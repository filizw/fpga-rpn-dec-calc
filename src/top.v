`timescale 1ns / 1ps

`include "symbols.vh"

// ============================================================================
// Top
// ============================================================================
// System-level integration for UART-driven RPN decimal calculator.
// RX ASCII symbols are converted and sent to calc_core.
// calc_core output symbols are buffered, converted back to ASCII, and transmitted.

module top (
    // Input interface
    input wire  i_clk,  // Clock
    input wire  i_rst,  // Reset
    input wire  i_rx,   // UART RX line

    // Output interface
    output wire o_tx    // UART TX line
);

    // Calculator core configuration
    localparam NUM_DIGITS  = 20;
    localparam STACK_DEPTH = 6;

    // TX FIFO datapath and control signals
    wire [`SYM_WIDTH-1:0] tx_fifo_wr_data;
    wire [`SYM_WIDTH-1:0] tx_fifo_rd_data;
    wire                  tx_fifo_rd;
    wire                  tx_fifo_wr;
    wire                  tx_fifo_empty;
    wire                  tx_fifo_full;

    // Output buffering between calc_core and UART TX
    fifo #(
        .DATA_WIDTH(`SYM_WIDTH),
        .DEPTH(NUM_DIGITS + 6)
    ) u_fifo (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rd(tx_fifo_rd),
        .i_wr(tx_fifo_wr),
        .i_wr_data(tx_fifo_wr_data),
        .o_rd_data(tx_fifo_rd_data),
        .o_empty(tx_fifo_empty),
        .o_full(tx_fifo_full)
    );

    // UART ASCII domain signals
    wire [7:0] ascii_char_in;
    wire [7:0] ascii_char_out;

    // Calculator symbol domain signal
    wire [`SYM_WIDTH-1:0] sym_in;

    // RX ASCII to internal symbol conversion
    ascii_to_sym u_ascii_to_sym (
        .i_char(ascii_char_in),
        .o_symbol(sym_in)
    );

    // Internal symbol to TX ASCII conversion
    sym_to_ascii u_sym_to_ascii (
        .i_symbol(tx_fifo_rd_data),
        .o_char(ascii_char_out)
    );

    // Pulse when UART RX completes one byte
    wire du_sym_in_valid;

    // Calculator core instance
    calc_core #(
        .NUM_DIGITS(NUM_DIGITS),
        .STACK_DEPTH(STACK_DEPTH)
    ) u_calc_core (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(du_sym_in_valid),
        .i_symbol(sym_in),
        .o_symbol(tx_fifo_wr_data),
        .o_symbol_valid(tx_fifo_wr),
        .o_ready()
    );

    // UART wrapper instance
    uart u_uart (
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
