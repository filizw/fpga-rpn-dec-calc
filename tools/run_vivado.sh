SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../out/vivado"
REPORT_DIR="$OUTPUT_DIR/report"
BIT_DIR="$SCRIPT_DIR/../out/bit"

BUILD_SCRIPT="$SCRIPT_DIR/build.tcl"
PROG_SCRIPT="$SCRIPT_DIR/prog.tcl"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"
mkdir -p "$BIT_DIR"

cd "$OUTPUT_DIR"

BUILD=0
PROG=0

if [ $# -eq 0 ]; then
    echo "Usage: $0 [-b] [-p] [-bp]"
    exit 1
fi

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

if [ $BUILD -eq 1 ]; then
    vivado -mode batch -source "$BUILD_SCRIPT"
fi

if [ $PROG -eq 1 ]; then
    vivado -mode batch -source "$PROG_SCRIPT"
fi
