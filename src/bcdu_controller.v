`timescale 1ns / 1ps

`include "bcd_alu_op_codes.vh"
`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

module bcdu_controller #(
    parameter NUM_DIGITS      = 4,
    parameter ADDR_WIDTH      = 2,
    parameter SHIFT_AMT_WIDTH = 3
)(
    input wire                               i_clk,
    input wire                               i_rst,
    input wire                               i_valid,
    input wire                        [15:0] i_instr,
    input wire                         [3:0] i_digit,
    output wire                              o_wr_en,
    output wire             [ADDR_WIDTH-1:0] o_wr_addr,
    output wire             [ADDR_WIDTH-1:0] o_rd_addr_a,
    output wire             [ADDR_WIDTH-1:0] o_rd_addr_b,
    output wire                              o_ncp_en,
    output wire [`BCD_ALU_OP_CODE_WIDTH-1:0] o_alu_op_code,
    output wire        [SHIFT_AMT_WIDTH-1:0] o_shl_amt,
    output wire        [SHIFT_AMT_WIDTH-1:0] o_shr_amt,
    output wire                        [3:0] o_shl_digit,
    output wire                        [3:0] o_shr_digit,
    output wire                              o_add_cin,
    output wire        [`BCDU_NUM_FLAGS-1:0] o_flags_mask,
    output wire                              o_flags_save,
    output wire                              o_ready
);
    
    reg        mcycle_en_reg, mcycle_en_next;
    reg        mcycle_cnt_ld_reg, mcycle_cnt_ld_next;
    reg  [3:0] mcycle_cnt_reg, mcycle_cnt_next;

    wire [`BCDU_OP_CODE_WIDTH-1:0] op_code = i_instr[15-:`BCDU_OP_CODE_WIDTH];

    wire [ADDR_WIDTH-1:0] addr0 = i_instr[8+:ADDR_WIDTH];
    wire [ADDR_WIDTH-1:0] addr1 = i_instr[4+:ADDR_WIDTH];
    wire [ADDR_WIDTH-1:0] addr2 = i_instr[0+:ADDR_WIDTH];

    wire                       shift_wr       = i_instr[7];
    wire                       shift_digit_ld = i_instr[6];
    wire                 [3:0] shift_digit    = i_instr[3:0];
    wire [SHIFT_AMT_WIDTH-1:0] shift_amt      = i_instr[SHIFT_AMT_WIDTH-1:0];
    wire [SHIFT_AMT_WIDTH-1:0] shift_inv_amt  = (NUM_DIGITS - shift_amt);

    wire [3:0] acc_digit = i_instr[3:0];

    wire sub = ((op_code == `BCDU_OP_SUB) || (op_code == `BCDU_OP_ACS));

    reg wr_en_reg, wr_en_next;

    reg [ADDR_WIDTH-1:0] wr_addr_reg, wr_addr_next;
    reg [ADDR_WIDTH-1:0] rd_addr_a_reg, rd_addr_a_next;
    reg [ADDR_WIDTH-1:0] rd_addr_b_reg, rd_addr_b_next;

    assign o_wr_en     = wr_en_reg;
    assign o_wr_addr   = wr_addr_reg;
    assign o_rd_addr_a = (mcycle_en_reg ? rd_addr_a_reg : rd_addr_a_next);
    assign o_rd_addr_b = (mcycle_en_reg ? rd_addr_b_reg : rd_addr_b_next);

    reg ncp_en_reg, ncp_en_next;

    assign o_ncp_en = (mcycle_en_reg ? ncp_en_reg: ncp_en_next);

    reg [`BCD_ALU_OP_CODE_WIDTH-1:0] alu_op_code_reg, alu_op_code_next;

    assign o_alu_op_code = alu_op_code_reg;

    reg [SHIFT_AMT_WIDTH-1:0] shl_amt_reg, shl_amt_next;
    reg [SHIFT_AMT_WIDTH-1:0] shr_amt_reg, shr_amt_next;

    assign o_shl_amt = shl_amt_reg;
    assign o_shr_amt = shr_amt_reg;

    reg [3:0] shl_digit_reg, shl_digit_next;
    reg [3:0] shr_digit_reg, shr_digit_next;

    assign o_shl_digit = shl_digit_reg;
    assign o_shr_digit = shr_digit_reg;

    reg add_cin_reg, add_cin_next;

    assign o_add_cin = add_cin_reg;

    reg [`BCDU_NUM_FLAGS-1:0] flags_mask_reg, flags_mask_next;
    reg                       flags_save_reg, flags_save_next;

    assign o_flags_mask = flags_mask_reg;
    assign o_flags_save = flags_save_reg;

    assign o_ready = ~mcycle_en_reg;

    always @* begin
        mcycle_en_next     = mcycle_en_reg;
        mcycle_cnt_ld_next = 1'b0;
        mcycle_cnt_next    = mcycle_cnt_reg;

        wr_en_next     = 1'b0;
        wr_addr_next   = addr0;
        rd_addr_a_next = addr0;
        rd_addr_b_next = addr2;
        ncp_en_next    = 1'b0;

        alu_op_code_next = `BCD_ALU_OP_CMP;
        shl_amt_next     = 0;
        shr_amt_next     = 0;
        shl_digit_next   = 4'd0;
        shr_digit_next   = 4'd0;
        add_cin_next     = 1'b0;
        flags_mask_next  = 0;
        flags_save_next  = 1'b0;

        if (mcycle_cnt_ld_reg) mcycle_cnt_next = i_digit;

        if (mcycle_en_reg) begin
            flags_save_next = 1'b1;

            if (mcycle_cnt_reg == 4'd0) mcycle_en_next  = 1'b0;
            else                        mcycle_cnt_next = (mcycle_cnt_reg - 4'd1);
        end else if (i_valid) begin
            case (op_code)
                `BCDU_OP_SHL: begin
                    mcycle_cnt_ld_next = 1'b1;

                    wr_en_next = shift_wr;

                    alu_op_code_next = `BCD_ALU_OP_SHL;

                    flags_mask_next[`BCDU_ZF] = 1'b1;
                    flags_mask_next[`BCDU_TF] = 1'b1;

                    if (shift_digit_ld) begin
                        shl_digit_next = (shift_digit > 4'd9) ? i_digit : shift_digit;
                        shl_amt_next   = 1;
                        shr_amt_next   = (NUM_DIGITS - 1);
                    end else begin
                        shl_amt_next = shift_amt;
                        shr_amt_next = shift_inv_amt;
                    end
                end

                `BCDU_OP_SHR: begin
                    mcycle_cnt_ld_next = 1'b1;

                    wr_en_next = shift_wr;

                    alu_op_code_next = `BCD_ALU_OP_SHR;

                    flags_mask_next[`BCDU_ZF] = 1'b1;
                    flags_mask_next[`BCDU_TF] = 1'b1;

                    if (shift_digit_ld) begin
                        shr_digit_next = shift_digit;
                        shr_amt_next   = 1;
                        shl_amt_next   = (NUM_DIGITS - 1);
                    end else begin
                        shr_amt_next = shift_amt;
                        shl_amt_next = shift_inv_amt;
                    end
                end

                `BCDU_OP_ADD, `BCDU_OP_SUB: begin
                    wr_en_next     = 1'b1;
                    rd_addr_a_next = addr1;
                    ncp_en_next    = sub;

                    alu_op_code_next = `BCD_ALU_OP_ADD;
                    add_cin_next     = sub;
                    
                    flags_mask_next[`BCDU_ZF] = 1'b1;
                    flags_mask_next[`BCDU_CF] = 1'b1;
                end

                `BCDU_OP_CMP: begin
                    rd_addr_b_next = addr1;

                    flags_mask_next[`BCDU_GF] = 1'b1;
                    flags_mask_next[`BCDU_EF] = 1'b1;
                end

                `BCDU_OP_CLR: begin
                    wr_en_next = 1'b1;
                end

                `BCDU_OP_MOV: begin
                    wr_en_next     = 1'b1;
                    rd_addr_a_next = addr1;

                    alu_op_code_next = `BCD_ALU_OP_SHL;
                end

                `BCDU_OP_ACA, `BCDU_OP_ACS: begin
                    if ((acc_digit != 0) || (i_digit != 0) || (mcycle_cnt_reg != 0)) wr_en_next = 1'b1;

                    rd_addr_b_next = addr1;
                    ncp_en_next    = sub;

                    alu_op_code_next = `BCD_ALU_OP_ADD;
                    add_cin_next     = sub;
                    
                    flags_mask_next[`BCDU_ZF] = 1'b1;
                    flags_mask_next[`BCDU_CF] = 1'b1;

                    if (acc_digit > 4'd1) begin
                        mcycle_en_next  = 1'b1;
                        mcycle_cnt_next = (acc_digit - 4'd2);
                    end else if ((i_digit > 4'd2) && (i_digit <= 4'd9)) begin
                        mcycle_en_next  = 1'b1;
                        mcycle_cnt_next = (i_digit - 4'd2);
                    end else if (mcycle_cnt_reg > 4'd1) begin
                        mcycle_en_next  = 1'b1;
                        mcycle_cnt_next = (mcycle_cnt_reg - 4'd2);
                    end
                end
            endcase
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            mcycle_en_reg     <= 1'b0;
            mcycle_cnt_ld_reg <= 1'b0;
            mcycle_cnt_reg    <= 0;
            wr_en_reg         <= 1'b0;
            wr_addr_reg       <= 0;
            rd_addr_a_reg     <= 0;
            rd_addr_b_reg     <= 0;
            ncp_en_reg        <= 1'b0;
            alu_op_code_reg   <= `BCD_ALU_OP_CMP;
            shl_amt_reg       <= 0;
            shr_amt_reg       <= 0;
            shl_digit_reg     <= 4'd0;
            shr_digit_reg     <= 4'd0;
            add_cin_reg       <= 1'b0;
            flags_mask_reg    <= 0;
            flags_save_reg    <= 1'b0;
        end else begin
            mcycle_en_reg     <= mcycle_en_next;
            mcycle_cnt_ld_reg <= mcycle_cnt_ld_next;
            mcycle_cnt_reg    <= mcycle_cnt_next;
            flags_save_reg    <= flags_save_next;

            if (!mcycle_en_reg) begin
                wr_en_reg       <= wr_en_next;
                wr_addr_reg     <= wr_addr_next;
                rd_addr_a_reg   <= rd_addr_a_next;
                rd_addr_b_reg   <= rd_addr_b_next;
                ncp_en_reg      <= ncp_en_next;
                alu_op_code_reg <= alu_op_code_next;
                shl_amt_reg     <= shl_amt_next;
                shr_amt_reg     <= shr_amt_next;
                shl_digit_reg   <= shl_digit_next;
                shr_digit_reg   <= shr_digit_next;
                add_cin_reg     <= add_cin_next;
                flags_mask_reg  <= flags_mask_next;
            end
        end
    end

endmodule
