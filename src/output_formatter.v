`timescale 1ns / 1ps

`include "symbols.vh"
`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

// ============================================================================
// Output Formatter
// ============================================================================
// Formats BCDU numeric output into symbol stream form. Supports direct
// loopback symbols, signed-number streaming, comma insertion,
// and suppression of redundant trailing zeros.

module output_formatter #(
    parameter NUM_DIGITS      = 4, // Number of digits per operand
    parameter COMMA_POS_WIDTH = 2  // Bit width of comma position
)(
    input wire                       i_clk,                 // Clock
    input wire                       i_rst,                 // Reset
    input wire                       i_loopback_en,         // Send loopback symbol
    input wire      [`SYM_WIDTH-1:0] i_loopback_symbol,     // Loopback symbol
    input wire                       i_stream_start,        // Start formatted number stream
    input wire                       i_sign,                // Number sign (1 = minus)
    input wire [COMMA_POS_WIDTH-1:0] i_comma,               // Comma position
    input wire                 [3:0] i_bcdu_addr,           // Source BCDU register address
    input wire                 [3:0] i_bcdu_digit,          // Current BCDU digit
    input wire [`BCDU_NUM_FLAGS-1:0] i_bcdu_flags,          // BCDU status flags
    output wire               [15:0] o_bcdu_instr,          // BCDU instruction
    output wire                      o_bcdu_instr_valid,    // BCDU instruction valid
    output wire     [`SYM_WIDTH-1:0] o_symbol,              // Output symbol
    output wire                      o_symbol_valid,        // Output symbol valid
    output wire                      o_stream_done          // Stream finished
);
    
    // FSM state width
    localparam STATE_WIDTH = 3;

    // FSM state encoding
    localparam STATE_LOOPBACK = 0,
               STATE_NEW_LINE = 1,
               STATE_SIGN     = 2,
               STATE_DIGITS   = 3,
               STATE_DONE     = 4;
    
    // FSM state registers
    reg [STATE_WIDTH-1:0] state_reg, state_next;

    // Widths for digit index and BCDU shift amount
    localparam DIGIT_IDX_WIDTH = $clog2(NUM_DIGITS);
    localparam SHIFT_AMT_WIDTH = $clog2(NUM_DIGITS + 1);

    // Digit iteration and shift-control registers
    reg [DIGIT_IDX_WIDTH-1:0] digit_idx_reg, digit_idx_next;
    reg [SHIFT_AMT_WIDTH-1:0] shift_amt_reg, shift_amt_next;

    // Formatter drives SHR instructions while streaming digits
    assign o_bcdu_instr       = {`BCDU_OP_SHR, i_bcdu_addr, 2'b00, {6-SHIFT_AMT_WIDTH{1'b0}}, shift_amt_reg};
    assign o_bcdu_instr_valid = ((state_reg == STATE_DIGITS) && (shift_amt_reg != 0));

    // Tracks first significant digit
    reg  got_msd_reg, got_msd_next;
    wire got_msd = (got_msd_reg ? 1'b1 : got_msd_next);

    // Tracks comma insertion status
    reg  got_comma_reg, got_comma_next;
    wire got_comma = (got_comma_reg ? 1'b1 : got_comma_next);

    // Symbol buffering/output registers
    reg [`SYM_WIDTH-1:0] symbol_buf_reg, symbol_buf_next;
    reg [`SYM_WIDTH-1:0] symbol_out_reg, symbol_out_next;
    reg                      symbol_out_valid_reg, symbol_out_valid_next;

    assign o_symbol       = symbol_out_reg;
    assign o_symbol_valid = symbol_out_valid_reg;

    assign o_stream_done = (state_reg == STATE_DONE);

    // True when all remaining unshifted digits are zero
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

    // Convert a 4-bit BCD digit to symbol encoding
    function automatic [`SYM_WIDTH-1:0] digit_to_symbol;
        input [3:0] digit;
        digit_to_symbol = {{`SYM_WIDTH-4{1'b1}}, digit};
    endfunction

    // FSM: combinational next-state and output generation
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
                // Idle/loopback state: send direct symbols and await stream start
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
                // Prefix formatted stream with a newline
                symbol_out_next       = `SYM_NEW_LINE;
                symbol_out_valid_next = 1'b1;

                state_next = STATE_SIGN;
            end

            STATE_SIGN: begin
                // Send minus sign for negative values
                if (i_sign == 1'b1) begin
                    symbol_out_next       = `SYM_MINUS;
                    symbol_out_valid_next = 1'b1;
                end

                state_next = STATE_DIGITS;
            end

            STATE_DIGITS: begin
                // Stream digits, manage leading zeros and comma position
                if (shift_amt_reg != 0) shift_amt_next = (shift_amt_reg - 1);

                if (i_bcdu_digit != 4'hF) begin
                    digit_idx_next = (digit_idx_reg - 1);

                    if (!got_msd_reg && ((i_bcdu_digit != 4'd0) || (i_comma == digit_idx_reg))) got_msd_next = 1'b1;

                    if ((i_comma != 0) && ((i_comma - 1) == digit_idx_reg)) begin
                        got_comma_next = 1'b1;

                        symbol_buf_next = digit_to_symbol(i_bcdu_digit);
                        symbol_out_next = `SYM_COMMA;

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
                // Send deferred post-comma digit and return to loopback state
                state_next = STATE_LOOPBACK;

                if (got_comma_reg && !zero_left_reg) begin
                    symbol_out_next       = symbol_buf_reg;
                    symbol_out_valid_next = 1'b1;
                end
            end
        endcase
    end

    // Sequential state/register update
    always @(posedge i_clk) begin
        if (i_rst) begin
            state_reg            <= STATE_LOOPBACK;
            digit_idx_reg        <= (NUM_DIGITS - 1);
            shift_amt_reg        <= NUM_DIGITS;
            got_msd_reg          <= 1'b0;
            got_comma_reg        <= 1'b0;
            symbol_buf_reg       <= `SYM_INVALID;
            symbol_out_reg       <= `SYM_INVALID;
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
