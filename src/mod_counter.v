`timescale 1ns / 1ps

module mod_counter #(
    parameter MODULO    = 10,
    parameter CNT_WIDTH = $clog2(MODULO)
)(
    input wire                  i_clk,
    input wire                  i_rst,
    output wire [CNT_WIDTH-1:0] o_cnt,
    output wire                 o_cnt_max
);

    reg [CNT_WIDTH-1:0] cnt_reg;

    wire                 cnt_max  = (cnt_reg == (MODULO - 1));
    wire [CNT_WIDTH-1:0] cnt_next = cnt_max ? 0 : (cnt_reg + 1);

    assign o_cnt     = cnt_reg;
    assign o_cnt_max = cnt_max;

    initial begin
        cnt_reg = 0;
    end

    always @(posedge i_clk) begin
        if (i_rst) cnt_reg <= 0;
        else       cnt_reg <= cnt_next;
    end

endmodule
