`timescale 1ns / 1ps

// ============================================================================
// BCD Left Shifter (Barrel Shifter)
// ============================================================================
// Barrel shifter for BCD numbers. Shifts a BCD number and digit left by
// a variable amount, padding with zeros from the right.

module bcd_left_shifter #(
    parameter NUM_DIGITS = 4,                   // Number of BCD digits
    parameter NUM_STAGES = $clog2(NUM_DIGITS)   // Number of shifter stages
)(
    input wire  [NUM_DIGITS*4-1:0] i_num,       // Input number
    input wire               [3:0] i_digit,     // Input digit
    input wire    [NUM_STAGES-1:0] i_amt,       // Shift amount in digits
    output wire [NUM_DIGITS*4-1:0] o_num,       // Shifted number
    output wire              [3:0] o_digit      // Shifted digit output
);
    
    // Dummy digit for capturing bits shifted out from the left
    wire [3:0] dummy_digit;

    // Concatenate dummy + number + digit, shift left by (i_amt * 4) bits,
    // extract number and digit outputs
    assign {o_digit, o_num, dummy_digit} = ({4'b0, i_num, i_digit} << (i_amt * 4));

endmodule
