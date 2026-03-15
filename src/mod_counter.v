`timescale 1ns / 1ps

// ============================================================================
// Modulo Counter
// ============================================================================
// Counter that wraps at MODULO - 1.
// Exposes current count and a max-count flag.

module mod_counter #(
    parameter MODULO    = 10,               // Counter modulus
    parameter CNT_WIDTH = $clog2(MODULO)    // Bit width required for MODULO
)(
    // Input interface
    input wire                  i_clk,      // Clock
    input wire                  i_rst,      // Reset

    // Output interface
    output wire [CNT_WIDTH-1:0] o_cnt,      // Current counter value
    output wire                 o_cnt_max   // High when counter reaches MODULO - 1
);

    // Counter register
    reg [CNT_WIDTH-1:0] r_cnt;

    // Max-count detect and next-count logic
    wire                 cnt_max = (r_cnt == (MODULO - 1));
    wire [CNT_WIDTH-1:0] n_cnt   = cnt_max ? 0 : (r_cnt + 1);

    assign o_cnt     = r_cnt;
    assign o_cnt_max = cnt_max;

    initial begin
        r_cnt = 0;
    end

    // Sequential counter update
    always @(posedge i_clk) begin
        if (i_rst) r_cnt <= 0;
        else       r_cnt <= n_cnt;
    end

endmodule
