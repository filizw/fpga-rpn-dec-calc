`timescale 1ns / 1ps

module bcd_adder #(
    parameter NUM_DIGITS = 4
)(
    input wire  [NUM_DIGITS*4-1:0] i_num_a,
    input wire  [NUM_DIGITS*4-1:0] i_num_b,
    input wire                     i_carry,
    output wire [NUM_DIGITS*4-1:0] o_num,
    output wire                    o_carry
);

    wire [4:0] S [NUM_DIGITS-1:0];

    wire [NUM_DIGITS-1:0] G;
    wire [NUM_DIGITS-1:0] P;
    wire   [NUM_DIGITS:0] C;

    assign C[0]    = i_carry;
    assign o_carry = C[NUM_DIGITS];

    genvar n, m;

    generate
        for (n = 0; n < NUM_DIGITS; n = n + 1) begin
            assign S[n] = (i_num_a[4*n+:4] + i_num_b[4*n+:4]);
            assign G[n] = (S[n] > 5'd9);
            assign P[n] = (S[n] == 5'd9);
        end
    endgenerate

    generate
        for (n = 0; n < NUM_DIGITS; n = n + 1) begin
            reg [n:0] and_terms;

            for (m = 0; m <= n; m = m + 1) begin
                always @* begin
                    if (m == n) and_terms[m] = (&P[n:0] & C[0]);
                    else        and_terms[m] = (&P[n:n-m] & G[n-m-1]);
                end
            end

            assign C[n+1] = (|and_terms | G[n]);
        end
    endgenerate

    generate
        for (n = 0; n < NUM_DIGITS; n = n + 1) begin
            wire       correct = (G[n] | P[n] & C[n]);
            wire [4:0] result  = (S[n] + {2'b0, {2{correct}}, C[n]});

            assign o_num[4*n+:4] = result[3:0];
        end
    endgenerate

endmodule
