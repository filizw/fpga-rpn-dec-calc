`timescale 1ns / 1ps

// ============================================================================
// UART Wrapper
// ============================================================================
// Top-level UART integration module.
// Generates oversampling tick enable from system clock and instantiates
// UART RX/TX submodules that share the same baud tick domain.

module uart #(
    parameter DATA_BITS = 8 // Number of bits in one UART data frame
)(
    // Input interface
    input wire                  i_clk,      // Clock
    input wire                  i_rst,      // Reset
    input wire                  i_rx,       // Serial RX line
    input wire                  i_tx_start, // Pulse to start TX frame
    input wire  [DATA_BITS-1:0] i_data,     // TX payload data

    // Output interface
    output wire                 o_tx,       // Serial TX line
    output wire                 o_rx_done,  // RX frame received pulse
    output wire                 o_tx_done,  // TX frame sent pulse
    output wire [DATA_BITS-1:0] o_data      // RX payload data
);

    // UART oversampling configuration
    localparam TICKS_PER_BIT = 16;

    // Baud tick divider for 100 MHz clock and 115200 baud:
    // N = CLK_RATE / (TICKS_PER_BIT * BAUD_RATE) = 54
    localparam N = 54;

    // Shared oversampling tick enable used by RX and TX
    wire tick_en;

    // Baud tick generator
    mod_counter #(
        .MODULO(N)
    ) u_baud_gen (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_cnt(),
        .o_cnt_max(tick_en)
    );

    // UART receiver instance
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

    // UART transmitter instance
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
