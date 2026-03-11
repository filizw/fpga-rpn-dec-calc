`timescale 1ns / 1ps

// ============================================================================
// BCD Comparator
// ============================================================================
// Compares two BCD numbers and outputs greater-than and equal flags.

module bcd_comparator #(
    parameter NUM_DIGITS = 4                // Number of BCD digits
)(
    input wire [NUM_DIGITS*4-1:0] i_num_a,  // Operand A
    input wire [NUM_DIGITS*4-1:0] i_num_b,  // Operand B
    output wire                   o_gt,     // Greater than (A > B)
    output wire                   o_eq      // Equal (A == B)
);

    // Compare operands
    assign o_gt = (i_num_a > i_num_b);
    assign o_eq = (i_num_a == i_num_b);

endmodule
