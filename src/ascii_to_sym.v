`timescale 1ns / 1ps

`include "symbols.vh"

// ============================================================================
// ASCII to Symbol Converter
// ============================================================================
// Converts ASCII characters to internal symbol representations used by the
// calculator core. Maps keyboard input characters to the symbol constants
// defined in symbols.vh.

module ascii_to_sym (
    input wire            [7:0] i_char,     // Input ASCII character (8-bit)
    output reg [`SYM_WIDTH-1:0] o_symbol    // Output symbol (5-bit)
);

    always @* begin
        // Default to invalid symbol
        o_symbol = `SYM_INVALID;

        // Carriage return (0x0D) -> Result symbol (0x0D)
        if (i_char == 8'h0D) o_symbol = i_char[4:0];

        // Space (0x20) -> Separator symbol (0x02)
        if (i_char == 8'h20) o_symbol = 5'h02;

        // 'r' (0x72) -> Reset symbol (0x07)
        if (i_char == 8'h72) o_symbol = 5'h07;

        // '*' (0x2A) -> Multiplication symbol
        if (i_char == 8'h2A) o_symbol = `SYM_MUL;

        // '/' (0x2F) -> Division symbol
        if (i_char == 8'h2F) o_symbol = `SYM_DIV;

        // '+', ',', '-' (0x2B-0x2D) -> Plus, comma, minus symbols
        // Maps to symbols 0x1B, 0x1C, 0x1D respectively
        if ((i_char >= 8'h2B) && (i_char <= 8'h2D)) o_symbol = {1'b1, i_char[3:0]};

        // Digits '0'-'9' (0x30-0x39) -> Symbol digits 0x10-0x19
        if ((i_char >= 8'h30) && (i_char <= 8'h39)) o_symbol = i_char[4:0];
    end

endmodule
