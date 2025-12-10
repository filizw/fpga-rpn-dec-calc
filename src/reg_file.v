`timescale 1ns / 1ps

module reg_file #(
    parameter REG_WIDTH  = 4,
    parameter NUM_REGS   = 4,
    parameter ADDR_WIDTH = $clog2(NUM_REGS)
)(
    input wire                  i_clk,
    input wire                  i_wr_en,
    input wire [ADDR_WIDTH-1:0] i_wr_addr,
    input wire  [REG_WIDTH-1:0] i_wr_data,
    input wire [ADDR_WIDTH-1:0] i_rd_addr_a,
    output wire [REG_WIDTH-1:0] o_rd_data_a,
    input wire [ADDR_WIDTH-1:0] i_rd_addr_b,
    output wire [REG_WIDTH-1:0] o_rd_data_b
);
    
    reg [REG_WIDTH-1:0] mem_reg [NUM_REGS-1:0];

    integer n;

    initial begin
        for (n = 0; n < NUM_REGS; n = n + 1) mem_reg[n] = 0;
    end

    always @(posedge i_clk) begin
        if (i_wr_en) mem_reg[i_wr_addr] <= i_wr_data;
    end

    assign o_rd_data_a = mem_reg[i_rd_addr_a];
    assign o_rd_data_b = mem_reg[i_rd_addr_b];

endmodule
