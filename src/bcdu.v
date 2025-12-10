`timescale 1ns / 1ps

`include "bcd_alu_op_codes.vh"
`include "bcdu_flags.vh"

module bcdu #(
    parameter NUM_DIGITS = 4,
    parameter NUM_REGS   = 4
)(
    input wire                        i_clk,
    input wire                        i_rst,
    input wire                        i_valid,
    input wire                 [15:0] i_instr,
    output wire                 [3:0] o_digit,
    output wire [`BCDU_NUM_FLAGS-1:0] o_flags,
    output wire                       o_ready
);

    wire wr_en;

    localparam ADDR_WIDTH = $clog2(NUM_REGS);

    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr_a;
    wire [ADDR_WIDTH-1:0] rd_addr_b;

    wire [NUM_DIGITS*4-1:0] wr_num;
    wire [NUM_DIGITS*4-1:0] rd_num_a;
    wire [NUM_DIGITS*4-1:0] rd_num_b;

    reg_file #(
        .REG_WIDTH(NUM_DIGITS * 4),
        .NUM_REGS(NUM_REGS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) reg_file_inst (
        .i_clk(i_clk),
        .i_wr_en(wr_en),
        .i_wr_addr(wr_addr),
        .i_wr_data(wr_num),
        .i_rd_addr_a(rd_addr_a),
        .o_rd_data_a(rd_num_a),
        .i_rd_addr_b(rd_addr_b),
        .o_rd_data_b(rd_num_b)
    );

    wire [NUM_DIGITS*4-1:0] num_a_mux = ((wr_en && (wr_addr == rd_addr_a)) ? wr_num: rd_num_a);
    wire [NUM_DIGITS*4-1:0] num_b_mux = ((wr_en && (wr_addr == rd_addr_b)) ? wr_num: rd_num_b);

    wire [NUM_DIGITS*4-1:0] ncp_num_b;

    bcd_9s_complementor #(
        .NUM_DIGITS(NUM_DIGITS)
    ) ncp_inst (
        .i_num(num_b_mux),
        .o_num(ncp_num_b)
    );

    wire ncp_en;

    reg  [NUM_DIGITS*4-1:0] num_a_reg;
    wire [NUM_DIGITS*4-1:0] num_a_next = num_a_mux;
    reg  [NUM_DIGITS*4-1:0] num_b_reg;
    wire [NUM_DIGITS*4-1:0] num_b_next = (ncp_en ? ncp_num_b : num_b_mux);

    wire [`BCD_ALU_OP_CODE_WIDTH-1:0] alu_op_code;

    localparam SHIFT_AMT_WIDTH = $clog2(NUM_DIGITS + 1);

    wire [SHIFT_AMT_WIDTH-1:0] shl_amt;
    wire [SHIFT_AMT_WIDTH-1:0] shr_amt;

    wire [3:0] shl_digit_in;
    wire [3:0] shr_digit_in;
    wire [3:0] shl_digit_out;
    wire [3:0] shr_digit_out;

    wire op_shl = (alu_op_code == `BCD_ALU_OP_SHL);
    wire op_shr = (alu_op_code == `BCD_ALU_OP_SHR);

    reg  [3:0] digit_out_reg;
    wire [3:0] digit_out_next = (op_shl ? shl_digit_out : (op_shr ? shr_digit_out : 4'hF));

    wire add_cin;

    wire shl_zero;
    wire shr_zero;
    wire add_zero;
    wire add_cout;
    wire cmp_gt;
    wire cmp_eq;

    wire zero  = (op_shl ? shl_zero : (op_shr ? shr_zero : add_zero));
    wire trunc = ~(op_shl ? shr_zero : shl_zero);

    reg  [`BCDU_NUM_FLAGS-1:0] flags_reg, flags_next;
    wire [`BCDU_NUM_FLAGS-1:0] flags_mask;
    wire                       flags_save;

    assign o_digit = digit_out_reg;
    assign o_flags = flags_reg;

    bcd_alu #(
        .NUM_DIGITS(NUM_DIGITS),
        .SHIFT_AMT_WIDTH(SHIFT_AMT_WIDTH)
    ) alu_inst (
        .i_op_code(alu_op_code),
        .i_shl_amt(shl_amt),
        .i_shr_amt(shr_amt),
        .i_shl_digit(shl_digit_in),
        .i_shr_digit(shr_digit_in),
        .i_add_cin(add_cin),
        .i_num_a(num_a_reg),
        .i_num_b(num_b_reg),
        .o_num(wr_num),
        .o_shl_digit(shl_digit_out),
        .o_shr_digit(shr_digit_out),
        .o_shl_zero(shl_zero),
        .o_shr_zero(shr_zero),
        .o_add_zero(add_zero),
        .o_add_cout(add_cout),
        .o_cmp_gt(cmp_gt),
        .o_cmp_eq(cmp_eq)
    );

    bcdu_controller #(
        .NUM_DIGITS(NUM_DIGITS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SHIFT_AMT_WIDTH(SHIFT_AMT_WIDTH)
    ) ctrl_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_instr(i_instr),
        .i_digit(digit_out_next),
        .o_wr_en(wr_en),
        .o_wr_addr(wr_addr),
        .o_rd_addr_a(rd_addr_a),
        .o_rd_addr_b(rd_addr_b),
        .o_ncp_en(ncp_en),
        .o_alu_op_code(alu_op_code),
        .o_shl_amt(shl_amt),
        .o_shr_amt(shr_amt),
        .o_shl_digit(shl_digit_in),
        .o_shr_digit(shr_digit_in),
        .o_add_cin(add_cin),
        .o_flags_mask(flags_mask),
        .o_flags_save(flags_save),
        .o_ready(o_ready)
    );

    wire sub = add_cin;

    always @* begin
        flags_next = ({cmp_eq, cmp_gt, add_cout, trunc, zero} & flags_mask);

        if (flags_save) begin
            if      (!sub && flags_reg[`BCDU_CF]) flags_next[`BCDU_CF] = 1'b1;
            else if (sub && !flags_reg[`BCDU_CF]) flags_next[`BCDU_CF] = 1'b0;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            num_a_reg     <= 0;
            num_b_reg     <= 0;
            digit_out_reg <= 4'hF;
            flags_reg     <= 0;
        end else begin
            num_a_reg     <= num_a_next;
            num_b_reg     <= num_b_next;
            digit_out_reg <= digit_out_next;
            flags_reg     <= flags_next;
        end
    end

endmodule
