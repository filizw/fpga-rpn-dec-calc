`timescale 1ns / 1ps

`include "test/tb/common.vh"

module bcdu_tb ();
    
    localparam T = 10;

    localparam NUM_REGS   = 4;
    localparam NUM_DIGITS = 4;

    localparam REG0 = 4'h0;
    localparam REG1 = 4'h1;
    localparam REG2 = 4'h2;
    localparam REG3 = 4'h3;

    reg                        i_clk;
    reg                        i_rst;
    reg                        i_valid;
    reg                 [15:0] i_instr;
    wire                 [3:0] o_digit;
    wire [`BCDU_NUM_FLAGS-1:0] o_flags;
    wire                       o_ready;

    bcdu #(
        .NUM_REGS(NUM_REGS),
        .NUM_DIGITS(NUM_DIGITS)
    ) uut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_instr(i_instr),
        .o_digit(o_digit),
        .o_flags(o_flags),
        .o_ready(o_ready)
    );

    task LOAD_INSTR (
        input [15:0] instr
    );
        begin
            i_instr = instr;
            @(posedge i_clk);
            #1;
        end
    endtask

    task CHECK_OUTPUT (
        input integer               idx,
        input                 [3:0] e_digit,
        input [`BCDU_NUM_FLAGS-1:0] e_flags
    );
        begin
            `ASSERT_EQ_HEX(idx, "o_digit", o_digit, e_digit)
            `ASSERT_EQ_BIN(idx, "o_flags", o_flags, e_flags)
        end
    endtask

    task LOAD_AND_CHECK (
        input integer               idx,
        input                [15:0] instr,
        input                 [3:0] e_digit,
        input [`BCDU_NUM_FLAGS-1:0] e_flags
    );
        begin
            LOAD_INSTR(instr);
            CHECK_OUTPUT(idx, e_digit, e_flags);
        end
    endtask

    always #(T/2) i_clk = ~i_clk;

    initial begin
        `TEST_START("bcdu", "out/vcd/bcdu_tb.vcd", bcdu_tb)

        i_clk   = 1'b0;
        i_rst   = 1'b1;
        i_valid = 1'b1;
        i_instr = 16'b0;

        @(negedge i_clk);
        i_rst = 1'b0;

        LOAD_INSTR({`BCDU_OP_NOP, 12'b0});

        LOAD_AND_CHECK(1, {`BCDU_OP_SHL, REG0, 2'b11, 6'd1}, 4'hF, 5'b00000);
        LOAD_AND_CHECK(2, {`BCDU_OP_SHL, REG0, 2'b11, 6'd2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(3, {`BCDU_OP_SHL, REG0, 2'b11, 6'd3}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(4, {`BCDU_OP_SHL, REG0, 2'b11, 6'd4}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(5, {`BCDU_OP_SHL, REG0, 2'b11, 6'd5}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(6, {`BCDU_OP_SHL, REG0, 2'b11, 6'd6}, 4'h1, 5'b00010); // REG0 = 3456

        LOAD_AND_CHECK(7, {`BCDU_OP_SHR, REG1, 2'b11, 6'd9}, 4'h2, 5'b00010);
        LOAD_AND_CHECK(8, {`BCDU_OP_SHR, REG1, 2'b11, 6'd8}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(9, {`BCDU_OP_SHR, REG1, 2'b11, 6'd7}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(10, {`BCDU_OP_SHR, REG1, 2'b11, 6'd6}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(11, {`BCDU_OP_SHR, REG1, 2'b11, 6'd5}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(12, {`BCDU_OP_SHR, REG1, 2'b11, 6'd4}, 4'h9, 5'b00010); // REG1 = 4567

        LOAD_AND_CHECK(13, {`BCDU_OP_SHL, REG0, 2'b10, 6'd3}, 4'h8, 5'b00010); // REG0 = 6000
        LOAD_AND_CHECK(14, {`BCDU_OP_SHR, REG1, 2'b10, 6'd2}, 4'h5, 5'b00010); // REG1 = 45

        LOAD_AND_CHECK(15, {`BCDU_OP_SHR, REG0, 2'b00, 6'd1}, 4'h6, 5'b00010);
        LOAD_AND_CHECK(16, {`BCDU_OP_SHR, REG0, 2'b00, 6'd2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(17, {`BCDU_OP_SHR, REG0, 2'b00, 6'd3}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(18, {`BCDU_OP_SHR, REG0, 2'b00, 6'd4}, 4'h0, 5'b00000);

        LOAD_AND_CHECK(19, {`BCDU_OP_SHR, REG1, 2'b00, 6'd1}, 4'h6, 5'b00011);
        LOAD_AND_CHECK(20, {`BCDU_OP_SHR, REG1, 2'b00, 6'd2}, 4'h5, 5'b00010);
        LOAD_AND_CHECK(21, {`BCDU_OP_SHR, REG1, 2'b00, 6'd3}, 4'h4, 5'b00011);
        LOAD_AND_CHECK(22, {`BCDU_OP_SHR, REG1, 2'b00, 6'd4}, 4'h0, 5'b00011);

        LOAD_AND_CHECK(23, {`BCDU_OP_ADD, REG2, REG0, REG1}, 4'h0, 5'b00011); // REG2 = 6045
        LOAD_AND_CHECK(24, {`BCDU_OP_SUB, REG3, REG0, REG1}, 4'hF, 5'b00000); // REG3 = 5955

        LOAD_AND_CHECK(25, {`BCDU_OP_SHR, REG2, 2'b00, 6'd1}, 4'hF, 5'b00100);
        LOAD_AND_CHECK(26, {`BCDU_OP_SHR, REG2, 2'b00, 6'd2}, 4'h5, 5'b00010);
        LOAD_AND_CHECK(27, {`BCDU_OP_SHR, REG2, 2'b00, 6'd3}, 4'h4, 5'b00010);
        LOAD_AND_CHECK(28, {`BCDU_OP_SHR, REG2, 2'b00, 6'd4}, 4'h0, 5'b00010);

        LOAD_AND_CHECK(29, {`BCDU_OP_SHR, REG3, 2'b00, 6'd1}, 4'h6, 5'b00011);
        LOAD_AND_CHECK(30, {`BCDU_OP_SHR, REG3, 2'b00, 6'd2}, 4'h5, 5'b00010);
        LOAD_AND_CHECK(31, {`BCDU_OP_SHR, REG3, 2'b00, 6'd3}, 4'h5, 5'b00010);
        LOAD_AND_CHECK(32, {`BCDU_OP_SHR, REG3, 2'b00, 6'd4}, 4'h9, 5'b00010);
        LOAD_AND_CHECK(33, {`BCDU_OP_NOP, 12'b0}, 4'h5, 5'b00011);

        LOAD_AND_CHECK(34, {`BCDU_OP_CLR, REG1, 8'b0}, 4'hF, 5'b00000); // REG1 = 0
        LOAD_AND_CHECK(35, {`BCDU_OP_SHR, REG1, 2'b11, 6'd7}, 4'hF, 5'b00000); // REG1 = 7000

        LOAD_AND_CHECK(36, {`BCDU_OP_SHR, REG1, 2'b00, 6'd1}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(37, {`BCDU_OP_SHR, REG1, 2'b00, 6'd2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(38, {`BCDU_OP_SHR, REG1, 2'b00, 6'd3}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(39, {`BCDU_OP_SHR, REG1, 2'b00, 6'd4}, 4'h0, 5'b00000);

        LOAD_AND_CHECK(40, {`BCDU_OP_ADD, REG2, REG0, REG1}, 4'h7, 5'b00011); // REG2 = 3000
        LOAD_AND_CHECK(41, {`BCDU_OP_SUB, REG3, REG0, REG1}, 4'hF, 5'b00100); // REG3 = 9000

        LOAD_AND_CHECK(42, {`BCDU_OP_SHR, REG2, 2'b00, 6'h1}, 4'hF, 5'b00000);
        LOAD_AND_CHECK(43, {`BCDU_OP_SHR, REG2, 2'b00, 6'h2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(44, {`BCDU_OP_SHR, REG2, 2'b00, 6'h3}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(45, {`BCDU_OP_SHR, REG2, 2'b00, 6'h4}, 4'h0, 5'b00000);

        LOAD_AND_CHECK(46, {`BCDU_OP_SHR, REG3, 2'b00, 6'h1}, 4'h3, 5'b00011);
        LOAD_AND_CHECK(47, {`BCDU_OP_SHR, REG3, 2'b00, 6'h2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(48, {`BCDU_OP_SHR, REG3, 2'b00, 6'h3}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(49, {`BCDU_OP_SHR, REG3, 2'b00, 6'h4}, 4'h0, 5'b00000);

        LOAD_AND_CHECK(50, {`BCDU_OP_MOV, REG2, REG1, 4'b0}, 4'h9, 5'b00011); // REG2 = 7000
        LOAD_AND_CHECK(51, {`BCDU_OP_CMP, REG0, REG1, 4'b0}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(52, {`BCDU_OP_CMP, REG1, REG0, 4'b0}, 4'hF, 5'b00000);
        LOAD_AND_CHECK(53, {`BCDU_OP_CMP, REG1, REG2, 4'b0}, 4'hF, 5'b01000);
        LOAD_AND_CHECK(54, {`BCDU_OP_NOP, 12'b0}, 4'hF, 5'b10000);

        LOAD_AND_CHECK(55, {`BCDU_OP_CLR, REG0, 8'b0}, 4'hF, 5'b00000); // REG0 = 0
        LOAD_AND_CHECK(56, {`BCDU_OP_CLR, REG1, 8'b0}, 4'hF, 5'b00000);
        LOAD_AND_CHECK(57, {`BCDU_OP_SHL, REG1, 2'b11, 6'd2}, 4'hF, 5'b00000);
        LOAD_AND_CHECK(58, {`BCDU_OP_SHL, REG1, 2'b11, 6'd3}, 4'h0, 5'b00000); // REG1 = 23

        LOAD_AND_CHECK(59, {`BCDU_OP_ACA, REG0, REG1, 4'd5}, 4'h0, 5'b00000); // REG0 = 115
        wait(o_ready);
        LOAD_INSTR({`BCDU_OP_NOP, 12'b0});
        CHECK_OUTPUT(60, 4'hF, 5'b00000);

        LOAD_INSTR({`BCDU_OP_SHR, REG0, 2'b00, 6'h1});
        LOAD_AND_CHECK(61, {`BCDU_OP_SHR, REG0, 2'b00, 6'h2}, 4'h5, 5'b00010);
        LOAD_AND_CHECK(62, {`BCDU_OP_SHR, REG0, 2'b00, 6'h3}, 4'h1, 5'b00010);
        LOAD_AND_CHECK(63, {`BCDU_OP_SHR, REG0, 2'b00, 6'h4}, 4'h1, 5'b00011);
        LOAD_AND_CHECK(64, {`BCDU_OP_MOV, REG2, REG0, 4'b0}, 4'h0, 5'b00011); // REG2 = 115

        LOAD_AND_CHECK(65, {`BCDU_OP_SHR, REG1, 2'b10, 6'd1}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(66, {`BCDU_OP_SHL, REG1, 2'b11, 6'd5}, 4'h3, 5'b00010); // REG1 = 25

        LOAD_AND_CHECK(67, {`BCDU_OP_ACS, REG0, REG1, 4'd5}, 4'h0, 5'b00000); // REG0 = 9990
        wait(o_ready);
        LOAD_INSTR({`BCDU_OP_NOP, 12'b0});
        CHECK_OUTPUT(68, 4'hF, 5'b00000);

        LOAD_INSTR({`BCDU_OP_SHR, REG0, 2'b00, 6'd1});
        LOAD_AND_CHECK(69, {`BCDU_OP_SHR, REG0, 2'b00, 6'd2}, 4'h0, 5'b00000);
        LOAD_AND_CHECK(70, {`BCDU_OP_SHR, REG0, 2'b00, 6'd3}, 4'h9, 5'b00010);
        LOAD_AND_CHECK(71, {`BCDU_OP_SHR, REG0, 2'b00, 6'd4}, 4'h9, 5'b00010);

        LOAD_AND_CHECK(72, {`BCDU_OP_SHR, REG1, 2'b00, 6'd1}, 4'h9, 5'b00011);

        LOAD_AND_CHECK(73, {`BCDU_OP_ACA, REG0, REG1, 4'd0}, 4'h5, 5'b00010); // REG0 = 115
        wait(o_ready);
        LOAD_INSTR({`BCDU_OP_NOP, 12'b0});
        CHECK_OUTPUT(74, 4'hF, 5'b00100);

        LOAD_INSTR({`BCDU_OP_CMP, REG0, REG2, 4'b0});
        LOAD_AND_CHECK(75, {`BCDU_OP_NOP, 12'b0}, 4'hF, 5'b10000);

        `TEST_END("bcdu")
    end

endmodule
