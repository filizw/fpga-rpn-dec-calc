`timescale 1ns / 1ps

`include "dau_symbols.vh"
`include "bcdu_op_codes.vh"

module dau_input_decoder #(
    parameter NUM_DIGITS  = 4,
    parameter STACK_DEPTH = 7
)(
    input wire                       i_clk,
    input wire                       i_rst,
    input wire                       i_valid,
    input wire  [`DAU_SYM_WIDTH-1:0] i_symbol,
    input wire                 [3:0] i_stack_ptr,
    input wire                       i_operation_done,
    output wire                      o_bcdu_instr_valid,
    output wire               [15:0] o_bcdu_instr,
    output wire                      o_loopback_en,
    output wire [`DAU_SYM_WIDTH-1:0] o_loopback_symbol,
    output wire                      o_print_start,
    output wire                      o_add_start,
    output wire                      o_sub_start,
    output wire                      o_mul_start,
    output wire                      o_div_start,
    output wire                      o_comma_inc,
    output wire                      o_comma_clr,
    output wire                      o_sign_set,
    output wire                      o_sign_clr,
    output reg                 [3:0] o_stack_ptr_next,
    output wire                      o_ready
);

    localparam DIGIT_CNT_WIDTH = $clog2(NUM_DIGITS / 2 + 1);

    reg [`DAU_SYM_WIDTH-1:0] symbol_buf_reg, symbol_buf_next;

    reg [DIGIT_CNT_WIDTH-1:0] digit_cnt_reg, digit_cnt_next;

    reg got_comma_reg, got_comma_next;
    reg got_sign_reg, got_sign_next;
    reg got_operator_reg, got_operator_next;
    reg got_last_num_reg, got_last_num_next;

    reg clr_reg, clr_next;

    reg internal_rst_reg, internal_rst_next;

    reg        bcdu_instr_valid_reg, bcdu_instr_valid_next;
    reg [15:0] bcdu_instr_reg, bcdu_instr_next;

    assign o_bcdu_instr_valid = bcdu_instr_valid_reg;
    assign o_bcdu_instr       = bcdu_instr_reg;

    reg                      loopback_en_reg, loopback_en_next;
    reg [`DAU_SYM_WIDTH-1:0] loopback_symbol_reg, loopback_symbol_next;

    assign o_loopback_en     = loopback_en_reg;
    assign o_loopback_symbol = loopback_symbol_reg;

    reg print_start_reg, print_start_next;
    reg add_start_reg, add_start_next;
    reg sub_start_reg, sub_start_next;
    reg mul_start_reg, mul_start_next;
    reg div_start_reg, div_start_next;

    assign o_print_start = print_start_reg;
    assign o_add_start   = add_start_reg;
    assign o_sub_start   = sub_start_reg;
    assign o_mul_start   = mul_start_reg;
    assign o_div_start   = div_start_reg;

    reg comma_inc_reg, comma_inc_next;
    reg comma_clr_reg, comma_clr_next;
    reg sign_set_reg, sign_set_next;
    reg sign_clr_reg, sign_clr_next;
    reg ready_reg, ready_next;

    assign o_comma_inc     = comma_inc_reg;
    assign o_comma_clr     = comma_clr_reg;
    assign o_sign_set      = sign_set_reg;
    assign o_sign_clr      = sign_clr_reg;
    assign o_ready         = ready_reg;

    initial begin
        ready_reg = 1'b1;
    end

    always @* begin
        symbol_buf_next   = symbol_buf_reg;
        digit_cnt_next    = digit_cnt_reg;
        got_comma_next    = got_comma_reg;
        got_sign_next     = got_sign_reg;
        got_operator_next = 1'b0;
        got_last_num_next = got_last_num_reg;
        clr_next          = clr_reg;
        internal_rst_next = 1'b0;

        bcdu_instr_valid_next = 1'b0;
        bcdu_instr_next       = {`BCDU_OP_NOP, 12'b0};

        loopback_en_next     = 1'b0;
        loopback_symbol_next = `DAU_SYM_INVALID;

        print_start_next = 1'b0;
        add_start_next   = 1'b0;
        sub_start_next   = 1'b0;
        mul_start_next   = 1'b0;
        div_start_next   = 1'b0;

        comma_inc_next = 1'b0;
        comma_clr_next = 1'b0;
        sign_set_next  = 1'b0;
        sign_clr_next  = 1'b0;
        ready_next     = ready_reg;

        o_stack_ptr_next = i_stack_ptr;

        internal_rst_next = 1'b0;

        if (i_operation_done) ready_next = 1'b1;

        if (clr_reg) begin
            if (loopback_symbol_reg == `DAU_SYM_RESULT) begin
                loopback_en_next     = 1'b1;
                loopback_symbol_next = `DAU_SYM_NEW_LINE;
            end

            if (i_stack_ptr == 0) internal_rst_next = 1'b1;
            else                  o_stack_ptr_next = (i_stack_ptr - 1);

            comma_clr_next = 1'b1;
            sign_clr_next  = 1'b1;

            bcdu_instr_valid_next = 1'b1;
            bcdu_instr_next       = {`BCDU_OP_CLR, i_stack_ptr, 8'b0};
        end

        if (i_valid && ready_reg) begin
            if ((i_symbol >= `DAU_SYM_0) && (i_symbol <= `DAU_SYM_9) && (symbol_buf_reg != `DAU_SYM_RESULT) && (i_stack_ptr != STACK_DEPTH)) begin
                if (digit_cnt_reg < (NUM_DIGITS / 2)) begin
                    digit_cnt_next = (digit_cnt_reg + 1);

                    bcdu_instr_valid_next = 1'b1;
                    bcdu_instr_next       = {`BCDU_OP_SHL, i_stack_ptr, 2'b11, {6-`DAU_SYM_WIDTH{1'b0}}, i_symbol};

                    loopback_en_next     = 1'b1;
                    loopback_symbol_next = i_symbol;

                    if (got_comma_reg) comma_inc_next = 1'b1;

                    if ((symbol_buf_reg == `DAU_SYM_MINUS) && !got_sign_reg) begin
                        got_sign_next = 1'b1;

                        sign_set_next = 1'b1;
                    end

                    symbol_buf_next = i_symbol;
                end
            end else if ((i_symbol == `DAU_SYM_COMMA) && !got_comma_reg) begin
                got_comma_next = 1'b1;

                loopback_en_next     = 1'b1;
                loopback_symbol_next = i_symbol;

                if ((symbol_buf_reg == `DAU_SYM_MINUS) && !got_sign_reg) begin
                    got_sign_next = 1'b1;

                    sign_set_next = 1'b1;
                end

                symbol_buf_next = i_symbol;
            end else if (((i_symbol == `DAU_SYM_PLUS) || (i_symbol == `DAU_SYM_MINUS)) && ((symbol_buf_reg == `DAU_SYM_INVALID) || (symbol_buf_reg == `DAU_SYM_SEPARATOR))) begin
                loopback_en_next     = 1'b1;
                loopback_symbol_next = i_symbol;
                
                symbol_buf_next = i_symbol;
            end else if (((i_symbol == `DAU_SYM_MUL) || (i_symbol == `DAU_SYM_DIV)) && (symbol_buf_reg == `DAU_SYM_SEPARATOR)) begin
                loopback_en_next     = 1'b1;
                loopback_symbol_next = i_symbol;
                
                symbol_buf_next = i_symbol;
            end else if ((i_symbol == `DAU_SYM_SEPARATOR) && (symbol_buf_reg != `DAU_SYM_SEPARATOR) && (symbol_buf_reg != `DAU_SYM_INVALID)) begin
                if (i_stack_ptr != (STACK_DEPTH - 1)) begin
                    digit_cnt_next = 0;
                    got_comma_next = 1'b0;
                    got_sign_next  = 1'b0;
                end

                loopback_en_next     = 1'b1;
                loopback_symbol_next = i_symbol;

                if ((((symbol_buf_reg >= `DAU_SYM_0) && (symbol_buf_reg <= `DAU_SYM_9)) || (symbol_buf_reg == `DAU_SYM_RESULT)) && (i_stack_ptr != STACK_DEPTH)) o_stack_ptr_next = (i_stack_ptr + 1);

                if (((symbol_buf_reg == `DAU_SYM_PLUS) || (symbol_buf_reg == `DAU_SYM_MINUS) || (symbol_buf_reg == `DAU_SYM_MUL) || (symbol_buf_reg == `DAU_SYM_DIV)) && (i_stack_ptr > 1)) begin
                    add_start_next = (symbol_buf_reg == `DAU_SYM_PLUS);
                    sub_start_next = (symbol_buf_reg == `DAU_SYM_MINUS);
                    mul_start_next = (symbol_buf_reg == `DAU_SYM_MUL);
                    div_start_next = (symbol_buf_reg == `DAU_SYM_DIV);
                    ready_next     = 1'b0;

                    if (i_stack_ptr != 0) o_stack_ptr_next = (i_stack_ptr - 1);
                end

                symbol_buf_next = i_symbol;
            end else if ((i_symbol == `DAU_SYM_RESULT) && (symbol_buf_reg == `DAU_SYM_SEPARATOR)) begin
                loopback_en_next     = 1'b1;
                loopback_symbol_next = i_symbol;

                print_start_next = 1'b1;

                ready_next = 1'b0;

                o_stack_ptr_next = (i_stack_ptr - 1);

                symbol_buf_next = i_symbol;
            end else if (i_symbol == `DAU_SYM_RESET) begin
                loopback_en_next     = 1'b1;
                loopback_symbol_next = `DAU_SYM_RESULT;

                clr_next = 1'b1;

                ready_next = 1'b0;
            end
        end
    end

    always @(posedge i_clk) begin
        if (i_rst || internal_rst_reg) begin
            symbol_buf_reg   <= `DAU_SYM_INVALID;
            digit_cnt_reg    <= 0;
            got_comma_reg    <= 1'b0;
            got_sign_reg     <= 1'b0;
            got_operator_reg <= 1'b0;
            got_last_num_reg <= 1'b0;
            clr_reg          <= 1'b0;
            internal_rst_reg <= 1'b0;

            bcdu_instr_valid_reg <= 1'b0;
            bcdu_instr_reg       <= {`BCDU_OP_NOP, 12'b0};

            loopback_en_reg     <= 1'b0;
            loopback_symbol_reg <= `DAU_SYM_INVALID;

            print_start_reg <= 1'b0;
            add_start_reg   <= 1'b0;
            sub_start_reg   <= 1'b0;
            mul_start_reg   <= 1'b0;
            div_start_reg   <= 1'b0;

            comma_inc_reg <= 1'b0;
            comma_clr_reg <= 1'b0;
            sign_set_reg  <= 1'b0;
            sign_clr_reg  <= 1'b0;
            ready_reg     <= 1'b1;
        end else begin
            symbol_buf_reg   <= symbol_buf_next;
            digit_cnt_reg    <= digit_cnt_next;
            got_comma_reg    <= got_comma_next;
            got_sign_reg     <= got_sign_next;
            got_operator_reg <= got_operator_next;
            got_last_num_reg <= got_last_num_next;
            clr_reg          <= clr_next;
            internal_rst_reg <= internal_rst_next;

            bcdu_instr_valid_reg <= bcdu_instr_valid_next;
            bcdu_instr_reg       <= bcdu_instr_next;

            loopback_en_reg     <= loopback_en_next;
            loopback_symbol_reg <= loopback_symbol_next;

            print_start_reg <= print_start_next;
            add_start_reg   <= add_start_next;
            sub_start_reg   <= sub_start_next;
            mul_start_reg   <= mul_start_next;
            div_start_reg   <= div_start_next;

            comma_inc_reg <= comma_inc_next;
            comma_clr_reg <= comma_clr_next;
            sign_set_reg  <= sign_set_next;
            sign_clr_reg  <= sign_clr_next;
            ready_reg     <= ready_next;
        end
    end

endmodule
