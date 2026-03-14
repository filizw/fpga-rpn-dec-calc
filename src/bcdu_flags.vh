`ifndef BCDU_FLAGS_VH
`define BCDU_FLAGS_VH

// ============================================================================
// BCDU Status Flags
// ============================================================================
// Defines status flags for the BCD Unit (BCDU).

// Total number of status flags
`define BCDU_NUM_FLAGS 5

// Zero flag: set when result is zero
`define BCDU_ZF 0

// Truncated flag: set when non-zero digit is shifted out by shift operations
`define BCDU_TF 1

// Carry flag: set when operation generates carry
`define BCDU_CF 2

// Greater flag: set when A > B in comparison operations
`define BCDU_GF 3

// Equal flag: set when A == B in comparison operations
`define BCDU_EF 4

`endif
