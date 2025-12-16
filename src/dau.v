`timescale 1ns / 1ps

`include "dau_symbols.vh"
`include "bcdu_flags.vh"

module dau #(
    parameter NUM_DIGITS  = 4,
    parameter STACK_DEPTH = 7
)(
    input wire                       i_clk,
    input wire                       i_rst,
    input wire                       i_valid,
    input wire  [`DAU_SYM_WIDTH-1:0] i_symbol,
    output wire [`DAU_SYM_WIDTH-1:0] o_symbol,
    output wire                      o_symbol_valid,
    output wire                      o_ready
);

    localparam COMMA_WIDTH = $clog2(NUM_DIGITS);
    localparam ADDR_WIDTH  = $clog2(STACK_DEPTH);

    reg  [3:0] stack_ptr_reg;
    wire [3:0] stack_ptr_next;
    wire [3:0] stack_ptr      = stack_ptr_reg;
    wire [3:0] prev_stack_ptr = ((stack_ptr_reg == 0) ? 0 : (stack_ptr_reg - 1));

    reg                 wr_sign_comma_en;
    reg [COMMA_WIDTH:0] wr_sign_comma;

    wire rd_prev_sign;
    wire rd_sign;

    wire [COMMA_WIDTH-1:0] rd_prev_comma;
    wire [COMMA_WIDTH-1:0] rd_comma;

    reg_file #(
        .REG_WIDTH(COMMA_WIDTH + 1),
        .NUM_REGS(STACK_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) sign_comma_reg_file_inst (
        .i_clk(i_clk),
        .i_wr_en(wr_sign_comma_en),
        .i_wr_addr(stack_ptr[ADDR_WIDTH-1:0]),
        .i_wr_data(wr_sign_comma),
        .i_rd_addr_a(prev_stack_ptr[ADDR_WIDTH-1:0]),
        .o_rd_data_a({rd_prev_sign, rd_prev_comma}),
        .i_rd_addr_b(stack_ptr[ADDR_WIDTH-1:0]),
        .o_rd_data_b({rd_sign, rd_comma})
    );

    reg                        bcdu_instr_valid;
    reg                 [15:0] bcdu_instr;
    wire                 [3:0] bcdu_digit;
    wire [`BCDU_NUM_FLAGS-1:0] bcdu_flags;
    wire                       bcdu_ready;

    bcdu #(
        .NUM_DIGITS(NUM_DIGITS),
        .NUM_REGS(STACK_DEPTH + 2)
    ) bcdu_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(bcdu_instr_valid),
        .i_instr(bcdu_instr),
        .o_digit(bcdu_digit),
        .o_flags(bcdu_flags),
        .o_ready(bcdu_ready)
    );

    wire        inp_dec_bcdu_instr_valid;
    wire [15:0] inp_dec_bcdu_instr;

    wire                      loopback_en;
    wire [`DAU_SYM_WIDTH-1:0] loopback_symbol;

    wire print_start;
    wire print_done;
    wire add_start;
    wire sub_start;
    wire mul_start;
    wire div_start;

    reg add_sub_done_reg, add_sub_done_next, add_sub_done;
    reg mul_done_reg, mul_done_next, mul_done;
    reg div_done_reg, div_done_next, div_done;

    initial begin
        add_sub_done_reg = 1'b1;
        mul_done_reg     = 1'b1;
        div_done_reg     = 1'b1;
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            add_sub_done_reg <= 1'b1;
            mul_done_reg     <= 1'b1;
            div_done_reg     <= 1'b1;
        end else begin 
            add_sub_done_reg <= add_sub_done_next;
            mul_done_reg     <= mul_done_next;
            div_done_reg     <= div_done_next;
        end
    end

    wire comma_inc;
    wire comma_clr;
    wire sign_set;
    wire sign_clr;

    wire op_done = print_done | add_sub_done | mul_done | div_done;

    dau_input_decoder #(
        .NUM_DIGITS(NUM_DIGITS),
        .STACK_DEPTH(STACK_DEPTH)
    ) inp_dec_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_symbol(i_symbol),
        .i_stack_ptr(stack_ptr),
        .i_operation_done(op_done),
        .o_bcdu_instr_valid(inp_dec_bcdu_instr_valid),
        .o_bcdu_instr(inp_dec_bcdu_instr),
        .o_loopback_en(loopback_en),
        .o_loopback_symbol(loopback_symbol),
        .o_print_start(print_start),
        .o_add_start(add_start),
        .o_sub_start(sub_start),
        .o_mul_start(mul_start),
        .o_div_start(div_start),
        .o_comma_inc(comma_inc),
        .o_comma_clr(comma_clr),
        .o_sign_set(sign_set),
        .o_sign_clr(sign_clr),
        .o_stack_ptr_next(stack_ptr_next),
        .o_ready(o_ready)
    );

    wire        out_fmt_bcdu_instr_valid;
    wire [15:0] out_fmt_bcdu_instr;

    dau_output_formatter #(
        .NUM_DIGITS(NUM_DIGITS),
        .COMMA_WIDTH(COMMA_WIDTH)
    ) out_fmt_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_loopback_en(loopback_en),
        .i_loopback_symbol(loopback_symbol),
        .i_stream_start(print_start),
        .i_sign(rd_sign),
        .i_comma(rd_comma),
        .i_bcdu_addr(stack_ptr),
        .i_bcdu_digit(bcdu_digit),
        .i_bcdu_flags(bcdu_flags),
        .o_bcdu_instr(out_fmt_bcdu_instr),
        .o_bcdu_instr_valid(out_fmt_bcdu_instr_valid),
        .o_symbol(o_symbol),
        .o_symbol_valid(o_symbol_valid),
        .o_stream_done(print_done)
    );

    // ADD SUB
    wire add_sub_instr_valid;
    wire [15:0] add_sub_instr;
    wire add_sub_sign;
    wire [COMMA_WIDTH-1:0] add_sub_comma_pos;
    wire add_sub_ready;

    dau_add_sub_seq #(
        .COMMA_POS_W(COMMA_WIDTH)
    ) u_add_sub_seq (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(add_start | sub_start),
        .i_sub(sub_start),
        .i_sign_a(rd_prev_sign),
        .i_sign_b(rd_sign),
        .i_comma_pos_a(rd_prev_comma),
        .i_comma_pos_b(rd_comma),
        .i_digits_addr_a(prev_stack_ptr),
        .i_digits_addr_b(stack_ptr),
        .i_gt_flag(bcdu_flags[`BCDU_GF]),
        .i_eq_flag(bcdu_flags[`BCDU_EF]),
        .i_instr_accept(bcdu_ready),
        .o_instr_valid(add_sub_instr_valid),
        .o_instr(add_sub_instr),
        .o_sign(add_sub_sign),
        .o_comma_pos(add_sub_comma_pos),
        .o_ready(add_sub_ready)
    );
    // ADD SUB

    // MUL
    wire mul_instr_valid;
    wire [15:0] mul_instr;
    wire mul_sign;
    wire [COMMA_WIDTH-1:0] mul_comma_pos;
    wire mul_ready;

    dau_mul_seq #(
        .N_DIGITS(NUM_DIGITS),
        .COMMA_POS_W(COMMA_WIDTH),
        .ACC_ADDR(STACK_DEPTH)
    ) u_mul_seq (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(mul_start),
        .i_sign_a(rd_prev_sign),
        .i_sign_b(rd_sign),
        .i_comma_pos_a(rd_prev_comma),
        .i_comma_pos_b(rd_comma),
        .i_digits_addr_a(prev_stack_ptr),
        .i_digits_addr_b(stack_ptr),
        .i_instr_accept(bcdu_ready),
        .o_instr_valid(mul_instr_valid),
        .o_instr(mul_instr),
        .o_sign(mul_sign),
        .o_comma_pos(mul_comma_pos),
        .o_ready(mul_ready)
    );
    // MUL

    // DIV
    wire div_instr_valid;
    wire [15:0] div_instr;
    wire div_sign;
    wire [COMMA_WIDTH-1:0] div_comma_pos;
    wire div_ready;

    dau_div_seq #(
        .N_DIGITS(NUM_DIGITS),
        .COMMA_POS_W(COMMA_WIDTH),
        .REM_ADDR(STACK_DEPTH),
        .QUO_ADDR(STACK_DEPTH + 1)
    ) u_div_seq (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(div_start),
        .i_sign_a(rd_prev_sign),
        .i_sign_b(rd_sign),
        .i_comma_pos_a(rd_prev_comma),
        .i_comma_pos_b(rd_comma),
        .i_flags(bcdu_flags),
        .i_digits_addr_a(prev_stack_ptr),
        .i_digits_addr_b(stack_ptr),
        .i_instr_accept(bcdu_ready),
        .o_instr_valid(div_instr_valid),
        .o_instr(div_instr),
        .o_sign(div_sign),
        .o_comma_pos(div_comma_pos),
        .o_ready(div_ready)
    );
    // DIV

    localparam BCDU_INSTR_SRC_WIDTH = 3;

    localparam BCDU_INSTR_SRC_INP_DEC = 0,
               BCDU_INSTR_SRC_OUT_FMT = 1,
               BCDU_INSTR_SRC_ADD_SUB_SEQ = 2,
               BCDU_INSTR_SRC_MUL_SEQ = 3,
               BCDU_INSTR_SRC_DIV_SEQ = 4;

    reg [BCDU_INSTR_SRC_WIDTH-1:0] bcdu_instr_src_reg, bcdu_instr_src_next;

    initial begin
        bcdu_instr_src_reg = BCDU_INSTR_SRC_INP_DEC;
    end

    always @* begin
        bcdu_instr_src_next = bcdu_instr_src_reg;

        if                 (print_start) bcdu_instr_src_next = BCDU_INSTR_SRC_OUT_FMT;
        else if (add_start || sub_start) bcdu_instr_src_next = BCDU_INSTR_SRC_ADD_SUB_SEQ;
        else if              (mul_start) bcdu_instr_src_next = BCDU_INSTR_SRC_MUL_SEQ;
        else if              (div_start) bcdu_instr_src_next = BCDU_INSTR_SRC_DIV_SEQ;
        else if                (op_done) bcdu_instr_src_next = BCDU_INSTR_SRC_INP_DEC;

        bcdu_instr_valid = inp_dec_bcdu_instr_valid;
        bcdu_instr       = inp_dec_bcdu_instr;

        case (bcdu_instr_src_reg)
            BCDU_INSTR_SRC_OUT_FMT: begin
                bcdu_instr_valid = out_fmt_bcdu_instr_valid;
                bcdu_instr       = out_fmt_bcdu_instr;
            end

            BCDU_INSTR_SRC_ADD_SUB_SEQ: begin
                bcdu_instr_valid = add_sub_instr_valid;
                bcdu_instr       = add_sub_instr;
            end

            BCDU_INSTR_SRC_MUL_SEQ: begin
                bcdu_instr_valid = mul_instr_valid;
                bcdu_instr       = mul_instr;
            end

            BCDU_INSTR_SRC_DIV_SEQ: begin
                bcdu_instr_valid = div_instr_valid;
                bcdu_instr       = div_instr;
            end
        endcase
    end

    always @(posedge i_clk) begin
        if (i_rst) bcdu_instr_src_reg <= BCDU_INSTR_SRC_INP_DEC;
        else       bcdu_instr_src_reg <= bcdu_instr_src_next;
    end

    always @(posedge i_clk) begin
        if (i_rst) stack_ptr_reg <= 0;
        else if ((add_sub_done_reg && !add_sub_ready) || (mul_done_reg && !mul_ready) || (div_done_reg && !div_ready)) stack_ptr_reg <= stack_ptr_reg - 1;
        else if ((!add_sub_done_reg && add_sub_ready) || (!mul_done_reg && mul_ready) || (!div_done_reg && div_ready)) stack_ptr_reg <= stack_ptr_reg + 1;
        else stack_ptr_reg <= stack_ptr_next;
    end

    always @* begin
        wr_sign_comma_en = 1'b0;
        wr_sign_comma    = {rd_sign, rd_comma};

        add_sub_done_next = add_sub_ready;
        add_sub_done      = 1'b0;

        mul_done_next = mul_ready;
        mul_done      = 1'b0;

        div_done_next = div_ready;
        div_done      = 1'b0;

        if (comma_clr) begin
            wr_sign_comma_en               = 1'b1;
            wr_sign_comma[COMMA_WIDTH-1:0] = 0;
        end else if (comma_inc) begin
            wr_sign_comma_en               = 1'b1;
            wr_sign_comma[COMMA_WIDTH-1:0] = (rd_comma + 1);
        end

        if (sign_clr) begin
            wr_sign_comma_en           = 1'b1;
            wr_sign_comma[COMMA_WIDTH] = 1'b0;
        end else if (sign_set) begin
            wr_sign_comma_en           = 1'b1;
            wr_sign_comma[COMMA_WIDTH] = 1'b1;
        end

        if (!add_sub_done_reg && add_sub_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = {add_sub_sign, add_sub_comma_pos};
            add_sub_done     = 1'b1;
        end else if (add_sub_done_reg && !add_sub_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = 0;
        end

        if (!mul_done_reg && mul_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = {mul_sign, mul_comma_pos};
            mul_done         = 1'b1;
        end else if (mul_done_reg && !mul_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = 0;
        end

        if (!div_done_reg && div_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = {div_sign, div_comma_pos};
            div_done         = 1'b1;
        end else if (div_done_reg && !div_ready) begin
            wr_sign_comma_en = 1'b1;
            wr_sign_comma    = 0;
        end
    end

endmodule
