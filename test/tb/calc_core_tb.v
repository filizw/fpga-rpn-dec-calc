`timescale 1ns / 1ps

`include "test/tb/common.vh"

module calc_core_tb ();
    
    localparam T = 10;

    localparam NUM_DIGITS  = 10;
    localparam STACK_DEPTH = 7;

    reg                       i_clk;
    reg                       i_rst;
    reg                       i_valid;
    reg  [`SYM_WIDTH-1:0] i_symbol;
    wire [`SYM_WIDTH-1:0] o_symbol;
    wire                      o_symbol_valid;
    wire                      o_ready;

    calc_core #(
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
        `TEST_START("calc_core", "out/vcd/calc_core_tb.vcd", calc_core_tb)

        i_clk    = 1'b0;
        i_rst    = 1'b1;
        i_valid  = 1'b0;
        i_symbol = `SYM_INVALID;

        @(negedge i_clk);

        i_rst   = 1'b0;
        i_valid = 1'b1;

        @(negedge i_clk);

        i_symbol = `SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_2;
        @(negedge i_clk);
        i_symbol = `SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `SYM_3;
        @(negedge i_clk);
        i_symbol = `SYM_4;
        @(negedge i_clk);
        i_symbol = `SYM_5;
        @(negedge i_clk);
        i_symbol = `SYM_6;
        @(negedge i_clk);
        i_symbol = `SYM_7;
        @(negedge i_clk);
        i_symbol = `SYM_8;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `SYM_5;
        @(negedge i_clk);
        i_symbol = `SYM_6;
        @(negedge i_clk);
        i_symbol = `SYM_7;
        @(negedge i_clk);
        i_symbol = `SYM_8;
        @(negedge i_clk);
        i_symbol = `SYM_9;
        @(negedge i_clk);
        i_symbol = `SYM_9;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #120;

        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `SYM_2;
        @(negedge i_clk);
        i_symbol = `SYM_5;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        @(negedge i_clk);
        i_symbol = `SYM_RESET;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;

        @(negedge i_clk);
        i_symbol = `SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #160;

        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_3;
        @(negedge i_clk);
        i_symbol = `SYM_0;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `SYM_2;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;

        @(negedge i_clk);
        i_symbol = `SYM_PLUS;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;
        
        #70;

        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #160;

        // MUL

        @(negedge i_clk);
        i_symbol = `SYM_RESET;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_COMMA;
        @(negedge i_clk);
        i_symbol = `SYM_2;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_1;
        @(negedge i_clk);
        i_symbol = `SYM_0;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_MUL;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);

        #1000;

        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #160;

        // DIV

        @(negedge i_clk);
        i_symbol = `SYM_RESET;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `SYM_5;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_5;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_DIV;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);

        #2000;

        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #160;

        @(negedge i_clk);
        i_symbol = `SYM_RESET;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        #100;

        @(negedge i_clk);
        i_symbol = `SYM_MINUS;
        @(negedge i_clk);
        i_symbol = `SYM_3;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_7;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);
        i_symbol = `SYM_DIV;
        @(negedge i_clk);
        i_symbol = `SYM_SEPARATOR;
        @(negedge i_clk);

        #2000;

        @(negedge i_clk);
        i_symbol = `SYM_RESULT;
        @(negedge i_clk);
        i_symbol = `SYM_INVALID;

        i_valid = 1'b0;

        #200;

        `TEST_END("calc_core")
    end

endmodule
