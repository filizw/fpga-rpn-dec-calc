`timescale 1ns / 1ps

module uart_echo_top (
    input wire  i_clk,
    input wire  i_rx,
    output wire o_tx
);
    
    localparam DATA_BITS = 8;

    wire [DATA_BITS-1:0] data;
    
    wire rx_done;
    wire tx_done;
    reg  tx_start = 1'b0;
    
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
    
    always @(posedge i_clk) begin
        if (rx_done & ~tx_start) begin
            tx_start <= 1'b1;
        end else begin
            tx_start <= 1'b0;
        end
    end

endmodule
