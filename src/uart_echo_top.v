`timescale 1ns / 1ps

// ============================================================================
// UART Echo Top
// ============================================================================
// Minimal loopback top module.
// Receives one UART byte and transmits the same byte back.

module uart_echo_top (
    // Input interface
    input wire  i_clk,  // Clock
    input wire  i_rx,   // Serial RX line

    // Output interface
    output wire o_tx    // Serial TX line
);

    // UART payload width
    localparam DATA_BITS = 8;

    // Shared RX/TX payload bus
    wire [DATA_BITS-1:0] data;

    // UART status handshake signals
    wire rx_done;
    wire tx_done;

    // One-cycle pulse used to trigger transmission
    reg  tx_start = 1'b0;

    // UART wrapper instance
    uart #(
        .DATA_BITS(DATA_BITS)
    ) u_uart (
        .i_clk(i_clk),
        .i_rst(1'b0),
        .i_rx(i_rx),
        .i_tx_start(tx_start),
        .i_data(data),
        .o_tx(o_tx),
        .o_rx_done(rx_done),
        .o_tx_done(tx_done),
        .o_data(data)
    );

    // Start TX when RX completes; send a single-cycle start pulse
    always @(posedge i_clk) begin
        if (rx_done & ~tx_start) begin
            tx_start <= 1'b1;
        end else begin
            tx_start <= 1'b0;
        end
    end

endmodule
