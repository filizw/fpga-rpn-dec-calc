`timescale 1ns / 1ps

`include "bcdu_op_codes.vh"
`include "bcdu_flags.vh"

module dau_add_sub_seq #(
    parameter COMMA_POS_W = 4
)(
    input wire                    i_clk,
    input wire                    i_rst,
    input wire                    i_start,
    input wire                    i_sub,
    input wire                    i_sign_a,
    input wire                    i_sign_b,
    input wire  [COMMA_POS_W-1:0] i_comma_pos_a,
    input wire  [COMMA_POS_W-1:0] i_comma_pos_b,
    input wire              [3:0] i_digits_addr_a,
    input wire              [3:0] i_digits_addr_b,
    input wire                    i_gt_flag,
    input wire                    i_eq_flag,
    input wire                    i_instr_accept,
    output wire                   o_instr_valid,
    output wire            [15:0] o_instr,
    output wire                   o_sign,
    output wire [COMMA_POS_W-1:0] o_comma_pos,
    output wire                   o_ready
);

    localparam S_IDLE    = 3'h0;
    localparam S_COMPARE = 3'h1;
    localparam S_ADD_SUB = 3'h2;
    localparam S_WAIT    = 3'h3;
    localparam S_CLEAR   = 3'h4;
    localparam S_CORRECT = 3'h5;

    reg [2:0] r_state, n_state;

    initial begin
        r_state = S_IDLE;
    end

    reg                   r_start;
    reg                   r_sub;
    reg                   r_sign_a;
    reg                   r_sign_b;
    reg [COMMA_POS_W-1:0] r_comma_pos_a;
    reg [COMMA_POS_W-1:0] r_comma_pos_b;
    reg             [3:0] r_digits_addr_a;
    reg             [3:0] r_digits_addr_b;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_start         <= 1'b0;
            r_sub           <= 1'b0;
            r_sign_a        <= 1'b0;
            r_sign_b        <= 1'b0;
            r_comma_pos_a   <= 0;
            r_comma_pos_b   <= 0;
            r_digits_addr_a <= 4'b0;
            r_digits_addr_b <= 4'b0;
        end else if (r_state == S_IDLE) begin
            if (i_start) begin
                r_start         <= 1'b1;
                r_sub           <= i_sub;
                r_sign_a        <= i_sign_a;
                r_sign_b        <= i_sign_b;
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
            r_state       <= S_IDLE;
            r_instr_valid <= 1'b0;
            r_instr       <= {`BCDU_OP_NOP, 12'b0};
        end else begin
            r_state       <= n_state;
            r_instr_valid <= n_instr_valid;
            r_instr       <= n_instr;
        end
    end

    reg                   r_sign;
    reg [COMMA_POS_W-1:0] r_comma_pos;

    assign o_sign      = r_sign;
    assign o_comma_pos = r_comma_pos;

    wire comma_pos_a_gt_b = (r_comma_pos_a > r_comma_pos_b);

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_sign      <= 1'b0;
            r_comma_pos <= 0;
        end else if (r_state == S_CLEAR) begin
            r_sign      <= ~i_eq_flag & ((i_gt_flag & r_sign_a) | (~i_gt_flag & (r_sub ^ r_sign_b)));
            r_comma_pos <= comma_pos_a_gt_b ? r_comma_pos_a : r_comma_pos_b;
        end
    end

    wire subtract = (r_sub & ~(r_sign_a ^ r_sign_b)) | (~r_sub & (r_sign_a ^ r_sign_b));

    always @* begin
        n_state       = r_state;
        n_instr_valid = 1'b0;
        n_instr       = {`BCDU_OP_NOP, 12'b0};

        if (r_state == S_WAIT) n_state = S_CLEAR;

        if (i_instr_accept) begin
            case (r_state)
                S_IDLE: begin
                    if (i_start || r_start) begin
                        n_state       = S_COMPARE;
                        n_instr_valid = 1'b1;
                    end

                    if (r_start) begin
                        if (r_comma_pos_a > r_comma_pos_b) n_instr = {`BCDU_OP_SHL, r_digits_addr_b, 2'b10, {6-COMMA_POS_W{1'b0}}, r_comma_pos_a - r_comma_pos_b};
                        else                               n_instr = {`BCDU_OP_SHL, r_digits_addr_a, 2'b10, {6-COMMA_POS_W{1'b0}}, r_comma_pos_b - r_comma_pos_a};
                    end else begin
                        if (i_comma_pos_a > i_comma_pos_b) n_instr = {`BCDU_OP_SHL, i_digits_addr_b, 2'b10, {6-COMMA_POS_W{1'b0}}, i_comma_pos_a - i_comma_pos_b};
                        else                               n_instr = {`BCDU_OP_SHL, i_digits_addr_a, 2'b10, {6-COMMA_POS_W{1'b0}}, i_comma_pos_b - i_comma_pos_a};
                    end
                end

                S_COMPARE: begin
                    n_state       = S_ADD_SUB;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CMP, i_digits_addr_a, i_digits_addr_b, 4'b0};
                end

                S_ADD_SUB: begin
                    n_state       = S_WAIT;
                    n_instr_valid = 1'b1;
                    n_instr       = {(subtract ? `BCDU_OP_SUB : `BCDU_OP_ADD), r_digits_addr_a, r_digits_addr_a, r_digits_addr_b};
                end

                S_CLEAR: begin
                    n_state       = S_CLEAR;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_CLR, r_digits_addr_b, 8'b0};

                    if (!i_gt_flag && subtract) n_state = S_CORRECT;
                    else                                n_state = S_IDLE;
                end

                S_CORRECT: begin
                    n_state       = S_IDLE;
                    n_instr_valid = 1'b1;
                    n_instr       = {`BCDU_OP_SUB, r_digits_addr_a, r_digits_addr_b, r_digits_addr_a};
                end
            endcase
        end
    end

endmodule
