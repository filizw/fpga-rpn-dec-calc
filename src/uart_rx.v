`timescale 1ns / 1ps

module uart_rx #(
    parameter DATA_BITS     = 8,
    parameter TICKS_PER_BIT = 16
)(
    input wire                  i_clk,
    input wire                  i_rst,
    input wire                  i_rx,
    input wire                  i_tick_en,
    output reg                  o_rx_done,
    output wire [DATA_BITS-1:0] o_data
);
    
    localparam TICK_CNT_WIDTH = $clog2(TICKS_PER_BIT);
    localparam BIT_CNT_WIDTH  = $clog2(DATA_BITS);

    localparam [1:0] STATE_IDLE  = 2'd0,
                     STATE_START = 2'd1,
                     STATE_DATA  = 2'd2,
                     STATE_STOP  = 2'd3;

    reg                [1:0] state_reg, state_next;
    reg [TICK_CNT_WIDTH-1:0] tick_cnt_reg, tick_cnt_next;
    reg  [BIT_CNT_WIDTH-1:0] bit_cnt_reg, bit_cnt_next;
    reg      [DATA_BITS-1:0] data_buf_reg, data_buf_next;

    assign o_data = data_buf_reg;

    always @* begin
        state_next    = state_reg;
        tick_cnt_next = tick_cnt_reg;
        bit_cnt_next  = bit_cnt_reg;
        data_buf_next = data_buf_reg;
        o_rx_done     = 1'b0;

        case (state_reg)
            STATE_IDLE: begin
                if (!i_rx) begin
                    state_next = STATE_START;
                end
            end

            STATE_START: begin
                if (i_tick_en) begin
                    if (tick_cnt_reg == (TICKS_PER_BIT / 2 - 1)) begin
                        state_next    = STATE_DATA;
                        tick_cnt_next = 0;
                        bit_cnt_next  = 0;
                    end else begin
                        tick_cnt_next = (tick_cnt_reg + 1);
                    end
                end
            end

            STATE_DATA: begin
                if (i_tick_en) begin
                    tick_cnt_next = (tick_cnt_reg + 1);

                    if (tick_cnt_reg == (TICKS_PER_BIT - 1)) begin
                        tick_cnt_next = 0;
                        data_buf_next = {i_rx, data_buf_reg[DATA_BITS-1:1]};

                        if (bit_cnt_reg == (DATA_BITS - 1)) begin
                            state_next = STATE_STOP;
                        end else begin
                            bit_cnt_next = (bit_cnt_reg + 1);
                        end
                    end
                end
            end

            STATE_STOP: begin
                if (i_tick_en) begin
                    if (tick_cnt_reg == (TICKS_PER_BIT - 1)) begin
                        state_next = STATE_IDLE;
                        o_rx_done  = 1'b1;
                    end else begin
                        tick_cnt_next = (tick_cnt_reg + 1);
                    end
                end
            end
        endcase
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            state_reg    <= STATE_IDLE;
            tick_cnt_reg <= 0;
            bit_cnt_reg  <= 0;
            data_buf_reg <= 0;
        end else begin
            state_reg    <= state_next;
            tick_cnt_reg <= tick_cnt_next;
            bit_cnt_reg  <= bit_cnt_next;
            data_buf_reg <= data_buf_next;
        end
    end

endmodule
