`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

// ============================================================================
// Division Sequencer
// ============================================================================
// Sequences BCDU instructions to perform decimal division using iterative
// shift/subtract steps. Produces quotient in operand A, and outputs sign and
// comma position for the formatted result.

module div_seq #(
    parameter       NUM_DIGITS      = 4,    // Number of digits per operand
    parameter       COMMA_POS_WIDTH = 4,    // Bit width of comma position
    parameter [3:0] REM_ADDR        = 6,    // BCDU register address for remainder
    parameter [3:0] QUO_ADDR        = 7     // BCDU register address for quotient
)(
    input wire                        i_clk,            // Clock
    input wire                        i_rst,            // Reset
    input wire                        i_start,          // Pulse to begin division
    input wire                        i_sign_a,         // Sign of dividend (1 = negative)
    input wire                        i_sign_b,         // Sign of divisor (1 = negative)
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_a,    // Dividend comma position
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_b,    // Divisor comma position
    input wire                  [3:0] i_digits_addr_a,  // BCDU register address for dividend/result
    input wire                  [3:0] i_digits_addr_b,  // BCDU register address for divisor
    input wire  [`BCDU_NUM_FLAGS-1:0] i_flags,          // BCDU status flags from previous instruction
    input wire                        i_instr_accept,   // BCDU ready to accept next instruction
    output wire                       o_instr_valid,    // Instruction valid
    output wire                [15:0] o_instr,          // Instruction sent to BCDU
    output wire                       o_sign,           // Result sign (1 = negative)
    output wire [COMMA_POS_WIDTH-1:0] o_comma_pos,      // Result comma position
    output wire                       o_ready           // Sequencer idle and ready for i_start
);

    // FSM state encoding
    localparam STATE_IDLE     = 4'h0;   // Idle; wait for start
    localparam STATE_ZERO_CMP = 4'h1;   // Check if divisor is zero
    localparam STATE_QUO_CLR  = 4'h2;   // Clear quotient register
    localparam STATE_DIV_SHL  = 4'h3;   // Shift dividend to fetch next digit
    localparam STATE_REM_SHL  = 4'h4;   // Shift remainder and append fetched digit
    localparam STATE_REM_SUB  = 4'h5;   // Repeatedly subtract divisor from remainder
    localparam STATE_QUO_SHL  = 4'h6;   // Shift quotient and insert computed digit
    localparam STATE_REM_ADD  = 4'h7;   // Restore remainder after oversubtraction
    localparam STATE_DVSR_CLR = 4'h8;   // Clear divisor register
    localparam STATE_QUO_MOV  = 4'h9;   // Move quotient to output register

    // FSM state register
    reg [3:0] r_state, n_state;

    // Per-digit subtraction loop counter
    reg [3:0] r_sub_cnt, n_sub_cnt;

    // Digit counters for quotient and dividend processing
    reg [5:0] r_quo_digit_cnt, n_quo_digit_cnt;
    reg [5:0] r_div_digit_cnt, n_div_digit_cnt;

    // Tracks whether first non-zero quotient digit has been produced
    reg r_got_msd, n_got_msd;

    initial begin
        r_state         = STATE_IDLE;
        r_sub_cnt       = 4'd0;
        r_quo_digit_cnt = 6'd0;
        r_div_digit_cnt = 6'd0;
        r_got_msd       = 1'b0;
    end

    // Input data captured at start
    reg                       r_start;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos_a;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos_b;
    reg                 [3:0] r_digits_addr_a;
    reg                 [3:0] r_digits_addr_b;

    // Capture operation context in IDLE
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_comma_pos_a   <= 0;
            r_comma_pos_b   <= 0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == STATE_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
                r_comma_pos_a   <= i_comma_pos_a;
                r_comma_pos_b   <= i_comma_pos_b;
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
            r_state         <= STATE_IDLE;
            r_sub_cnt       <= 4'd0;
            r_quo_digit_cnt <= 6'd0;
            r_div_digit_cnt <= 6'd0;
            r_got_msd       <= 1'b0;
            r_instr_valid   <= 1'b0;
            r_instr         <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state         <= n_state;
            r_sub_cnt       <= n_sub_cnt;
            r_quo_digit_cnt <= n_quo_digit_cnt;
            r_div_digit_cnt <= n_div_digit_cnt;
            r_got_msd       <= n_got_msd;
            r_instr_valid   <= n_instr_valid;
            r_instr         <= n_instr;
        end
    end

    // Result sign and comma position
    reg                       r_sign;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos;

    assign o_sign      = r_sign;
    assign o_comma_pos = r_comma_pos;

    // Sign is computed at start; comma position is finalized on completion
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_sign      <= 1'b0;
            r_comma_pos <= 0;
        end else begin
            if ((r_state == STATE_IDLE) && i_start) r_sign <= i_sign_a ^ i_sign_b;

            if (r_state == STATE_QUO_MOV) r_comma_pos <= (r_div_digit_cnt - NUM_DIGITS) + r_comma_pos_a - r_comma_pos_b;
        end
    end

    // FSM: combinational next-state and instruction generation
    always @* begin
        n_state         = r_state;
        n_sub_cnt       = r_sub_cnt;
        n_quo_digit_cnt = r_quo_digit_cnt;
        n_div_digit_cnt = r_div_digit_cnt;
        n_got_msd       = r_got_msd;
        n_instr_valid   = 1'b0;
        n_instr         = {`BCDU_OP_NOP, 12'b0};

        if (i_instr_accept) begin
            case (r_state)
                STATE_IDLE: begin
                    // Initialize internal registers and start with remainder clear
                    if (i_start || r_start) begin
                        n_state         = STATE_ZERO_CMP;
                        n_sub_cnt       = 4'd0;
                        n_quo_digit_cnt = 6'd0;
                        n_div_digit_cnt = 6'd0;
                        n_got_msd       = 1'b0;
                        n_instr_valid   = 1'b1;
                        n_instr         = {`BCDU_OP_CLR, REM_ADDR, 8'b0};
                    end
                end

                STATE_ZERO_CMP: begin
                    // Compare remainder (set to zero) with divisor
                    n_state       = STATE_QUO_CLR;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CMP, REM_ADDR, r_digits_addr_b, 4'b0};
                end

                STATE_QUO_CLR: begin
                    // Ensure quotient starts from zero
                    n_state       = STATE_DIV_SHL;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, QUO_ADDR, 8'b0};
                end

                STATE_DIV_SHL: begin
                    if (r_quo_digit_cnt != NUM_DIGITS) begin
                        // Pull next dividend digit into carry path
                        n_state         = STATE_REM_SHL;
                        n_div_digit_cnt = r_div_digit_cnt + 1;
                        n_instr_valid   = 1'b1;
                        n_instr         = {`BCDU_OP_SHL, r_digits_addr_a, 2'b11, 6'b0};
                    end else begin
                        // Quotient precision reached; finish sequence
                        n_state       = STATE_QUO_MOV;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                    end
                end

                STATE_REM_SHL: begin
                    if (i_flags[`BCDU_EF]) begin
                        // No more dividend digits available
                        n_state       = STATE_QUO_MOV;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                    end else begin
                        // Shift remainder and inject next dividend digit
                        n_state       = STATE_REM_SUB;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, REM_ADDR, 2'b11, 6'hA};
                    end
                end

                STATE_REM_SUB: begin
                    // Subtract divisor repeatedly to derive current quotient digit
                    if ((r_sub_cnt == 4'd1) && !i_flags[`BCDU_TF] && !r_got_msd) begin
                        n_state       = STATE_DIV_SHL;
                        n_sub_cnt     = 4'd0;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_ADD, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else if ((r_sub_cnt >= 4'd2) && i_flags[`BCDU_ZF] && (r_div_digit_cnt > NUM_DIGITS)) begin
                        // Early termination when exact division is reached
                        n_state       = STATE_DVSR_CLR;
                        n_sub_cnt     = 4'd0;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, QUO_ADDR, 4'b1100, r_sub_cnt - 4'd2};
                    end else if ((r_sub_cnt < 4'd3) || i_flags[`BCDU_CF]) begin
                        // Continue subtract loop while subtraction is valid
                        n_sub_cnt     = r_sub_cnt + 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SUB, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else begin
                        n_state = STATE_QUO_SHL;
                    end

                    if (r_sub_cnt == 4'd2) n_got_msd = 1'b1;
                end

                STATE_QUO_SHL: begin
                    // Commit computed quotient digit and prepare remainder restore
                    n_state         = STATE_REM_ADD;
                    n_sub_cnt       = 4'd3;
                    n_quo_digit_cnt = r_quo_digit_cnt + 1;
                    n_instr_valid   = 1'b1;
                    n_instr         = {`BCDU_OP_SHL, QUO_ADDR, 4'b1100, r_sub_cnt - 4'd3};
                end

                STATE_REM_ADD: begin
                    if (r_sub_cnt != 0) begin
                        // Restore remainder after too many subtractions
                        n_sub_cnt     = r_sub_cnt - 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_ADD, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else begin
                        n_state = STATE_DIV_SHL;
                    end
                end

                STATE_DVSR_CLR: begin
                    // Clear divisor register
                    n_state       = STATE_QUO_MOV;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                end

                STATE_QUO_MOV: begin
                    // Move final quotient into destination and return to IDLE
                    n_state       = STATE_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_MOV, r_digits_addr_a, QUO_ADDR, 4'b0};
                end
            endcase
        end
    end

endmodule
