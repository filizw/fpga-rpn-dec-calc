`timescale 1ns / 1ps

// ============================================================================
// UART Transmitter
// ============================================================================
// Transmits UART frames using an oversampling tick input.
// Sends start bit, DATA_BITS payload bits (LSB first), and stop bit,
// then pulses o_tx_done when transmission is complete.

module uart_tx #(
    parameter DATA_BITS     = 8,    // Number of bits in one UART data frame
    parameter TICKS_PER_BIT = 16    // Oversampling ticks per UART bit time
)(
    // Input interface
    input wire                 i_clk,       // Clock
    input wire                 i_rst,       // Reset
    input wire                 i_tx_start,  // Pulse to start transmission
    input wire                 i_tick_en,   // Oversampling tick enable
    input wire [DATA_BITS-1:0] i_data,      // Data byte to transmit

    // Output interface
    output reg                 o_tx,       // Serial TX line
    output reg                 o_tx_done   // One-cycle pulse when frame is sent
);

    // Counter widths derived from protocol parameters
    localparam TICK_CNT_WIDTH = $clog2(TICKS_PER_BIT);
    localparam BIT_CNT_WIDTH  = $clog2(DATA_BITS);

    // Transmitter FSM states
    localparam [1:0] STATE_IDLE  = 2'b00,
                     STATE_START = 2'b01,
                     STATE_DATA  = 2'b10,
                     STATE_STOP  = 2'b11;

    // FSM state, counters, and transmit shift buffer registers
    reg                [1:0] r_state, n_state;
    reg [TICK_CNT_WIDTH-1:0] r_tick_cnt, n_tick_cnt;
    reg  [BIT_CNT_WIDTH-1:0] r_bit_cnt, n_bit_cnt;
    reg      [DATA_BITS-1:0] r_data_buf, n_data_buf;

    // Combinational next-state and output logic
    always @* begin
        n_state    = r_state;
        n_tick_cnt = r_tick_cnt;
        n_bit_cnt  = r_bit_cnt;
        n_data_buf = r_data_buf;
        o_tx       = 1'b1;
        o_tx_done  = 1'b0;

        case (r_state)
            STATE_IDLE: begin
                // Save payload and begin start-bit phase
                if (i_tx_start) begin
                    n_state    = STATE_START;
                    n_tick_cnt = 0;
                    n_data_buf = i_data;
                end
            end

            STATE_START: begin
                // Drive UART start bit low for one bit time
                o_tx = 1'b0;

                if (i_tick_en) begin
                    if (r_tick_cnt == (TICKS_PER_BIT - 1)) begin
                        n_state    = STATE_DATA;
                        n_tick_cnt = 0;
                        n_bit_cnt  = 0;
                    end else begin
                        n_tick_cnt = (r_tick_cnt + 1);
                    end
                end
            end

            STATE_DATA: begin
                // Transmit current LSB of shift buffer
                o_tx = r_data_buf[0];

                if (i_tick_en) begin
                    n_tick_cnt = (r_tick_cnt + 1);

                    if (r_tick_cnt == (TICKS_PER_BIT - 1)) begin
                        // Advance to next data bit each full bit period
                        n_tick_cnt = 0;
                        n_data_buf = (r_data_buf >> 1);

                        if (r_bit_cnt == (DATA_BITS - 1)) begin
                            n_state = STATE_STOP;
                        end else begin
                            n_bit_cnt = (r_bit_cnt + 1);
                        end
                    end
                end
            end

            STATE_STOP: begin
                // Hold stop bit high for one bit time, then signal completion
                if (i_tick_en) begin
                    if (r_tick_cnt == (TICKS_PER_BIT - 1)) begin
                        n_state   = STATE_IDLE;
                        o_tx_done = 1'b1;
                    end else begin
                        n_tick_cnt = (r_tick_cnt + 1);
                    end
                end
            end
        endcase
    end

    // Sequential register update
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
