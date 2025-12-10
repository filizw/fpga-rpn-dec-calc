`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 4
)(
    input wire                   i_clk,
    input wire                   i_rst,
    input wire                   i_rd,
    input wire                   i_wr,
    input wire  [DATA_WIDTH-1:0] i_wr_data,
    output wire [DATA_WIDTH-1:0] o_rd_data,
    output wire                  o_empty,
    output wire                  o_full
);
    
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem_reg [DEPTH-1:0];

    reg [ADDR_WIDTH-1:0] wr_ptr_reg, wr_ptr_next, wr_ptr_succ;
    reg [ADDR_WIDTH-1:0] rd_ptr_reg, rd_ptr_next, rd_ptr_succ;

    reg empty_reg, empty_next;
    reg full_reg, full_next;

    wire wr_en = (i_wr & ~full_reg);

    assign o_rd_data = mem_reg[rd_ptr_reg];
    assign o_empty   = empty_reg;
    assign o_full    = full_reg;

    always @* begin
        wr_ptr_succ = ((wr_ptr_reg == (DEPTH - 1)) ? 0 : (wr_ptr_reg + 1));
        rd_ptr_succ = ((rd_ptr_reg == (DEPTH - 1)) ? 0 : (rd_ptr_reg + 1));

        wr_ptr_next = wr_ptr_reg;
        rd_ptr_next = rd_ptr_reg;
        empty_next  = empty_reg;
        full_next   = full_reg;

        case ({i_wr, i_rd})
            2'b01: begin
                if (!empty_reg) begin
                    rd_ptr_next = rd_ptr_succ;
                    full_next   = 1'b0;

                    if (rd_ptr_succ == wr_ptr_reg) empty_next = 1'b1;
                end
            end

            2'b10: begin
                if (!full_reg) begin
                    wr_ptr_next = wr_ptr_succ;
                    empty_next  = 1'b0;

                    if (wr_ptr_succ == rd_ptr_reg) full_next = 1'b1;
                end
            end

            2'b11: begin
                wr_ptr_next = wr_ptr_succ;
                rd_ptr_next = rd_ptr_succ;
            end
        endcase
    end

    integer n;

    initial begin
        for (n = 0; n < DEPTH; n = n + 1) mem_reg[n] = 0;

        wr_ptr_reg = 0;
        rd_ptr_reg = 0;
        empty_reg  = 1'b1;
        full_reg   = 1'b0;
    end

    always @(posedge i_clk) begin
        if (wr_en) mem_reg[wr_ptr_reg] <= i_wr_data;
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            empty_reg  <= 1'b1;
            full_reg   <= 1'b0;
        end else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            empty_reg  <= empty_next;
            full_reg   <= full_next;
        end
    end

endmodule
