`timescale 1ns / 1ps

module uart_tx #(
    parameter DATA_BITS     = 8,
    parameter TICKS_PER_BIT = 16
)(
    input wire                 i_clk,
    input wire                 i_rst,
    input wire                 i_tx_start,
    input wire                 i_tick_en,
    input wire [DATA_BITS-1:0] i_data,
    output reg                 o_tx,
    output reg                 o_tx_done
);

    localparam TICK_CNT_WIDTH = $clog2(TICKS_PER_BIT);
    localparam BIT_CNT_WIDTH  = $clog2(DATA_BITS);

    localparam [1:0] STATE_IDLE  = 2'b00,
                     STATE_START = 2'b01,
                     STATE_DATA  = 2'b10,
                     STATE_STOP  = 2'b11;

    reg                [1:0] state_reg, state_next;
    reg [TICK_CNT_WIDTH-1:0] tick_cnt_reg, tick_cnt_next;
    reg  [BIT_CNT_WIDTH-1:0] bit_cnt_reg, bit_cnt_next;
    reg      [DATA_BITS-1:0] data_buf_reg, data_buf_next;

    always @* begin
        state_next    = state_reg;
        tick_cnt_next = tick_cnt_reg;
        bit_cnt_next  = bit_cnt_reg;
        data_buf_next = data_buf_reg;
        o_tx          = 1'b1;
        o_tx_done     = 1'b0;

        case (state_reg)
            STATE_IDLE: begin
                if (i_tx_start) begin
                    state_next    = STATE_START;
                    tick_cnt_next = 0;
                    data_buf_next = i_data;
                end
            end

            STATE_START: begin
                o_tx = 1'b0;

                if (i_tick_en) begin
                    if (tick_cnt_reg == (TICKS_PER_BIT - 1)) begin
                        state_next    = STATE_DATA;
                        tick_cnt_next = 0;
                        bit_cnt_next  = 0;
                    end else begin
                        tick_cnt_next = (tick_cnt_reg + 1);
                    end
                end
            end

            STATE_DATA: begin
                o_tx = data_buf_reg[0];

                if (i_tick_en) begin
                    tick_cnt_next = (tick_cnt_reg + 1);

                    if (tick_cnt_reg == (TICKS_PER_BIT - 1)) begin
                        tick_cnt_next = 0;
                        data_buf_next = (data_buf_reg >> 1);

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
                        o_tx_done  = 1'b1;
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
