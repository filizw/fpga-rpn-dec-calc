# Resolve script-relative paths to keep execution independent of current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../out/vivado"
REPORT_DIR="$OUTPUT_DIR/report"
BIT_DIR="$SCRIPT_DIR/../out/bit"

# TCL entry points for Vivado batch flow
BUILD_SCRIPT="$SCRIPT_DIR/build.tcl"
PROG_SCRIPT="$SCRIPT_DIR/prog.tcl"

# Ensure expected output directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"
mkdir -p "$BIT_DIR"

# Run Vivado from output directory so generated files are contained there
cd "$OUTPUT_DIR"

# Operation flags set by command-line mode
BUILD=0
PROG=0

# Require at least one mode flag
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-b] [-p] [-bp]"
    exit 1
fi

# Parse mode:
#   -b     build bitstream
#   -p     program device
#   -bp/-pb build and then program
case "$1" in
    -b) BUILD=1 ;;
    -p) PROG=1 ;;
    -bp|-pb) 
        BUILD=1
        PROG=1
        ;;
    *)
        echo "Invalid argument: $1"
        exit 1
        ;;
esac

# Launch Vivado build flow when requested
if [ $BUILD -eq 1 ]; then
    vivado -mode batch -source "$BUILD_SCRIPT"
fi

# Launch Vivado programming flow when requested
if [ $PROG -eq 1 ]; then
    vivado -mode batch -source "$PROG_SCRIPT"
fi
