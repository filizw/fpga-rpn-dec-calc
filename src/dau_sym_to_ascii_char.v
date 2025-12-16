`timescale 1ns / 1ps

`include "dau_symbols.vh"

module dau_sym_to_ascii_char (
    input wire [`DAU_SYM_WIDTH-1:0] i_symbol,
    output reg                [7:0] o_char
);

    always @* begin
        o_char = 8'h0;

        if ((i_symbol >= `DAU_SYM_PLUS) && (i_symbol <= `DAU_SYM_MINUS)) o_char = {4'h2, i_symbol[3:0]};

        if (i_symbol == `DAU_SYM_MUL) o_char = 8'h2A;

        if (i_symbol == `DAU_SYM_DIV) o_char = 8'h2F;

        if ((i_symbol >= `DAU_SYM_0) && (i_symbol <= `DAU_SYM_9)) o_char = {4'h3, i_symbol[3:0]};

        if (i_symbol == `DAU_SYM_SEPARATOR) o_char = 8'h20;

        if (i_symbol == `DAU_SYM_RESULT) o_char = 8'h0D;

        if (i_symbol == `DAU_SYM_NEW_LINE) o_char = 8'h0A;
    end

endmodule
