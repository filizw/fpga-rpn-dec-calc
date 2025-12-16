`timescale 1ns / 1ps

`include "test/tb/common.vh"

module dau_tb ();
    
    localparam T = 10;

    localparam NUM_DIGITS  = 10;
    localparam STACK_DEPTH = 7;

    reg                       i_clk;
    reg                       i_rst;
    reg                       i_valid;
    reg  [`DAU_SYM_WIDTH-1:0] i_symbol;
    wire [`DAU_SYM_WIDTH-1:0] o_symbol;
    wire                      o_symbol_valid;
    wire                      o_ready;

    dau #(
        .NUM_DIGITS(NUM_DIGITS),
        .STACK_DEPTH(STACK_DEPTH)
    ) uut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_symbol(i_symbol),
        .o_symbol(o_symbol),
        .o_symbol_valid(o_symbol_valid),
        .o_ready(o_ready)
    );

    always #(T/2) i_clk = ~i_clk;

    initial begin
        `TEST_START("dau", "out/vcd/dau_tb.vcd", dau_tb)

        i_clk    = 1'b0;
        i_rst    = 1'b1;
        i_valid  = 1'b0;
        i_symbol = `DAU_SYM_INVALID;

        @(negedge i_clk);

        i_rst   = 1'b0;
        i_valid = 1'b1;

        @(negedge i_clk);

        i_symbol = `DAU_SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_2;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_3;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_4;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_5;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_6;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_7;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_8;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_5;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_6;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_7;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_8;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_9;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_9;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #120;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_2;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_5;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESET;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #160;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_3;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_0;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_2;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #160;

        // MUL

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESET;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_2;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_1;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_0;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_MUL;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);

        #1000;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #160;

        // DIV

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESET;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_5;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_5;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_DIV;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);

        #2000;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #160;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESET;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_3;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_7;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_DIV;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_SEPARATOR;
        @(negedge i_clk);

        #2000;

        @(negedge i_clk);
        i_symbol = `DAU_SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `DAU_SYM_INVALID;

        i_valid = 1'b0;

        #200;

        `TEST_END("dau")
    end

endmodule
