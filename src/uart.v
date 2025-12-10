`timescale 1ns / 1ps

module uart #(
    parameter DATA_BITS = 8
)(
    input wire                  i_clk,
    input wire                  i_rst,
    input wire                  i_rx,
    input wire                  i_tx_start,
    input wire  [DATA_BITS-1:0] i_data,
    output wire                 o_tx,
    output wire                 o_rx_done,
    output wire                 o_tx_done,
    output wire [DATA_BITS-1:0] o_data
);

    localparam TICKS_PER_BIT = 16;

    /*  CLK_RATE  = 100 MHz
        BAUD_RATE = 115200
        
        N = CLK_RATE / (TICKS_PER_BIT * BAUD_RATE)
    */
    localparam N = 54;

    wire tick_en;

    mod_counter #(
        .MODULO(N)
    ) u_baud_gen (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_cnt(),
        .o_cnt_max(tick_en)
    );

    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .TICKS_PER_BIT(TICKS_PER_BIT)
    ) u_rx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx(i_rx),
        .i_tick_en(tick_en),
        .o_rx_done(o_rx_done),
        .o_data(o_data)
    );

    uart_tx #(
        .DATA_BITS(DATA_BITS),
        .TICKS_PER_BIT(TICKS_PER_BIT)
    ) u_tx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_tx_start(i_tx_start),
        .i_tick_en(tick_en),
        .i_data(i_data),
        .o_tx(o_tx),
        .o_tx_done(o_tx_done)
    );

endmodule
