`timescale 1ns / 1ps

`include "bcd_alu_op_codes.vh"

module bcd_alu #(
    parameter NUM_DIGITS      = 4,
    parameter SHIFT_AMT_WIDTH = $clog2(NUM_DIGITS + 1)
)(
    input wire [`BCD_ALU_OP_CODE_WIDTH-1:0] i_op_code,
    input wire        [SHIFT_AMT_WIDTH-1:0] i_shl_amt,
    input wire        [SHIFT_AMT_WIDTH-1:0] i_shr_amt,
    input wire                        [3:0] i_shl_digit,
    input wire                        [3:0] i_shr_digit,
    input wire                              i_add_cin,
    input wire           [NUM_DIGITS*4-1:0] i_num_a,
    input wire           [NUM_DIGITS*4-1:0] i_num_b,
    output reg           [NUM_DIGITS*4-1:0] o_num,
    output wire                       [3:0] o_shl_digit,
    output wire                       [3:0] o_shr_digit,
    output wire                             o_shl_zero,
    output wire                             o_shr_zero,
    output wire                             o_add_zero,
    output wire                             o_add_cout,
    output wire                             o_cmp_gt,
    output wire                             o_cmp_eq
);

    wire [NUM_DIGITS*4-1:0] shl_num_out;

    assign o_shl_zero = (shl_num_out == 0);

    bcd_left_shifter #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_STAGES(SHIFT_AMT_WIDTH)
    ) shl_inst (
        .i_num(i_num_a),
        .i_digit(i_shl_digit),
        .i_amt(i_shl_amt),
        .o_num(shl_num_out),
        .o_digit(o_shl_digit)
    );

    wire [NUM_DIGITS*4-1:0] shr_num_out;

    assign o_shr_zero = (shr_num_out == 0);

    bcd_right_shifter #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_STAGES(SHIFT_AMT_WIDTH)
    ) shr_inst (
        .i_num(i_num_a),
        .i_digit(i_shr_digit),
        .i_amt(i_shr_amt),
        .o_num(shr_num_out),
        .o_digit(o_shr_digit)
    );

    wire [NUM_DIGITS*4-1:0] add_num_out;

    assign o_add_zero = (add_num_out == 0);

    bcd_adder #(
        .NUM_DIGITS(NUM_DIGITS)
    ) add_inst (
        .i_num_a(i_num_a),
        .i_num_b(i_num_b),
        .i_carry(i_add_cin),
        .o_num(add_num_out),
        .o_carry(o_add_cout)
    );

    bcd_comparator #(
        .NUM_DIGITS(NUM_DIGITS)
    ) cmp_inst (
        .i_num_a(i_num_a),
        .i_num_b(i_num_b),
        .o_gt(o_cmp_gt),
        .o_eq(o_cmp_eq)
    );

    always @* begin
        o_num = 0;

        case (i_op_code)
            `BCD_ALU_OP_SHL: begin
                o_num = shl_num_out;
            end

            `BCD_ALU_OP_SHR: begin
                o_num = shr_num_out;
            end

            `BCD_ALU_OP_ADD: begin
                o_num = add_num_out;
            end
        endcase
    end

endmodule
