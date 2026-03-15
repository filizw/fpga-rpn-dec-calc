`timescale 1ns / 1ps

// ============================================================================
// FIFO
// ============================================================================
// Simple synchronous FIFO with combinational read data output.
// Tracks read/write pointers and empty/full flags for flow control.

module fifo #(
    parameter DATA_WIDTH = 8,   // Width of each FIFO entry
    parameter DEPTH      = 4    // Number of entries in FIFO storage
)(
    // Input interface
    input wire                   i_clk,     // Clock
    input wire                   i_rst,     // Reset
    input wire                   i_rd,      // Read request
    input wire                   i_wr,      // Write request
    input wire  [DATA_WIDTH-1:0] i_wr_data, // Write data

    // Output interface
    output wire [DATA_WIDTH-1:0] o_rd_data, // Data at current read pointer
    output wire                  o_empty,   // FIFO empty flag
    output wire                  o_full     // FIFO full flag
);

    // Address width required to index DEPTH entries
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // FIFO storage array
    reg [DATA_WIDTH-1:0] r_mem [DEPTH-1:0];

    // Read/write pointer registers
    reg [ADDR_WIDTH-1:0] r_wr_ptr, n_wr_ptr, wr_ptr_succ;
    reg [ADDR_WIDTH-1:0] r_rd_ptr, n_rd_ptr, rd_ptr_succ;

    // FIFO status flags
    reg r_empty, n_empty;
    reg r_full, n_full;

    // Write is allowed only when FIFO is not full
    wire wr_en = (i_wr & ~r_full);

    assign o_rd_data = r_mem[r_rd_ptr];
    assign o_empty   = r_empty;
    assign o_full    = r_full;

    // Combinational next-state logic for pointers and status flags
    always @* begin
        wr_ptr_succ = ((r_wr_ptr == (DEPTH - 1)) ? 0 : (r_wr_ptr + 1));
        rd_ptr_succ = ((r_rd_ptr == (DEPTH - 1)) ? 0 : (r_rd_ptr + 1));

        n_wr_ptr = r_wr_ptr;
        n_rd_ptr = r_rd_ptr;
        n_empty  = r_empty;
        n_full   = r_full;

        // Decode request combinations: read only, write only, or simultaneous
        case ({i_wr, i_rd})
            2'b01: begin
                if (!r_empty) begin
                    n_rd_ptr = rd_ptr_succ;
                    n_full   = 1'b0;

                    if (rd_ptr_succ == r_wr_ptr) n_empty = 1'b1;
                end
            end

            2'b10: begin
                if (!r_full) begin
                    n_wr_ptr = wr_ptr_succ;
                    n_empty  = 1'b0;

                    if (wr_ptr_succ == r_rd_ptr) n_full = 1'b1;
                end
            end

            2'b11: begin
                n_wr_ptr = wr_ptr_succ;
                n_rd_ptr = rd_ptr_succ;
            end
        endcase
    end

    integer n;

    initial begin
        for (n = 0; n < DEPTH; n = n + 1) r_mem[n] = 0;

        r_wr_ptr = 0;
        r_rd_ptr = 0;
        r_empty  = 1'b1;
        r_full   = 1'b0;
    end

    // Synchronous memory write
    always @(posedge i_clk) begin
        if (wr_en) r_mem[r_wr_ptr] <= i_wr_data;
    end

    // Sequential update of pointers and status flags
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_wr_ptr <= 0;
            r_rd_ptr <= 0;
            r_empty  <= 1'b1;
            r_full   <= 1'b0;
        end else begin
            r_wr_ptr <= n_wr_ptr;
            r_rd_ptr <= n_rd_ptr;
            r_empty  <= n_empty;
            r_full   <= n_full;
        end
    end

endmodule
