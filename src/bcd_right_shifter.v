`timescale 1ns / 1ps

// ============================================================================
// BCD Right Shifter (Barrel Shifter)
// ============================================================================
// Barrel shifter for BCD numbers. Shifts a BCD number and digit right by
// a variable amount, padding with zeros from the left.

module bcd_right_shifter #(
    parameter NUM_DIGITS = 4,                   // Number of BCD digits
    parameter NUM_STAGES = $clog2(NUM_DIGITS)   // Number of shifter stages
)(
    input wire  [NUM_DIGITS*4-1:0] i_num,       // Input BCD number
    input wire               [3:0] i_digit,     // Input digit (4-bit)
    input wire    [NUM_STAGES-1:0] i_amt,       // Shift amount in digits
    output wire [NUM_DIGITS*4-1:0] o_num,       // Shifted BCD number
    output wire              [3:0] o_digit      // Shifted digit output
);
    
    // Dummy digit for capturing bits shifted out from the right
    wire [3:0] dummy_digit;

    // Concatenate digit + number + dummy, shift right by (i_amt * 4) bits,
    // extract number and digit outputs
    assign {dummy_digit, o_num, o_digit} = ({i_digit, i_num, 4'b0} >> (i_amt * 4));

endmodule
