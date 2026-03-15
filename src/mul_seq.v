`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"

// ============================================================================
// Multiplication Sequencer
// ============================================================================
// Sequences BCDU instructions to perform decimal multiplication using an
// accumulator register. Produces the product in operand A, and outputs sign
// and comma position for the formatted result.

module mul_seq #(
    parameter       NUM_DIGITS      = 4,    // Number of digits per operand
    parameter       COMMA_POS_WIDTH = 4,    // Bit width of comma position
    parameter [3:0] ACC_ADDR        = 7     // BCDU register address for accumulator
)(
    input wire                        i_clk,            // Clock
    input wire                        i_rst,            // Reset
    input wire                        i_start,          // Pulse to begin multiplication
    input wire                        i_sign_a,         // Sign of operand A (1 = negative)
    input wire                        i_sign_b,         // Sign of operand B (1 = negative)
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_a,    // Comma position of A
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_b,    // Comma position of B
    input wire                  [3:0] i_digits_addr_a,  // BCDU register address for A/result
    input wire                  [3:0] i_digits_addr_b,  // BCDU register address for B
    input wire                        i_instr_accept,   // BCDU ready to accept next instruction
    output wire                       o_instr_valid,    // Instruction valid
    output wire                [15:0] o_instr,          // Instruction sent to BCDU
    output wire                       o_sign,           // Result sign (1 = negative)
    output wire [COMMA_POS_WIDTH-1:0] o_comma_pos,      // Result comma position
    output wire                       o_ready           // Sequencer idle and ready for i_start
);

    // FSM state encoding
    localparam STATE_IDLE      = 3'h0;  // Idle; wait for start
    localparam STATE_LD_DIGIT  = 3'h1;  // Load next multiplier digit
    localparam STATE_SHIFT_ACC = 3'h2;  // Shift accumulator for next partial product
    localparam STATE_START_ACC = 3'h3;  // Start accumulate operation in BCDU
    localparam STATE_WAIT      = 3'h4;  // Wait one cycle for result commit
    localparam STATE_MOVE      = 3'h5;  // Move final product to output register

    // FSM state registers
    reg [2:0] r_state, n_state;

    // Remaining multiplier digits to process
    reg [$clog2(NUM_DIGITS)-1:0] r_digit_cnt, n_digit_cnt;

    initial begin
        r_state     = STATE_IDLE;
        r_digit_cnt = NUM_DIGITS;
    end

    // Input addresses captured at start
    reg       r_start;
    reg [3:0] r_digits_addr_a;
    reg [3:0] r_digits_addr_b;

    // Capture operation context in IDLE
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == STATE_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
                r_digits_addr_a <= i_digits_addr_a;
                r_digits_addr_b <= i_digits_addr_b;
            end
        end else begin
            r_start <= 1'b0;
        end
    end

    // BCDU instruction output registers
    reg        r_instr_valid, n_instr_valid;
    reg [15:0] r_instr, n_instr;

    assign o_instr_valid = r_instr_valid;
    assign o_instr       = r_instr;

    assign o_ready = (r_state == STATE_IDLE);

    // Sequential update of state, counters, and instruction outputs
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_state       <= STATE_IDLE;
            r_digit_cnt   <= NUM_DIGITS;
            r_instr_valid <= 1'b0;
            r_instr       <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state       <= n_state;
            r_digit_cnt   <= n_digit_cnt;
            r_instr_valid <= n_instr_valid;
            r_instr       <= n_instr;
        end
    end

    // Result sign and comma position
    reg                       r_sign;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos;

    assign o_sign      = r_sign;
    assign o_comma_pos = r_comma_pos;

    // Sign and comma position are determined when operation starts
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_sign      <= 1'b0;
            r_comma_pos <= 0;
        end else if ((r_state == STATE_IDLE) && i_start) begin
            r_sign      <= i_sign_a ^ i_sign_b;
            r_comma_pos <= i_comma_pos_a + i_comma_pos_b;
        end
    end

    // FSM: combinational next-state and BCDU instruction generation
    always @* begin
        n_state       = r_state;
        n_digit_cnt   = r_digit_cnt;
        n_instr_valid = 1'b0;
        n_instr       = {`BCDU_OP_NOP, 12'b0};

        if (i_instr_accept) begin
            case (r_state)
                STATE_IDLE: begin
                    // Initialize accumulator and counters on new operation
                    if (i_start || r_start) begin
                        n_state       = STATE_LD_DIGIT;
                        n_digit_cnt   = NUM_DIGITS;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, ACC_ADDR, 8'b0};
                    end
                end

                STATE_LD_DIGIT: begin
                    if (r_digit_cnt != 4'd0) begin
                        // Shift multiplier to expose next digit for ACC operation
                        n_state       = STATE_SHIFT_ACC;
                        n_digit_cnt   = r_digit_cnt - 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, r_digits_addr_b, 2'b11, 6'b0};
                    end else begin
                        // All digits processed; finalize result transfer
                        n_state = STATE_MOVE;
                    end
                end

                STATE_SHIFT_ACC: begin
                    // Shift accumulator before adding next partial product
                    n_state       = STATE_START_ACC;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_SHL, ACC_ADDR, 2'b11, 6'b0};
                end

                STATE_START_ACC: begin
                    // Accumulate current partial product into accumulator
                    n_state       = STATE_WAIT;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_ACC, ACC_ADDR, r_digits_addr_a, 4'b0};
                end

                STATE_WAIT: begin
                    // Return to digit-loading stage
                    n_state = STATE_LD_DIGIT;
                end

                STATE_MOVE: begin
                    // Move final product into destination register A
                    n_state       = STATE_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_MOV, r_digits_addr_a, ACC_ADDR, 4'b0};
                end
            endcase
        end
    end

endmodule
