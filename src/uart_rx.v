`timescale 1ns / 1ps

// ============================================================================
// UART Receiver
// ============================================================================
// Receives serial UART frames using an oversampling tick input.
// Detects start bit, samples DATA_BITS payload bits, validates stop-bit period,
// and pulses o_rx_done when one byte is available on o_data.

module uart_rx #(
    parameter DATA_BITS     = 8,    // Number of bits in one UART data frame
    parameter TICKS_PER_BIT = 16    // Oversampling ticks per UART bit time
)(
    // Input interface
    input wire                  i_clk,      // Clock
    input wire                  i_rst,      // Reset
    input wire                  i_rx,       // Serial RX line
    input wire                  i_tick_en,  // Oversampling tick enable

    // Output interface
    output reg                  o_rx_done,  // One-cycle pulse when a frame is received
    output wire [DATA_BITS-1:0] o_data      // Received data byte (LSB-first shifted in)
);

    // Counter widths derived from protocol parameters.
    localparam TICK_CNT_WIDTH = $clog2(TICKS_PER_BIT);
    localparam BIT_CNT_WIDTH  = $clog2(DATA_BITS);

    // Receiver FSM states.
    localparam [1:0] STATE_IDLE  = 2'd0,
                     STATE_START = 2'd1,
                     STATE_DATA  = 2'd2,
                     STATE_STOP  = 2'd3;

    // FSM state, counters, and data shift buffer registers.
    reg                [1:0] r_state, n_state;
    reg [TICK_CNT_WIDTH-1:0] r_tick_cnt, n_tick_cnt;
    reg  [BIT_CNT_WIDTH-1:0] r_bit_cnt, n_bit_cnt;
    reg      [DATA_BITS-1:0] r_data_buf, n_data_buf;

    assign o_data = r_data_buf;

    // Combinational next-state and datapath logic.
    always @* begin
        n_state    = r_state;
        n_tick_cnt = r_tick_cnt;
        n_bit_cnt  = r_bit_cnt;
        n_data_buf = r_data_buf;
        o_rx_done  = 1'b0;

        case (r_state)
            STATE_IDLE: begin
                // Start-bit edge detected.
                if (!i_rx) begin
                    n_state = STATE_START;
                end
            end

            STATE_START: begin
                if (i_tick_en) begin
                    // Wait half bit to sample in the center of start bit.
                    if (r_tick_cnt == (TICKS_PER_BIT / 2 - 1)) begin
                        n_state    = STATE_DATA;
                        n_tick_cnt = 0;
                        n_bit_cnt  = 0;
                    end else begin
                        n_tick_cnt = (r_tick_cnt + 1);
                    end
                end
            end

            STATE_DATA: begin
                if (i_tick_en) begin
                    n_tick_cnt = (r_tick_cnt + 1);

                    // Sample each data bit once per full bit period.
                    if (r_tick_cnt == (TICKS_PER_BIT - 1)) begin
                        n_tick_cnt = 0;
                        n_data_buf = {i_rx, r_data_buf[DATA_BITS-1:1]};

                        if (r_bit_cnt == (DATA_BITS - 1)) begin
                            n_state = STATE_STOP;
                        end else begin
                            n_bit_cnt = (r_bit_cnt + 1);
                        end
                    end
                end
            end

            STATE_STOP: begin
                if (i_tick_en) begin
                    // Consume one stop-bit period, then commit received byte.
                    if (r_tick_cnt == (TICKS_PER_BIT - 1)) begin
                        n_state   = STATE_IDLE;
                        o_rx_done = 1'b1;
                    end else begin
                        n_tick_cnt = (r_tick_cnt + 1);
                    end
                end
            end
        endcase
    end

    // Sequential register update.
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_state    <= STATE_IDLE;
            r_tick_cnt <= 0;
            r_bit_cnt  <= 0;
            r_data_buf <= 0;
        end else begin
            r_state    <= n_state;
            r_tick_cnt <= n_tick_cnt;
            r_bit_cnt  <= n_bit_cnt;
            r_data_buf <= n_data_buf;
        end
    end

endmodule
