`timescale 1ns / 1ps

`include "dau_symbols.vh"
`include "bcdu_flags.vh"

module dau #(
    parameter NUM_DIGITS  = 4,
    parameter STACK_DEPTH = 7
)(
    input wire                       i_clk,
    input wire                       i_rst,
    input wire                       i_valid,
    input wire  [`DAU_SYM_WIDTH-1:0] i_symbol,
    output wire [`DAU_SYM_WIDTH-1:0] o_symbol,
    output wire                      o_symbol_valid,
    output wire                      o_ready
);

    wire                       bcdu_valid;
    wire                [15:0] bcdu_instr;
    wire                 [3:0] bcdu_digit;
    wire [`BCDU_NUM_FLAGS-1:0] bcdu_flags;
    wire                       bcdu_ready;

    bcdu #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_REGS(STACK_DEPTH + 1)
    ) bcdu_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(bcdu_valid),
        .i_instr(bcdu_instr),
        .o_digit(bcdu_digit),
        .o_flags(bcdu_flags),
        .o_ready(bcdu_ready)
    );

endmodule
