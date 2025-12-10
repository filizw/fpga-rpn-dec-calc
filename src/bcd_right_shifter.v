`timescale 1ns / 1ps

module bcd_right_shifter #(
    parameter NUM_DIGITS = 4,
    parameter NUM_STAGES = $clog2(NUM_DIGITS)
)(
    input wire  [NUM_DIGITS*4-1:0] i_num,
    input wire               [3:0] i_digit,
    input wire    [NUM_STAGES-1:0] i_amt,
    output wire [NUM_DIGITS*4-1:0] o_num,
    output wire              [3:0] o_digit
);
    
    wire [3:0] dummy_digit;

    assign {dummy_digit, o_num, o_digit} = ({i_digit, i_num, 4'b0} >> (i_amt * 4));

endmodule