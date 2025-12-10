SRC_DIR  = src
TEST_DIR = test
TB_DIR 	 = $(TEST_DIR)/tb
OUT_DIR  = out
VCD_DIR  = $(OUT_DIR)/vcd

SRCS := $(wildcard $(SRC_DIR)/*.v)
TBS  := $(wildcard $(TB_DIR)/*_tb.v)

IVERILOG  := iverilog
VVP       := vvp

all: $(patsubst $(TB_DIR)/%.v,$(VCD_DIR)/%.vcd,$(TBS))

$(VCD_DIR)/%.vcd: $(TB_DIR)/%.v $(SRCS)
	mkdir -p $(VCD_DIR)
	$(IVERILOG) -I $(SRC_DIR) -o $@ $(SRCS) $<
	$(VVP) $@

clean:
	rm -rf $(OUT_DIR)
