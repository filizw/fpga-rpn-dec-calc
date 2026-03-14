`timescale 1ns / 1ps

// ============================================================================
// BCDU Controller
// ============================================================================
// Decodes 16-bit instructions and orchestrates the BCD Unit
// (BCDU). Handles multi-cycle counting, register file addressing, and
// generation of control signals for ALU operations, shifts, addition, and
// flag updates.

`include "bcd_alu_op_codes.vh"
`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

module bcdu_controller #(
    parameter NUM_DIGITS      = 4,      // Width of BCD operands
    parameter ADDR_WIDTH      = 2,      // log2 register file size
    parameter SHIFT_AMT_WIDTH = 3       // Bits needed for shift amount
)(
    // Global control
    input wire                               i_clk,         // Clock
    input wire                               i_rst,         // Reset
    input wire                               i_valid,       // Instruction valid
    input wire                        [15:0] i_instr,       // Instruction
    input wire                         [3:0] i_digit,       // Input digit for shift/accumulate

    // Register file controls
    output wire                              o_wr_en,       // Write enable
    output wire             [ADDR_WIDTH-1:0] o_wr_addr,     // Write address
    output wire             [ADDR_WIDTH-1:0] o_rd_addr_a,   // Read address A
    output wire             [ADDR_WIDTH-1:0] o_rd_addr_b,   // Read address B

    // 9's complementor controls
    output wire                              o_ncp_en,      // 9's complement enable

    // ALU control signals
    output wire [`BCD_ALU_OP_CODE_WIDTH-1:0] o_alu_op_code, // ALU operation code
    output wire        [SHIFT_AMT_WIDTH-1:0] o_shl_amt,     // Shift-left amount
    output wire        [SHIFT_AMT_WIDTH-1:0] o_shr_amt,     // Shift-right amount
    output wire                        [3:0] o_shl_digit,   // Digit for left shift
    output wire                        [3:0] o_shr_digit,   // Digit for right shift
    output wire                              o_add_cin,     // Add carry-in

    // Flag controls
    output wire        [`BCDU_NUM_FLAGS-1:0] o_flags_mask,  // Which flags to update
    output wire                              o_flags_save,  // Store flag values

    // Status
    output wire                              o_ready        // Ready for next instr
);
    
    // Used by the ACC (accumulate) instruction to repeat operations multiple
    // times. 'mcycle_en' enables counting, 'mcycle_cnt' holds remaining
    // iterations and can be loaded with i_digit.
    reg       r_mcycle_en, n_mcycle_en;
    reg       r_mcycle_cnt_ld, n_mcycle_cnt_ld;
    reg [3:0] r_mcycle_cnt, n_mcycle_cnt;

    // Operation code field decoded from i_instr
    wire [`BCDU_OP_CODE_WIDTH-1:0] op_code = i_instr[15-:`BCDU_OP_CODE_WIDTH];

    // Operand addresses encoded in instruction
    wire [ADDR_WIDTH-1:0] addr0 = i_instr[8+:ADDR_WIDTH];
    wire [ADDR_WIDTH-1:0] addr1 = i_instr[4+:ADDR_WIDTH];
    wire [ADDR_WIDTH-1:0] addr2 = i_instr[0+:ADDR_WIDTH];

    // Shift-specific fields
    wire                       shift_wr       = i_instr[7];                     // Write enable
    wire                       shift_digit_ld = i_instr[6];                     // Load digit instead of amount
    wire                 [3:0] shift_digit    = i_instr[3:0];                   // Literal digit value
    wire [SHIFT_AMT_WIDTH-1:0] shift_amt      = i_instr[SHIFT_AMT_WIDTH-1:0];   // Amount
    wire [SHIFT_AMT_WIDTH-1:0] shift_inv_amt  = (NUM_DIGITS - shift_amt);       // Inverse

    // Accumulate digit (same position as shift_digit)
    wire [3:0] acc_digit = i_instr[3:0];

    // Flag used to bias ADD vs SUB operations
    wire sub = (op_code == `BCDU_OP_SUB);

    // Register-file address and enable registers
    reg r_wr_en, n_wr_en;                              // Write enable

    reg [ADDR_WIDTH-1:0] r_wr_addr, n_wr_addr;         // Writing address
    reg [ADDR_WIDTH-1:0] r_rd_addr_a, n_rd_addr_a;     // Read port A address
    reg [ADDR_WIDTH-1:0] r_rd_addr_b, n_rd_addr_b;     // Read port B address

    // Outputs for register file control
    assign o_wr_en     = r_wr_en;
    assign o_wr_addr   = r_wr_addr;
    assign o_rd_addr_a = (r_mcycle_en ? r_rd_addr_a : n_rd_addr_a);
    assign o_rd_addr_b = (r_mcycle_en ? r_rd_addr_b : n_rd_addr_b);

    // 9's complement enable register
    reg r_ncp_en, n_ncp_en;

    assign o_ncp_en = (r_mcycle_en ? r_ncp_en: n_ncp_en);

    // ALU operation code register
    reg [`BCD_ALU_OP_CODE_WIDTH-1:0] r_alu_op_code, n_alu_op_code;

    assign o_alu_op_code = r_alu_op_code;

    // Shift amount registers
    reg [SHIFT_AMT_WIDTH-1:0] r_shl_amt, n_shl_amt;
    reg [SHIFT_AMT_WIDTH-1:0] r_shr_amt, n_shr_amt;

    assign o_shl_amt = r_shl_amt;
    assign o_shr_amt = r_shr_amt;

    // Digit registers used by variable-shift instructions
    reg [3:0] r_shl_digit, n_shl_digit;
    reg [3:0] r_shr_digit, n_shr_digit;

    assign o_shl_digit = r_shl_digit;
    assign o_shr_digit = r_shr_digit;

    // Add carry-in register
    reg r_add_cin, n_add_cin;

    assign o_add_cin = r_add_cin;

    // Flag mask and save registers control which status flags are updated
    reg [`BCDU_NUM_FLAGS-1:0] r_flags_mask, n_flags_mask;
    reg                       r_flags_save, n_flags_save;

    assign o_flags_mask = r_flags_mask;
    assign o_flags_save = r_flags_save;

    assign o_ready = ~r_mcycle_en;

    // Combinational next-state logic and output multiplexing
    always @* begin
        n_mcycle_en     = r_mcycle_en;
        n_mcycle_cnt_ld = 1'b0;
        n_mcycle_cnt    = r_mcycle_cnt;

        n_wr_en     = 1'b0;
        n_wr_addr   = addr0;
        n_rd_addr_a = addr0;
        n_rd_addr_b = addr2;
        n_ncp_en    = 1'b0;

        n_alu_op_code = `BCD_ALU_OP_CMP;
        n_shl_amt     = 0;
        n_shr_amt     = 0;
        n_shl_digit   = 4'd0;
        n_shr_digit   = 4'd0;
        n_add_cin     = 1'b0;
        n_flags_mask  = 0;
        n_flags_save  = 1'b0;

        if (r_mcycle_cnt_ld) n_mcycle_cnt = i_digit;

        if (r_mcycle_en) begin
            n_flags_save = 1'b1;

            if (r_mcycle_cnt == 4'd0) n_mcycle_en  = 1'b0;
            else                      n_mcycle_cnt = (r_mcycle_cnt - 4'd1);
        end else if (i_valid) begin
            // Decode operation code and set control signals accordingly
            case (op_code)
                `BCDU_OP_SHL: begin // Shift left
                    n_mcycle_cnt_ld = 1'b1;
                    n_wr_en = shift_wr;
                    n_alu_op_code = `BCD_ALU_OP_SHL;

                    n_flags_mask[`BCDU_ZF] = 1'b1;
                    n_flags_mask[`BCDU_TF] = 1'b1;

                    if (shift_digit_ld) begin
                        n_shl_digit = (shift_digit > 4'd9) ? i_digit : shift_digit;
                        n_shl_amt   = 1;
                        n_shr_amt   = (NUM_DIGITS - 1);
                    end else begin
                        n_shl_amt = shift_amt;
                        n_shr_amt = shift_inv_amt;
                    end
                end

                `BCDU_OP_SHR: begin // Shift right
                    n_mcycle_cnt_ld = 1'b1;
                    n_wr_en = shift_wr;
                    n_alu_op_code = `BCD_ALU_OP_SHR;

                    n_flags_mask[`BCDU_ZF] = 1'b1;
                    n_flags_mask[`BCDU_TF] = 1'b1;

                    if (shift_digit_ld) begin
                        n_shr_digit = shift_digit;
                        n_shr_amt   = 1;
                        n_shl_amt   = (NUM_DIGITS - 1);
                    end else begin
                        n_shr_amt = shift_amt;
                        n_shl_amt = shift_inv_amt;
                    end
                end

                `BCDU_OP_ADD, `BCDU_OP_SUB: begin // Add or subtract
                    n_wr_en     = 1'b1;
                    n_rd_addr_a = addr1;
                    n_ncp_en    = sub;

                    n_alu_op_code = `BCD_ALU_OP_ADD;
                    n_add_cin     = sub;
                    
                    n_flags_mask[`BCDU_ZF] = 1'b1;
                    n_flags_mask[`BCDU_CF] = 1'b1;
                end

                `BCDU_OP_CMP: begin // Compare
                    n_rd_addr_b = addr1;

                    n_flags_mask[`BCDU_GF] = 1'b1;
                    n_flags_mask[`BCDU_EF] = 1'b1;
                end

                `BCDU_OP_CLR: begin // Clear
                    n_wr_en = 1'b1;
                end

                `BCDU_OP_MOV: begin // Move
                    n_wr_en     = 1'b1;
                    n_rd_addr_a = addr1;

                    n_alu_op_code = `BCD_ALU_OP_SHL;
                end

                `BCDU_OP_ACC: begin // Accumulate
                    if ((acc_digit != 0) || (i_digit != 0) || (r_mcycle_cnt != 0)) n_wr_en = 1'b1;

                    n_rd_addr_b = addr1;

                    n_alu_op_code = `BCD_ALU_OP_ADD;
                    
                    n_flags_mask[`BCDU_ZF] = 1'b1;
                    n_flags_mask[`BCDU_CF] = 1'b1;

                    if (acc_digit > 4'd1) begin
                        n_mcycle_en  = 1'b1;
                        n_mcycle_cnt = (acc_digit - 4'd2);
                    end else if ((i_digit > 4'd2) && (i_digit <= 4'd9)) begin
                        n_mcycle_en  = 1'b1;
                        n_mcycle_cnt = (i_digit - 4'd2);
                    end else if (r_mcycle_cnt > 4'd1) begin
                        n_mcycle_en  = 1'b1;
                        n_mcycle_cnt = (r_mcycle_cnt - 4'd2);
                    end
                end
            endcase
        end
    end

    // Sequential register updates on clock edge
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_mcycle_en     <= 1'b0;
            r_mcycle_cnt_ld <= 1'b0;
            r_mcycle_cnt    <= 0;
            r_wr_en         <= 1'b0;
            r_wr_addr       <= 0;
            r_rd_addr_a     <= 0;
            r_rd_addr_b     <= 0;
            r_ncp_en        <= 1'b0;
            r_alu_op_code   <= `BCD_ALU_OP_CMP;
            r_shl_amt       <= 0;
            r_shr_amt       <= 0;
            r_shl_digit     <= 4'd0;
            r_shr_digit     <= 4'd0;
            r_add_cin       <= 1'b0;
            r_flags_mask    <= 0;
            r_flags_save    <= 1'b0;
        end else begin
            r_mcycle_en     <= n_mcycle_en;
            r_mcycle_cnt_ld <= n_mcycle_cnt_ld;
            r_mcycle_cnt    <= n_mcycle_cnt;
            r_flags_save    <= n_flags_save;

            if (!r_mcycle_en) begin
                r_wr_en       <= n_wr_en;
                r_wr_addr     <= n_wr_addr;
                r_rd_addr_a   <= n_rd_addr_a;
                r_rd_addr_b   <= n_rd_addr_b;
                r_ncp_en      <= n_ncp_en;
                r_alu_op_code <= n_alu_op_code;
                r_shl_amt     <= n_shl_amt;
                r_shr_amt     <= n_shr_amt;
                r_shl_digit   <= n_shl_digit;
                r_shr_digit   <= n_shr_digit;
                r_add_cin     <= n_add_cin;
                r_flags_mask  <= n_flags_mask;
            end
        end
    end

endmodule
