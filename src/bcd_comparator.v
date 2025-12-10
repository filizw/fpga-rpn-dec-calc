`timescale 1ns / 1ps

module bcd_comparator #(
    parameter NUM_DIGITS = 4
)(
    input wire [NUM_DIGITS*4-1:0] i_num_a,
    input wire [NUM_DIGITS*4-1:0] i_num_b,
    output wire                   o_gt,
    output wire                   o_eq
);

    assign o_gt = (i_num_a > i_num_b);
    assign o_eq = (i_num_a == i_num_b);

endmodule
