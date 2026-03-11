`timescale 1ns / 1ps

// ============================================================================
// Register File
// ============================================================================
// Simple synchronous register file with two read ports and one write port.
// Parameterized width and depth allow it to be reused for different word
// sizes and number of registers.

module reg_file #(
    parameter REG_WIDTH  = 4,                   // Width of each register
    parameter NUM_REGS   = 4,                   // Number of registers
    parameter ADDR_WIDTH = $clog2(NUM_REGS)     // Bits needed to index registers
)(
    // Clock & control
    input wire                  i_clk,          // Clock
    input wire                  i_wr_en,        // Write enable

    // Write port
    input wire [ADDR_WIDTH-1:0] i_wr_addr,      // Write address
    input wire  [REG_WIDTH-1:0] i_wr_data,      // Data to write

    // Read port A
    input wire [ADDR_WIDTH-1:0] i_rd_addr_a,    // Read address A
    output wire [REG_WIDTH-1:0] o_rd_data_a,    // Read data A

    // Read port B
    input wire [ADDR_WIDTH-1:0] i_rd_addr_b,    // Read address B
    output wire [REG_WIDTH-1:0] o_rd_data_b     // Read data B
);
    
    // Memory array for registers
    reg [REG_WIDTH-1:0] r_mem [NUM_REGS-1:0];

    integer n;

    // Initialize registers to zero
    initial begin
        for (n = 0; n < NUM_REGS; n = n + 1) r_mem[n] = {REG_WIDTH{1'b0}};
    end

    // Synchronous write
    always @(posedge i_clk) begin
        if (i_wr_en) r_mem[i_wr_addr] <= i_wr_data;
    end

    // Asynchronous read ports
    assign o_rd_data_a = r_mem[i_rd_addr_a];
    assign o_rd_data_b = r_mem[i_rd_addr_b];

endmodule
