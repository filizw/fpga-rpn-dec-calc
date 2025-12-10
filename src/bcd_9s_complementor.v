`timescale 1ns / 1ps

module bcd_9s_complementor #(
    parameter NUM_DIGITS = 4
)(
    input wire  [4*NUM_DIGITS-1:0] i_num,
    output wire [4*NUM_DIGITS-1:0] o_num
);

    generate
        genvar n;

        for (n = 0; n < NUM_DIGITS; n = n + 1) begin
            assign o_num[4*n+:4] = (4'd9 - i_num[4*n+:4]);
        end
    endgenerate

endmodule
