`timescale 1ns / 1ps

`include "symbols.vh"

// ============================================================================
// Symbol to ASCII Converter
// ============================================================================
// Converts internal symbol representations back to ASCII characters for
// display output. Maps the 5-bit symbols defined in symbols.vh to their
// corresponding 8-bit ASCII character representations.

module sym_to_ascii (
    input wire [`SYM_WIDTH-1:0] i_symbol,   // Input symbol (5-bit)
    output reg            [7:0] o_char      // Output ASCII character (8-bit)
);

    always @* begin
        // Default to null character
        o_char = 8'h0;

        // Plus, comma, minus symbols (0x1B-0x1D) -> '+', ',', '-' (0x2B-0x2D)
        if ((i_symbol >= `SYM_PLUS) && (i_symbol <= `SYM_MINUS)) o_char = {4'h2, i_symbol[3:0]};

        // Multiplication symbol -> '*' (0x2A)
        if (i_symbol == `SYM_MUL) o_char = 8'h2A;

        // Division symbol -> '/' (0x2F)
        if (i_symbol == `SYM_DIV) o_char = 8'h2F;

        // Digit symbols (0x10-0x19) -> ASCII digits '0'-'9' (0x30-0x39)
        if ((i_symbol >= `SYM_0) && (i_symbol <= `SYM_9)) o_char = {4'h3, i_symbol[3:0]};

        // Separator symbol -> space (0x20)
        if (i_symbol == `SYM_SEPARATOR) o_char = 8'h20;

        // Result symbol -> carriage return (0x0D)
        if (i_symbol == `SYM_RESULT) o_char = 8'h0D;

        // New line symbol -> line feed (0x0A)
        if (i_symbol == `SYM_NEW_LINE) o_char = 8'h0A;
    end

endmodule
