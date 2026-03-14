`ifndef BCDU_OP_CODES_VH
`define BCDU_OP_CODES_VH

// ============================================================================
// BCDU Operation Codes
// ============================================================================
// Defines operation codes for the BCD Unit (BCDU).

// Operation code width in bits
`define BCDU_OP_CODE_WIDTH 4

// No operation (idle state)
`define BCDU_OP_NOP 4'h0

// Shift left (variable-length barrel shift, multiply by 10^N per digit)
`define BCDU_OP_SHL 4'h1

// Shift right (variable-length barrel shift, divide by 10^N per digit)
`define BCDU_OP_SHR 4'h2

// Addition
`define BCDU_OP_ADD 4'h3

// Subtraction
`define BCDU_OP_SUB 4'h4

// Comparison (greater than / equal)
`define BCDU_OP_CMP 4'h5

// Clear (set to zero)
`define BCDU_OP_CLR 4'h6

// Move (copy value)
`define BCDU_OP_MOV 4'h7

// Accumulate (add one value multiple times to accumulator)
`define BCDU_OP_ACC 4'h8

`endif
