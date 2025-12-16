`timescale 1ns / 1ps

`include "dau_symbols.vh"

module top (
    input wire  i_clk,
    input wire  i_rst,
    input wire  i_rx,
    output wire o_tx
);

    localparam NUM_DIGITS  = 20;
    localparam STACK_DEPTH = 6;

    wire [`DAU_SYM_WIDTH-1:0] tx_fifo_wr_data;
    wire [`DAU_SYM_WIDTH-1:0] tx_fifo_rd_data;
    wire                      tx_fifo_rd;
    wire                      tx_fifo_wr;
    wire                      tx_fifo_empty;
    wire                      tx_fifo_full;

    fifo #(
        .DATA_WIDTH(`DAU_SYM_WIDTH),
        .DEPTH(NUM_DIGITS + 6)
    ) fifo_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rd(tx_fifo_rd),
        .i_wr(tx_fifo_wr),
        .i_wr_data(tx_fifo_wr_data),
        .o_rd_data(tx_fifo_rd_data),
        .o_empty(tx_fifo_empty),
        .o_full(tx_fifo_full)
    );

    wire [7:0] ascii_char_in;
    wire [7:0] ascii_char_out;

    wire [`DAU_SYM_WIDTH-1:0] du_sym_in;

    ascii_char_to_dau_sym ascii_to_sym_inst (
        .i_char(ascii_char_in),
        .o_symbol(du_sym_in)
    );

    dau_sym_to_ascii_char sym_to_ascii_inst (
        .i_symbol(tx_fifo_rd_data),
        .o_char(ascii_char_out)
    );

    wire du_sym_in_valid;

    dau #(
        .NUM_DIGITS(NUM_DIGITS),
        .STACK_DEPTH(STACK_DEPTH)
    ) dau_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(du_sym_in_valid),
        .i_symbol(du_sym_in),
        .o_symbol(tx_fifo_wr_data),
        .o_symbol_valid(tx_fifo_wr),
        .o_ready()
    );
    
    uart uart_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rx(i_rx),
        .i_tx_start(~tx_fifo_empty),
        .i_data(ascii_char_out),
        .o_tx(o_tx),
        .o_rx_done(du_sym_in_valid),
        .o_tx_done(tx_fifo_rd),
        .o_data(ascii_char_in)
    );

endmodule
