`timescale 1ns / 1ps

`include "dau_symbols.vh"
`include "bcdu_op_codes.vh"

module dau_input_interpreter #(
    parameter NUM_DIGITS = 4
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_valid,
    input wire [`DAU_SYM_WIDTH-1:0] i_symbol,
    output wire              [15:0] o_bcdu_instr,
    output wire                     o_bcdu_valid,
    output wire o_ready
);

    localparam DIGIT_CNT_WIDTH = $clog2(NUM_DIGITS);

    reg [DIGIT_CNT_WIDTH-1:0] digit_cnt_reg, digit_cnt_next;

    always @* begin
        if (i_valid) begin
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
        end else begin
        end
    end

endmodule
