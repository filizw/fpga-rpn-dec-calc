`timescale 1ns / 1ps

`include "bcd_alu_op_codes.vh"

// ============================================================================
// BCD Arithmetic Logic Unit (ALU)
// ============================================================================
// Integrates BCD arithmetic components: left/right shifters, adder, comparator.
// Routes operands to selected operation and outputs results with status flags.

module bcd_alu #(
    parameter NUM_DIGITS      = 4,                          // Number of BCD digits
    parameter SHIFT_AMT_WIDTH = $clog2(NUM_DIGITS + 1)      // Width for shift amount
)(
    // Control inputs
    input wire [`BCD_ALU_OP_CODE_WIDTH-1:0] i_op_code,      // Operation code
    
    // Shift inputs
    input wire        [SHIFT_AMT_WIDTH-1:0] i_shl_amt,      // Left shift amount
    input wire        [SHIFT_AMT_WIDTH-1:0] i_shr_amt,      // Right shift amount
    input wire                        [3:0] i_shl_digit,    // Digit for left shift
    input wire                        [3:0] i_shr_digit,    // Digit for right shift
    
    // Addition inputs
    input wire                              i_add_cin,      // Add carry in
    
    // Operands
    input wire           [NUM_DIGITS*4-1:0] i_num_a,        // Operand A
    input wire           [NUM_DIGITS*4-1:0] i_num_b,        // Operand B
    
    // Result outputs
    output reg           [NUM_DIGITS*4-1:0] o_num,          // Operation result
    
    // Shift outputs
    output wire                       [3:0] o_shl_digit,    // Shifted digit (left)
    output wire                       [3:0] o_shr_digit,    // Shifted digit (right)
    output wire                             o_shl_zero,     // Left shift result zero
    output wire                             o_shr_zero,     // Right shift result zero
    
    // Addition outputs
    output wire                             o_add_zero,     // Add result zero
    output wire                             o_add_cout,     // Add carry out
    
    // Comparison outputs
    output wire                             o_cmp_gt,       // Greater than
    output wire                             o_cmp_eq        // Equal
);

    // Left Shift
    wire [NUM_DIGITS*4-1:0] shl_num_out;

    assign o_shl_zero = (shl_num_out == 0);

    bcd_left_shifter #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_STAGES(SHIFT_AMT_WIDTH)
    ) u_shl (
        .i_num(i_num_a),
        .i_digit(i_shl_digit),
        .i_amt(i_shl_amt),
        .o_num(shl_num_out),
        .o_digit(o_shl_digit)
    );

    // Right Shift
    wire [NUM_DIGITS*4-1:0] shr_num_out;

    assign o_shr_zero = (shr_num_out == 0);

    bcd_right_shifter #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_STAGES(SHIFT_AMT_WIDTH)
    ) u_shr (
        .i_num(i_num_a),
        .i_digit(i_shr_digit),
        .i_amt(i_shr_amt),
        .o_num(shr_num_out),
        .o_digit(o_shr_digit)
    );

    // Addition
    wire [NUM_DIGITS*4-1:0] add_num_out;

    assign o_add_zero = (add_num_out == 0);

    bcd_adder #(
        .NUM_DIGITS(NUM_DIGITS)
    ) u_add (
        .i_num_a(i_num_a),
        .i_num_b(i_num_b),
        .i_carry(i_add_cin),
        .o_num(add_num_out),
        .o_carry(o_add_cout)
    );

    // Comparison
    bcd_comparator #(
        .NUM_DIGITS(NUM_DIGITS)
    ) u_cmp (
        .i_num_a(i_num_a),
        .i_num_b(i_num_b),
        .o_gt(o_cmp_gt),
        .o_eq(o_cmp_eq)
    );

    // Select and output result based on operation code
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
