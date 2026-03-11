`timescale 1ns / 1ps

// ============================================================================
// BCD 9's Complementor
// ============================================================================
// Computes the 9's complement of a BCD number.
// The 9's complement is used for subtraction operations.

module bcd_9s_complementor #(
    parameter NUM_DIGITS = 4                // Number of BCD digits
)(
    input wire  [4*NUM_DIGITS-1:0] i_num,   // Input number
    output wire [4*NUM_DIGITS-1:0] o_num    // Output number
);

    generate
        genvar n;

        // Compute 9's complement for each digit
        for (n = 0; n < NUM_DIGITS; n = n + 1) begin
            assign o_num[4*n+:4] = (4'd9 - i_num[4*n+:4]);
        end
    endgenerate

endmodule
