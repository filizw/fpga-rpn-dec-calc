# Project directories
SRC_DIR  = src
TEST_DIR = test
TB_DIR 	 = $(TEST_DIR)/tb
OUT_DIR  = out
VCD_DIR  = $(OUT_DIR)/vcd

# Source and testbench file lists
SRCS := $(wildcard $(SRC_DIR)/*.v)
TBS  := $(wildcard $(TB_DIR)/*_tb.v)

# Simulation tools
IVERILOG  := iverilog
VVP       := vvp

# Build all testbenches and generate their VCD outputs
all: $(patsubst $(TB_DIR)/%.v,$(VCD_DIR)/%.vcd,$(TBS))

# Compile and run one testbench, writing waveform output to out/vcd
$(VCD_DIR)/%.vcd: $(TB_DIR)/%.v $(SRCS)
	mkdir -p $(VCD_DIR)
	$(IVERILOG) -I $(SRC_DIR) -o $@ $(SRCS) $<
	$(VVP) $@

# Remove generated simulation outputs
clean:
	rm -rf $(OUT_DIR)
