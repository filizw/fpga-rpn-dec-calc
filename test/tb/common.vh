`define TEST_START(MOD_NAME_STR, VCD_PATH_STR, TB_SCOPE) \
    $dumpfile(VCD_PATH_STR); \
    $dumpvars(0, TB_SCOPE); \
    $display("[ RUN    ] %s test", MOD_NAME_STR);

`define TEST_END(MOD_NAME_STR) \
    $display("[ PASSED ] %s test", MOD_NAME_STR); \
    $finish;

`define ASSERT_EQ_BIN(IDX, SIGNAL_STR, GOT, EXPECTED) \
    if (GOT !== EXPECTED) begin \
        $error("[ ERROR  ] Assert[%0d] for %s failed: expected %b, got %b", IDX, SIGNAL_STR, EXPECTED, GOT); \
        $finish; \
    end

`define ASSERT_EQ_DEC(IDX, SIGNAL_STR, GOT, EXPECTED) \
    if (GOT !== EXPECTED) begin \
        $error("[ ERROR  ] Assert[%0d] for %s failed: expected %0d, got %0d", IDX, SIGNAL_STR, EXPECTED, GOT); \
        $finish; \
    end

`define ASSERT_EQ_HEX(IDX, SIGNAL_STR, GOT, EXPECTED) \
    if (GOT !== EXPECTED) begin \
        $error("[ ERROR  ] Assert[%0d] for %s failed: expected 0x%h, got 0x%h", IDX, SIGNAL_STR, EXPECTED, GOT); \
        $finish; \
    end

`define ASSERT_EQ(ID, SIGNAL_STR, GOT, EXPECTED) \
    if (GOT !== EXPECTED) begin \
        $error("[ ERROR  ] Assert[%0d] for %s failed: expected 0x%h, got 0x%h", ID, SIGNAL_STR, EXPECTED, GOT); \
        $finish; \
    end
