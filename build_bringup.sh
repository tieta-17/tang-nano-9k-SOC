#!/bin/bash
# Build and program one isolated Tang Nano 9K bring-up design.
# Usage: ./build_bringup.sh led|tx|echo [--flash]

set -e

case "$1" in
    led)
        TOP_MODULE="led_reset_test"
        TEST_SOURCE="bringup/01_led_reset_test.v"
        EXTRA_SOURCES=()
        ;;
    tx)
        TOP_MODULE="uart_tx_test"
        TEST_SOURCE="bringup/02_uart_tx_test.v"
        EXTRA_SOURCES=(uart/src/uart_tx.v)
        ;;
    echo)
        TOP_MODULE="uart_echo_test"
        TEST_SOURCE="bringup/03_uart_echo_test.v"
        EXTRA_SOURCES=(uart/src/uart_tx.v uart/src/uart_rx.v)
        ;;
    *)
        echo "Usage: $0 led|tx|echo [--flash]"
        exit 1
        ;;
esac

DEVICE="GW1NR-LV9QN88PC6/I5"
FAMILY="GW1N-9C"
BOARD="tangnano9k"
CST="tangnano9k.cst"
BUILD_DIR="build/bringup-${1}"

mkdir -p "$BUILD_DIR"

READ_CMDS=""
for source in "${EXTRA_SOURCES[@]}" "$TEST_SOURCE"; do
    READ_CMDS+="read_verilog ${source}; "
done

echo "==> Synthesis: ${TOP_MODULE}"
yowasp-yosys -p "${READ_CMDS} synth_gowin -top ${TOP_MODULE} -json ${BUILD_DIR}/${TOP_MODULE}.json"

echo "==> Place and route"
yowasp-nextpnr-himbaechel-gowin \
    --json "${BUILD_DIR}/${TOP_MODULE}.json" \
    --write "${BUILD_DIR}/${TOP_MODULE}_pnr.json" \
    --device "$DEVICE" \
    --vopt family="$FAMILY" \
    --vopt cst="$CST"

echo "==> Pack bitstream"
gowin_pack -d "$FAMILY" -o "${BUILD_DIR}/${TOP_MODULE}.fs" \
    "${BUILD_DIR}/${TOP_MODULE}_pnr.json"

echo "==> Program board"
if [ "$2" = "--flash" ]; then
    openFPGALoader -b "$BOARD" -f "${BUILD_DIR}/${TOP_MODULE}.fs"
else
    openFPGALoader -b "$BOARD" "${BUILD_DIR}/${TOP_MODULE}.fs"
fi

echo "==> Loaded ${TOP_MODULE}"
