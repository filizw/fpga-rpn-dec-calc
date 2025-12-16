`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"

module dau_mul_seq #(
    parameter       N_DIGITS    = 4,
    parameter       COMMA_POS_W = 4,
    parameter [3:0] ACC_ADDR    = 7
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
    input wire                    i_instr_accept,
    output wire                   o_instr_valid,
    output wire            [15:0] o_instr,
    output wire                   o_sign,
    output wire [COMMA_POS_W-1:0] o_comma_pos,
    output wire                   o_ready
);

    localparam S_IDLE      = 3'h0;
    localparam S_LD_DIGIT  = 3'h1;
    localparam S_SHIFT_ACC = 3'h2;
    localparam S_START_ACC = 3'h3;
    localparam S_WAIT      = 3'h4;
    localparam S_MOVE      = 3'h5;

    reg [2:0] r_state, n_state;

    reg [$clog2(N_DIGITS)-1:0] r_digit_cnt, n_digit_cnt;

    initial begin
        r_state     = S_IDLE;
        r_digit_cnt = N_DIGITS;
    end

    reg       r_start;
    reg [3:0] r_digits_addr_a;
    reg [3:0] r_digits_addr_b;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == S_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
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
            r_state       <= S_IDLE;
            r_digit_cnt   <= N_DIGITS;
            r_instr_valid <= 1'b0;
            r_instr       <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state       <= n_state;
            r_digit_cnt   <= n_digit_cnt;
            r_instr_valid <= n_instr_valid;
            r_instr       <= n_instr;
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
        end else if ((r_state == S_IDLE) && i_start) begin
            r_sign      <= i_sign_a ^ i_sign_b;
            r_comma_pos <= i_comma_pos_a + i_comma_pos_b;
        end
    end

    always @* begin
        n_state       = r_state;
        n_digit_cnt   = r_digit_cnt;
        n_instr_valid = 1'b0;
        n_instr       = {`BCDU_OP_NOP, 12'b0};

        if (i_instr_accept) begin
            case (r_state)
                S_IDLE: begin
                    if (i_start || r_start) begin
                        n_state       = S_LD_DIGIT;
                        n_digit_cnt   = N_DIGITS;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_CLR, ACC_ADDR, 8'b0};
                    end
                end

                S_LD_DIGIT: begin
                    if (r_digit_cnt != 4'd0) begin
                        n_state       = S_SHIFT_ACC;
                        n_digit_cnt   = r_digit_cnt - 1;
                        n_instr_valid = 1'b1;
                        n_instr       = {`BCDU_OP_SHL, r_digits_addr_b, 2'b11, 6'b0};
                    end else begin
                        n_state = S_MOVE;
                    end
                end

                S_SHIFT_ACC: begin
                    n_state       = S_START_ACC;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_SHL, ACC_ADDR, 2'b11, 6'b0};
                end

                S_START_ACC: begin
                    n_state       = S_WAIT;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_ACA, ACC_ADDR, r_digits_addr_a, 4'b0};
                end

                S_WAIT: begin
                    n_state = S_LD_DIGIT;
                end

                S_MOVE: begin
                    n_state       = S_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_MOV, r_digits_addr_a, ACC_ADDR, 4'b0};
                end
            endcase
        end
    end

endmodule
