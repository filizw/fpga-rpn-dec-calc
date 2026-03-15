`timescale 1ns / 1ps

`include "symbols.vh"
`include "bcdu_op_codes.vh"

// ============================================================================
// Input Interpreter
// ============================================================================
// Interprets incoming symbols, updates number data, and sends BCDU
// instructions or high-level operation-start signals. Also controls loopback
// symbols for echo and manages RPN stack pointer updates.

module input_interpreter #(
    parameter NUM_DIGITS  = 4,  // Number of digits per operand
    parameter STACK_DEPTH = 7   // RPN stack depth
)(
    input wire                   i_clk,                 // Clock
    input wire                   i_rst,                 // Reset
    input wire                   i_valid,               // Input symbol is valid
    input wire  [`SYM_WIDTH-1:0] i_symbol,              // Input symbol
    input wire             [3:0] i_stack_ptr,           // Current stack pointer
    input wire                   i_operation_done,      // Active operation completed
    output wire                  o_bcdu_instr_valid,    // BCDU instruction valid
    output wire           [15:0] o_bcdu_instr,          // BCDU instruction
    output wire                  o_loopback_en,         // Enable loopback output symbol
    output wire [`SYM_WIDTH-1:0] o_loopback_symbol,     // Loopback output symbol
    output wire                  o_print_start,         // Start print/format sequence
    output wire                  o_add_start,           // Start add sequence
    output wire                  o_sub_start,           // Start subtract sequence
    output wire                  o_mul_start,           // Start multiply sequence
    output wire                  o_div_start,           // Start divide sequence
    output wire                  o_comma_inc,           // Increment comma position
    output wire                  o_comma_clr,           // Clear comma position
    output wire                  o_sign_set,            // Set current operand sign
    output wire                  o_sign_clr,            // Clear current operand sign
    output reg             [3:0] o_stack_ptr_next,      // Next stack pointer value
    output wire                  o_ready                // Interpreter ready for input
);

    // Digit counter width for entered-number length tracking
    localparam DIGIT_CNT_WIDTH = $clog2(NUM_DIGITS / 2 + 1);

    // Input symbols buffer register
    reg [`SYM_WIDTH-1:0] r_symbol_buf, n_symbol_buf;

    reg [DIGIT_CNT_WIDTH-1:0] r_digit_cnt, n_digit_cnt;

    reg r_got_comma, n_got_comma;
    reg r_got_sign, n_got_sign;
    reg r_got_operator, n_got_operator;
    reg r_got_last_num, n_got_last_num;

    reg r_clr, n_clr;

    reg r_internal_rst, n_internal_rst;

    // BCDU instruction output registers
    reg        r_bcdu_instr_valid, n_bcdu_instr_valid;
    reg [15:0] r_bcdu_instr, n_bcdu_instr;

    assign o_bcdu_instr_valid = r_bcdu_instr_valid;
    assign o_bcdu_instr       = r_bcdu_instr;

    // Loopback output registers
    reg                  r_loopback_en, n_loopback_en;
    reg [`SYM_WIDTH-1:0] r_loopback_symbol, n_loopback_symbol;

    assign o_loopback_en     = r_loopback_en;
    assign o_loopback_symbol = r_loopback_symbol;

    // Operation-start signals
    reg r_print_start, n_print_start;
    reg r_add_start, n_add_start;
    reg r_sub_start, n_sub_start;
    reg r_mul_start, n_mul_start;
    reg r_div_start, n_div_start;

    assign o_print_start = r_print_start;
    assign o_add_start   = r_add_start;
    assign o_sub_start   = r_sub_start;
    assign o_mul_start   = r_mul_start;
    assign o_div_start   = r_div_start;

    // Number-format control signals
    reg r_comma_inc, n_comma_inc;
    reg r_comma_clr, n_comma_clr;
    reg r_sign_set, n_sign_set;
    reg r_sign_clr, n_sign_clr;
    reg r_ready, n_ready;

    assign o_comma_inc     = r_comma_inc;
    assign o_comma_clr     = r_comma_clr;
    assign o_sign_set      = r_sign_set;
    assign o_sign_clr      = r_sign_clr;
    assign o_ready         = r_ready;

    initial begin
        r_ready = 1'b1;
    end

    // Combinational decision logic for symbol handling and control signals generation
    always @* begin
        n_symbol_buf   = r_symbol_buf;
        n_digit_cnt    = r_digit_cnt;
        n_got_comma    = r_got_comma;
        n_got_sign     = r_got_sign;
        n_got_operator = 1'b0;
        n_got_last_num = r_got_last_num;
        n_clr          = r_clr;
        n_internal_rst = 1'b0;

        n_bcdu_instr_valid = 1'b0;
        n_bcdu_instr       = {`BCDU_OP_NOP, 12'b0};

        n_loopback_en     = 1'b0;
        n_loopback_symbol = `SYM_INVALID;

        n_print_start = 1'b0;
        n_add_start   = 1'b0;
        n_sub_start   = 1'b0;
        n_mul_start   = 1'b0;
        n_div_start   = 1'b0;

        n_comma_inc = 1'b0;
        n_comma_clr = 1'b0;
        n_sign_set  = 1'b0;
        n_sign_clr  = 1'b0;
        n_ready     = r_ready;

        o_stack_ptr_next = i_stack_ptr;

        n_internal_rst = 1'b0;

        // Allow input again when operation completes
        if (i_operation_done) n_ready = 1'b1;

        if (r_clr) begin
            if (r_loopback_symbol == `SYM_RESULT) begin
                n_loopback_en     = 1'b1;
                n_loopback_symbol = `SYM_NEW_LINE;
            end

            if (i_stack_ptr == 0) n_internal_rst = 1'b1;
            else                  o_stack_ptr_next = (i_stack_ptr - 1);

            n_comma_clr = 1'b1;
            n_sign_clr  = 1'b1;

            n_bcdu_instr_valid = 1'b1;
            n_bcdu_instr       = {`BCDU_OP_CLR, i_stack_ptr, 8'b0};
        end

        // Handle input symbols when valid and ready
        if (i_valid && r_ready) begin
            if ((i_symbol >= `SYM_0) && (i_symbol <= `SYM_9) && (r_symbol_buf != `SYM_RESULT) && (i_stack_ptr != STACK_DEPTH)) begin
                // Numeric digit entry
                if (r_digit_cnt < (NUM_DIGITS / 2)) begin
                    n_digit_cnt = (r_digit_cnt + 1);

                    n_bcdu_instr_valid = 1'b1;
                    n_bcdu_instr       = {`BCDU_OP_SHL, i_stack_ptr, 2'b11, {6-`SYM_WIDTH{1'b0}}, i_symbol};

                    n_loopback_en     = 1'b1;
                    n_loopback_symbol = i_symbol;

                    if (r_got_comma) n_comma_inc = 1'b1;

                    if ((r_symbol_buf == `SYM_MINUS) && !r_got_sign) begin
                        n_got_sign = 1'b1;

                        n_sign_set = 1'b1;
                    end

                    n_symbol_buf = i_symbol;
                end
            end else if ((i_symbol == `SYM_COMMA) && !r_got_comma) begin
                // First comma in current number
                n_got_comma = 1'b1;

                n_loopback_en     = 1'b1;
                n_loopback_symbol = i_symbol;

                if ((r_symbol_buf == `SYM_MINUS) && !r_got_sign) begin
                    n_got_sign = 1'b1;

                    n_sign_set = 1'b1;
                end

                n_symbol_buf = i_symbol;
            end else if (((i_symbol == `SYM_PLUS) || (i_symbol == `SYM_MINUS)) && ((r_symbol_buf == `SYM_INVALID) || (r_symbol_buf == `SYM_SEPARATOR))) begin
                // Sign symbol at number start
                n_loopback_en     = 1'b1;
                n_loopback_symbol = i_symbol;
                
                n_symbol_buf = i_symbol;
            end else if (((i_symbol == `SYM_MUL) || (i_symbol == `SYM_DIV)) && (r_symbol_buf == `SYM_SEPARATOR)) begin
                // Arithmetic operation symbol placed after separator
                n_loopback_en     = 1'b1;
                n_loopback_symbol = i_symbol;
                
                n_symbol_buf = i_symbol;
            end else if ((i_symbol == `SYM_SEPARATOR) && (r_symbol_buf != `SYM_SEPARATOR) && (r_symbol_buf != `SYM_INVALID)) begin
                // Separator completes current number and may trigger operation start
                if (i_stack_ptr != (STACK_DEPTH - 1)) begin
                    n_digit_cnt = 0;
                    n_got_comma = 1'b0;
                    n_got_sign  = 1'b0;
                end

                n_loopback_en     = 1'b1;
                n_loopback_symbol = i_symbol;

                if ((((r_symbol_buf >= `SYM_0) && (r_symbol_buf <= `SYM_9)) || (r_symbol_buf == `SYM_RESULT)) && (i_stack_ptr != STACK_DEPTH)) o_stack_ptr_next = (i_stack_ptr + 1);

                if (((r_symbol_buf == `SYM_PLUS) || (r_symbol_buf == `SYM_MINUS) || (r_symbol_buf == `SYM_MUL) || (r_symbol_buf == `SYM_DIV)) && (i_stack_ptr > 1)) begin
                    n_add_start = (r_symbol_buf == `SYM_PLUS);
                    n_sub_start = (r_symbol_buf == `SYM_MINUS);
                    n_mul_start = (r_symbol_buf == `SYM_MUL);
                    n_div_start = (r_symbol_buf == `SYM_DIV);
                    n_ready     = 1'b0;

                    if (i_stack_ptr != 0) o_stack_ptr_next = (i_stack_ptr - 1);
                end

                n_symbol_buf = i_symbol;
            end else if ((i_symbol == `SYM_RESULT) && (r_symbol_buf == `SYM_SEPARATOR)) begin
                // Request result printout
                n_loopback_en     = 1'b1;
                n_loopback_symbol = i_symbol;

                n_print_start = 1'b1;

                n_ready = 1'b0;

                o_stack_ptr_next = (i_stack_ptr - 1);

                n_symbol_buf = i_symbol;
            end else if (i_symbol == `SYM_RESET) begin
                // Enter clear sequence
                n_loopback_en     = 1'b1;
                n_loopback_symbol = `SYM_RESULT;

                n_clr = 1'b1;

                n_ready = 1'b0;
            end
        end
    end

    // Sequential state/register update
    always @(posedge i_clk) begin
        if (i_rst || r_internal_rst) begin
            r_symbol_buf   <= `SYM_INVALID;
            r_digit_cnt    <= 0;
            r_got_comma    <= 1'b0;
            r_got_sign     <= 1'b0;
            r_got_operator <= 1'b0;
            r_got_last_num <= 1'b0;
            r_clr          <= 1'b0;
            r_internal_rst <= 1'b0;

            r_bcdu_instr_valid <= 1'b0;
            r_bcdu_instr       <= {`BCDU_OP_NOP, 12'b0};

            r_loopback_en     <= 1'b0;
            r_loopback_symbol <= `SYM_INVALID;

            r_print_start <= 1'b0;
            r_add_start   <= 1'b0;
            r_sub_start   <= 1'b0;
            r_mul_start   <= 1'b0;
            r_div_start   <= 1'b0;

            r_comma_inc <= 1'b0;
            r_comma_clr <= 1'b0;
            r_sign_set  <= 1'b0;
            r_sign_clr  <= 1'b0;
            r_ready     <= 1'b1;
        end else begin
            r_symbol_buf   <= n_symbol_buf;
            r_digit_cnt    <= n_digit_cnt;
            r_got_comma    <= n_got_comma;
            r_got_sign     <= n_got_sign;
            r_got_operator <= n_got_operator;
            r_got_last_num <= n_got_last_num;
            r_clr          <= n_clr;
            r_internal_rst <= n_internal_rst;

            r_bcdu_instr_valid <= n_bcdu_instr_valid;
            r_bcdu_instr       <= n_bcdu_instr;

            r_loopback_en     <= n_loopback_en;
            r_loopback_symbol <= n_loopback_symbol;

            r_print_start <= n_print_start;
            r_add_start   <= n_add_start;
            r_sub_start   <= n_sub_start;
            r_mul_start   <= n_mul_start;
            r_div_start   <= n_div_start;

            r_comma_inc <= n_comma_inc;
            r_comma_clr <= n_comma_clr;
            r_sign_set  <= n_sign_set;
            r_sign_clr  <= n_sign_clr;
            r_ready     <= n_ready;
        end
    end

endmodule
