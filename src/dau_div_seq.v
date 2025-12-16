`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

module dau_div_seq #(
    parameter       N_DIGITS    = 4,
    parameter       COMMA_POS_W = 4,
    parameter [3:0] REM_ADDR    = 6,
    parameter [3:0] QUO_ADDR    = 7
)(
    input wire                    i_clk,
    input wire                    i_rst,
    input wire                    i_start,
    input wire                    i_sign_a,
    input wire                    i_sign_b,
    input wire  [COMMA_POS_W-1:0] i_comma_pos_a,
    input wire  [COMMA_POS_W-1:0] i_comma_pos_b,
    input wire              [3:0] i_digits_addr_a,
    input wire              [3:0] i_digits_addr_b,
    input wire [`BCDU_NUM_FLAGS-1:0] i_flags,
    input wire                    i_instr_accept,
    output wire                   o_instr_valid,
    output wire            [15:0] o_instr,
    output wire                   o_sign,
    output wire [COMMA_POS_W-1:0] o_comma_pos,
    output wire                   o_ready
);

    localparam S_IDLE     = 4'h0;
    localparam S_ZERO_CMP = 4'h1;
    localparam S_QUO_CLR  = 4'h2;
    localparam S_DIV_SHL  = 4'h3;
    localparam S_REM_SHL  = 4'h4;
    localparam S_REM_SUB  = 4'h5;
    localparam S_QUO_SHL  = 4'h6;
    localparam S_REM_ADD  = 4'h7;
    localparam S_DVSR_CLR = 4'h8;
    localparam S_QUO_MOV  = 4'h9;

    reg [3:0] r_state, n_state;

    reg [3:0] r_sub_cnt, n_sub_cnt;

    reg [5:0] r_quo_digit_cnt, n_quo_digit_cnt;
    reg [5:0] r_div_digit_cnt, n_div_digit_cnt;

    reg r_got_msd, n_got_msd;

    initial begin
        r_state         = S_IDLE;
        r_sub_cnt       = 4'd0;
        r_quo_digit_cnt = 6'd0;
        r_div_digit_cnt = 6'd0;
        r_got_msd       = 1'b0;
    end

    reg                   r_start;
    reg [COMMA_POS_W-1:0] r_comma_pos_a;
    reg [COMMA_POS_W-1:0] r_comma_pos_b;
    reg             [3:0] r_digits_addr_a;
    reg             [3:0] r_digits_addr_b;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_comma_pos_a   <= 0;
            r_comma_pos_b   <= 0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == S_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
                r_comma_pos_a   <= i_comma_pos_a;
                r_comma_pos_b   <= i_comma_pos_b;
                r_digits_addr_a <= i_digits_addr_a;
                r_digits_addr_b <= i_digits_addr_b;
            end
        end else begin
            r_start <= 1'b0;
        end
    end

    reg        r_instr_valid, n_instr_valid;
    reg [15:0] r_instr, n_instr;

    assign o_instr_valid = r_instr_valid;
    assign o_instr       = r_instr;

    assign o_ready = (r_state == S_IDLE);

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_state         <= S_IDLE;
            r_sub_cnt       <= 4'd0;
            r_quo_digit_cnt <= 6'd0;
            r_div_digit_cnt <= 6'd0;
            r_got_msd       <= 1'b0;
            r_instr_valid   <= 1'b0;
            r_instr         <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state         <= n_state;
            r_sub_cnt       <= n_sub_cnt;
            r_quo_digit_cnt <= n_quo_digit_cnt;
            r_div_digit_cnt <= n_div_digit_cnt;
            r_got_msd       <= n_got_msd;
            r_instr_valid   <= n_instr_valid;
            r_instr         <= n_instr;
        end
    end

    reg                   r_sign;
    reg [COMMA_POS_W-1:0] r_comma_pos;

    assign o_sign      = r_sign;
    assign o_comma_pos = r_comma_pos;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_sign      <= 1'b0;
            r_comma_pos <= 0;
        end else begin
            if ((r_state == S_IDLE) && i_start) r_sign <= i_sign_a ^ i_sign_b;

            if (r_state == S_QUO_MOV) r_comma_pos <= (r_div_digit_cnt - N_DIGITS) + r_comma_pos_a - r_comma_pos_b;
        end
    end

    always @* begin
        n_state         = r_state;
        n_sub_cnt       = r_sub_cnt;
        n_quo_digit_cnt = r_quo_digit_cnt;
        n_div_digit_cnt = r_div_digit_cnt;
        n_got_msd       = r_got_msd;
        n_instr_valid   = 1'b0;
        n_instr         = {`BCDU_OP_NOP, 12'b0};

        if (i_instr_accept) begin
            case (r_state)
                S_IDLE: begin
                    if (i_start || r_start) begin
                        n_state         = S_ZERO_CMP;
                        n_sub_cnt       = 4'd0;
                        n_quo_digit_cnt = 6'd0;
                        n_div_digit_cnt = 6'd0;
                        n_got_msd       = 1'b0;
                        n_instr_valid   = 1'b1;
                        n_instr         = {`BCDU_OP_CLR, REM_ADDR, 8'b0};
                    end
                end

                S_ZERO_CMP: begin
                    n_state       = S_QUO_CLR;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CMP, REM_ADDR, r_digits_addr_b, 4'b0};
                end

                S_QUO_CLR: begin
                    n_state       = S_DIV_SHL;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, QUO_ADDR, 8'b0};
                end

                S_DIV_SHL: begin
                    if (r_quo_digit_cnt != N_DIGITS) begin
                        n_state         = S_REM_SHL;
                        n_div_digit_cnt = r_div_digit_cnt + 1;
                        n_instr_valid   = 1'b1;
                        n_instr         = {`BCDU_OP_SHL, r_digits_addr_a, 2'b11, 6'b0};
                    end else begin
                        n_state       = S_QUO_MOV;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                    end
                end

                S_REM_SHL: begin
                    if (i_flags[`BCDU_EF]) begin
                        n_state       = S_QUO_MOV;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                    end else begin
                        n_state       = S_REM_SUB;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, REM_ADDR, 2'b11, 6'hA};
                    end
                end

                S_REM_SUB: begin
                    if ((r_sub_cnt == 4'd1) && !i_flags[`BCDU_TF] && !r_got_msd) begin
                        n_state       = S_DIV_SHL;
                        n_sub_cnt     = 4'd0;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_ADD, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else if ((r_sub_cnt >= 4'd2) && i_flags[`BCDU_ZF] && (r_div_digit_cnt > N_DIGITS)) begin
                        n_state       = S_DVSR_CLR;
                        n_sub_cnt     = 4'd0;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, QUO_ADDR, 4'b1100, r_sub_cnt - 4'd2};
                    end else if ((r_sub_cnt < 4'd3) || i_flags[`BCDU_CF]) begin
                        n_sub_cnt     = r_sub_cnt + 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SUB, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else begin
                        n_state = S_QUO_SHL;
                    end

                    if (r_sub_cnt == 4'd2) n_got_msd = 1'b1;
                end

                S_QUO_SHL: begin
                    n_state         = S_REM_ADD;
                    n_sub_cnt       = 4'd3;
                    n_quo_digit_cnt = r_quo_digit_cnt + 1;
                    n_instr_valid   = 1'b1;
                    n_instr         = {`BCDU_OP_SHL, QUO_ADDR, 4'b1100, r_sub_cnt - 4'd3};
                end

                S_REM_ADD: begin
                    if (r_sub_cnt != 0) begin
                        n_sub_cnt     = r_sub_cnt - 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_ADD, REM_ADDR, REM_ADDR, r_digits_addr_b};
                    end else begin
                        n_state = S_DIV_SHL;
                    end
                end

                S_DVSR_CLR: begin
                    n_state       = S_QUO_MOV;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};
                end

                S_QUO_MOV: begin
                    n_state       = S_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_MOV, r_digits_addr_a, QUO_ADDR, 4'b0};
                end
            endcase
        end
    end

endmodule
