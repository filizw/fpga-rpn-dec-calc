`timescale 1ns / 1ps

`include "dau_symbols.vh"
`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

module dau_output_formatter #(
    parameter NUM_DIGITS  = 4,
    parameter COMMA_WIDTH = 2
)(
    input wire                       i_clk,
    input wire                       i_rst,
    input wire                       i_loopback_en,
    input wire  [`DAU_SYM_WIDTH-1:0] i_loopback_symbol,
    input wire                       i_stream_start,
    input wire                       i_sign,
    input wire     [COMMA_WIDTH-1:0] i_comma,
    input wire                 [3:0] i_bcdu_addr,
    input wire                 [3:0] i_bcdu_digit,
    input wire [`BCDU_NUM_FLAGS-1:0] i_bcdu_flags,
    output wire               [15:0] o_bcdu_instr,
    output wire                      o_bcdu_instr_valid,
    output wire [`DAU_SYM_WIDTH-1:0] o_symbol,
    output wire                      o_symbol_valid,
    output wire                      o_stream_done
);
    
    localparam STATE_WIDTH = 3;

    localparam STATE_LOOPBACK = 0,
               STATE_NEW_LINE = 1,
               STATE_SIGN     = 2,
               STATE_DIGITS   = 3,
               STATE_DONE     = 4;
    
    reg [STATE_WIDTH-1:0] state_reg, state_next;

    localparam DIGIT_IDX_WIDTH = $clog2(NUM_DIGITS);
    localparam SHIFT_AMT_WIDTH = $clog2(NUM_DIGITS + 1);

    reg [DIGIT_IDX_WIDTH-1:0] digit_idx_reg, digit_idx_next;
    reg [SHIFT_AMT_WIDTH-1:0] shift_amt_reg, shift_amt_next;

    assign o_bcdu_instr       = {`BCDU_OP_SHR, i_bcdu_addr, 2'b00, {6-SHIFT_AMT_WIDTH{1'b0}}, shift_amt_reg};
    assign o_bcdu_instr_valid = ((state_reg == STATE_DIGITS) && (shift_amt_reg != 0));

    reg  got_msd_reg, got_msd_next;
    wire got_msd = (got_msd_reg ? 1'b1 : got_msd_next);

    reg  got_comma_reg, got_comma_next;
    wire got_comma = (got_comma_reg ? 1'b1 : got_comma_next);

    reg [`DAU_SYM_WIDTH-1:0] symbol_buf_reg, symbol_buf_next;
    reg [`DAU_SYM_WIDTH-1:0] symbol_out_reg, symbol_out_next;
    reg                      symbol_out_valid_reg, symbol_out_valid_next;

    assign o_symbol       = symbol_out_reg;
    assign o_symbol_valid = symbol_out_valid_reg;

    assign o_stream_done = (state_reg == STATE_DONE);

    wire zero_left = ((i_bcdu_digit == 4'd0) && !i_bcdu_flags[`BCDU_TF]);

    reg zero_left_reg;

    initial begin
        zero_left_reg <= 1'b0;
    end

    always @(posedge i_clk) begin
        if (i_rst) zero_left_reg <= 1'b0;
        else if ((state_reg == STATE_DIGITS) && !zero_left_reg) zero_left_reg <= zero_left;
        else if (state_reg == STATE_LOOPBACK) zero_left_reg <= 1'b0;
    end

    function automatic [`DAU_SYM_WIDTH-1:0] digit_to_symbol;
        input [3:0] digit;
        digit_to_symbol = {{`DAU_SYM_WIDTH-4{1'b1}}, digit};
    endfunction

    always @* begin
        state_next            = state_reg;
        digit_idx_next        = digit_idx_reg;
        shift_amt_next        = shift_amt_reg;
        got_msd_next          = got_msd_reg;
        got_comma_next        = got_comma_reg;
        symbol_buf_next       = symbol_buf_reg;
        symbol_out_next       = symbol_out_reg;
        symbol_out_valid_next = 1'b0;

        case (state_reg)
            STATE_LOOPBACK: begin
                digit_idx_next = (NUM_DIGITS - 1);
                shift_amt_next = NUM_DIGITS;
                got_msd_next   = 1'b0;
                got_comma_next = 1'b0;

                if (i_loopback_en) begin
                    symbol_out_next       = i_loopback_symbol;
                    symbol_out_valid_next = 1'b1;
                end

                if (i_stream_start) state_next = STATE_NEW_LINE;
            end

            STATE_NEW_LINE: begin
                symbol_out_next       = `DAU_SYM_NEW_LINE;
                symbol_out_valid_next = 1'b1;

                state_next = STATE_SIGN;
            end

            STATE_SIGN: begin
                if (i_sign == 1'b1) begin
                    symbol_out_next       = `DAU_SYM_MINUS;
                    symbol_out_valid_next = 1'b1;
                end

                state_next = STATE_DIGITS;
            end

            STATE_DIGITS: begin
                if (shift_amt_reg != 0) shift_amt_next = (shift_amt_reg - 1);

                if (i_bcdu_digit != 4'hF) begin
                    digit_idx_next = (digit_idx_reg - 1);

                    if (!got_msd_reg && ((i_bcdu_digit != 4'd0) || (i_comma == digit_idx_reg))) got_msd_next = 1'b1;

                    if ((i_comma != 0) && ((i_comma - 1) == digit_idx_reg)) begin
                        got_comma_next = 1'b1;

                        symbol_buf_next = digit_to_symbol(i_bcdu_digit);
                        symbol_out_next = `DAU_SYM_COMMA;

                        if (!zero_left) symbol_out_valid_next = 1'b1;
                    end else if (got_msd_reg || got_msd_next) begin
                        symbol_out_valid_next = 1'b1;

                        if (got_comma_reg) begin
                            symbol_buf_next = digit_to_symbol(i_bcdu_digit);
                            symbol_out_next = symbol_buf_reg;
                        end else begin
                            symbol_out_next = digit_to_symbol(i_bcdu_digit);
                        end
                    end
                end

                if ((digit_idx_reg == 0) || ((got_comma_reg || got_comma_next) && zero_left)) state_next = STATE_DONE;
            end

            STATE_DONE: begin
                state_next = STATE_LOOPBACK;

                if (got_comma_reg && !zero_left_reg) begin
                    symbol_out_next       = symbol_buf_reg;
                    symbol_out_valid_next = 1'b1;
                end
            end
        endcase
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            state_reg            <= STATE_LOOPBACK;
            digit_idx_reg        <= (NUM_DIGITS - 1);
            shift_amt_reg        <= NUM_DIGITS;
            got_msd_reg          <= 1'b0;
            got_comma_reg        <= 1'b0;
            symbol_buf_reg       <= `DAU_SYM_INVALID;
            symbol_out_reg       <= `DAU_SYM_INVALID;
            symbol_out_valid_reg <= 1'b0;
        end else begin
            state_reg            <= state_next;
            digit_idx_reg        <= digit_idx_next;
            shift_amt_reg        <= shift_amt_next;
            got_msd_reg          <= got_msd_next;
            got_comma_reg        <= got_comma_next;
            symbol_buf_reg       <= symbol_buf_next;
            symbol_out_reg       <= symbol_out_next;
            symbol_out_valid_reg <= symbol_out_valid_next;
        end
    end

endmodule
