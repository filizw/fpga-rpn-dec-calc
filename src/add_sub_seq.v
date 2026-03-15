`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

// ============================================================================
// Add/Subtract Sequencer
// ============================================================================
// Sequences BCDU instructions to add or subtract two signed BCD numbers.
// Handles comma alignment via left-shifts, magnitude comparison,
// and sign correction for cases where B > A during subtraction.

module add_sub_seq #(
    parameter COMMA_POS_WIDTH = 4   // Bit width of comma position
)(
    input wire                        i_clk,            // Clock
    input wire                        i_rst,            // Reset
    input wire                        i_start,          // Pulse to begin operation
    input wire                        i_sub,            // 1 = subtract, 0 = add
    input wire                        i_sign_a,         // Sign of operand A (1 = negative)
    input wire                        i_sign_b,         // Sign of operand B (1 = negative)
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_a,    // Comma position of A
    input wire  [COMMA_POS_WIDTH-1:0] i_comma_pos_b,    // Comma position of B
    input wire                  [3:0] i_digits_addr_a,  // BCDU register address for A
    input wire                  [3:0] i_digits_addr_b,  // BCDU register address for B
    input wire                        i_gt_flag,        // BCDU GT status flag
    input wire                        i_eq_flag,        // BCDU EQ status flag
    input wire                        i_instr_accept,   // BCDU ready to accept instruction
    output wire                       o_instr_valid,    // Instruction valid
    output wire                [15:0] o_instr,          // Instruction sent to BCDU
    output wire                       o_sign,           // Result sign (1 = negative)
    output wire [COMMA_POS_WIDTH-1:0] o_comma_pos,      // Result comma position
    output wire                       o_ready           // Sequencer idle and ready for i_start
);

    // FSM state encoding
    localparam STATE_IDLE    = 3'h0;    // Idle; wait for start
    localparam STATE_COMPARE = 3'h1;    // Compare magnitudes of A and B
    localparam STATE_ADD_SUB = 3'h2;    // Issue add or subtract instruction
    localparam STATE_WAIT    = 3'h3;    // Wait one cycle for result commit
    localparam STATE_CLEAR   = 3'h4;    // Clear B register; determine result sign
    localparam STATE_CORRECT = 3'h5;    // Correct: compute B − A when B was larger

    // FSM state registers
    reg [2:0] r_state, n_state;

    initial begin
        r_state = STATE_IDLE;
    end

    // Input registers: inputs captured when i_start is asserted in STATE_IDLE
    reg                       r_start;
    reg                       r_sub;
    reg                       r_sign_a;
    reg                       r_sign_b;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos_a;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos_b;
    reg                 [3:0] r_digits_addr_a;
    reg                 [3:0] r_digits_addr_b;

    // Capture inputs on start; hold until the next operation
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_sub           <= 1'b0;
            r_sign_a        <= 1'b0;
            r_sign_b        <= 1'b0;
            r_comma_pos_a   <= 0;
            r_comma_pos_b   <= 0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == STATE_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
                r_sub           <= i_sub;
                r_sign_a        <= i_sign_a;
                r_sign_b        <= i_sign_b;
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

    // State and instruction sequential update
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_state       <= STATE_IDLE;
            r_instr_valid <= 1'b0;
            r_instr       <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state       <= n_state;
            r_instr_valid <= n_instr_valid;
            r_instr       <= n_instr;
        end
    end

    // Result sign and comma position output registers
    reg                       r_sign;
    reg [COMMA_POS_WIDTH-1:0] r_comma_pos;

    assign o_sign      = r_sign;
    assign o_comma_pos = r_comma_pos;

    // True when A's comma position exceeds B's
    wire comma_pos_a_gt_b = (r_comma_pos_a > r_comma_pos_b);

    // Save result sign and comma position once STATE_CLEAR is reached
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_sign      <= 1'b0;
            r_comma_pos <= 0;
        end else if (r_state == STATE_CLEAR) begin
            r_sign      <= ~i_eq_flag & ((i_gt_flag & r_sign_a) | (~i_gt_flag & (r_sub ^ r_sign_b)));
            r_comma_pos <= comma_pos_a_gt_b ? r_comma_pos_a : r_comma_pos_b;
        end
    end

    // Determine if subtraction is needed
    wire subtract = (r_sub & ~(r_sign_a ^ r_sign_b)) | (~r_sub & (r_sign_a ^ r_sign_b));

    // FSM: combinational next-state and BCDU instruction generation
    always @* begin
        n_state       = r_state;
        n_instr_valid = 1'b0;
        n_instr       = {`BCDU_OP_NOP, 12'b0};

        if (r_state == STATE_WAIT) n_state = STATE_CLEAR;

        if (i_instr_accept) begin
            case (r_state)
                STATE_IDLE: begin
                    if (i_start || r_start) begin
                        n_state       = STATE_COMPARE;
                        n_instr_valid = 1'b1;
                    end

                    // Shift the operand with the smaller comma position to align both
                    if (r_start) begin
                        if (r_comma_pos_a > r_comma_pos_b) n_instr = {`BCDU_OP_SHL, r_digits_addr_b, 2'b10, {6-COMMA_POS_WIDTH{1'b0}}, r_comma_pos_a - r_comma_pos_b};
                        else                               n_instr = {`BCDU_OP_SHL, r_digits_addr_a, 2'b10, {6-COMMA_POS_WIDTH{1'b0}}, r_comma_pos_b - r_comma_pos_a};
                    end else begin
                        if (i_comma_pos_a > i_comma_pos_b) n_instr = {`BCDU_OP_SHL, i_digits_addr_b, 2'b10, {6-COMMA_POS_WIDTH{1'b0}}, i_comma_pos_a - i_comma_pos_b};
                        else                               n_instr = {`BCDU_OP_SHL, i_digits_addr_a, 2'b10, {6-COMMA_POS_WIDTH{1'b0}}, i_comma_pos_b - i_comma_pos_a};
                    end
                end

                STATE_COMPARE: begin
                    // Compare magnitudes to determine which operand is larger
                    n_state       = STATE_ADD_SUB;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CMP, i_digits_addr_a, i_digits_addr_b, 4'b0};
                end

                STATE_ADD_SUB: begin
                    // Add or subtract magnitudes; result written back to A
                    n_state       = STATE_WAIT;
                    n_instr_valid = 1'b1;
                    n_instr       = {(subtract ? `BCDU_OP_SUB : `BCDU_OP_ADD), r_digits_addr_a, r_digits_addr_a, r_digits_addr_b};
                end

                STATE_CLEAR: begin
                    // Clear B register; route to correction if B was the larger operand
                    n_state       = STATE_CLEAR;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};

                    if (!i_gt_flag && subtract) n_state = STATE_CORRECT;
                    else                        n_state = STATE_IDLE;
                end

                STATE_CORRECT: begin
                    // B was larger: compute true magnitude as B − A, store in A
                    n_state       = STATE_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_SUB, r_digits_addr_a, r_digits_addr_b, r_digits_addr_a};
                end
            endcase
        end
    end

endmodule
