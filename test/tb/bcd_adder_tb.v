`timescale 1ns / 1ps

`include "test/tb/common.vh"

module bcd_adder_tb ();
    
    localparam NUM_DIGITS = 8;

    reg  [NUM_DIGITS*4-1:0] i_num_a;
    reg  [NUM_DIGITS*4-1:0] i_num_b;
    reg                     i_carry;
    wire [NUM_DIGITS*4-1:0] o_num;
    wire                    o_carry;

    bcd_adder #(
        .NUM_DIGITS(NUM_DIGITS)
    ) uut (
        .i_num_a(i_num_a),
        .i_num_b(i_num_b),
        .i_carry(i_carry),
        .o_num(o_num),
        .o_carry(o_carry)
    );

    initial begin
        `TEST_START("bcd_adder", "out/vcd/bcd_adder_tb.vcd", bcd_adder_tb)

        i_num_a = 32'h60000000;
        i_num_b = 32'h29999999;
        i_carry = 1'b1;

        #20;

        $display("result = %h, cout = %b", o_num, o_carry);

        `TEST_END("bcd_adder")
    end

endmodule
