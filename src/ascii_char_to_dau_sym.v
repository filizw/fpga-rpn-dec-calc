`timescale 1ns / 1ps

`include "dau_symbols.vh"

module ascii_char_to_dau_sym (
    input wire                [7:0] i_char,
    output reg [`DAU_SYM_WIDTH-1:0] o_symbol
);

    always @* begin
        o_symbol = `DAU_SYM_INVALID;

        if (i_char == 8'h0D) o_symbol = i_char[4:0];

        if (i_char == 8'h20) o_symbol = 5'h02;

        if (i_char == 8'h72) o_symbol = 5'h07;

        if (i_char == 8'h2A) o_symbol = `DAU_SYM_MUL;

        if (i_char == 8'h2F) o_symbol = `DAU_SYM_DIV;

        if ((i_char >= 8'h2B) && (i_char <= 8'h2D)) o_symbol = {1'b1, i_char[3:0]};

        if ((i_char >= 8'h30) && (i_char <= 8'h39)) o_symbol = i_char[4:0];
    end

endmodule
