`ifndef SYMBOLS_VH
`define SYMBOLS_VH

// ============================================================================
// Symbol Definitions for Calculator Core
// ============================================================================
// This header file defines all symbol constants used throughout the calculator
// core to represent digits, operators, and control signals internally.
// All symbols are represented as 5-bit values.

// Symbol width in bits
`define SYM_WIDTH 5

// Invalid symbol value (default for unmapped inputs)
`define SYM_INVALID 5'h00

// Digit symbols (0-9)
`define SYM_0 5'h10
`define SYM_1 5'h11
`define SYM_2 5'h12
`define SYM_3 5'h13
`define SYM_4 5'h14
`define SYM_5 5'h15
`define SYM_6 5'h16
`define SYM_7 5'h17
`define SYM_8 5'h18
`define SYM_9 5'h19

// Plus sign / add operation
`define SYM_PLUS 5'h1B

// Comma / decimal point
`define SYM_COMMA 5'h1C

// Minus sign / subtract operation
`define SYM_MINUS 5'h1D

// Multiplication operation
`define SYM_MUL 5'h1A

// Division operation
`define SYM_DIV 5'h1F

// Stack element separator (space character)
`define SYM_SEPARATOR 5'h02

// Result indicator (carriage return)
`define SYM_RESULT 5'h0D

// Line feed control
`define SYM_NEW_LINE 5'h0A

// Reset/clear operation
`define SYM_RESET 5'h07

`endif
