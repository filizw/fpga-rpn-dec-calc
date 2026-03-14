`ifndef BCD_ALU_OP_CODES_VH
`define BCD_ALU_OP_CODES_VH

// ============================================================================
// BCD ALU Operation Codes
// ============================================================================
// Defines operation codes for the BCD Arithmetic Logic Unit.

// Operation code width in bits
`define BCD_ALU_OP_CODE_WIDTH 2

// Shift left (variable-length barrel shift, multiply by 10^N per digit)
`define BCD_ALU_OP_SHL 2'h0

// Shift right (variable-length barrel shift, divide by 10^N per digit)
`define BCD_ALU_OP_SHR 2'h1

// Addition
`define BCD_ALU_OP_ADD 2'h2

// Comparison (greater than / equal)
`define BCD_ALU_OP_CMP 2'h3

`endif
