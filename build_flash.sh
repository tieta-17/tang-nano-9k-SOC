#!/bin/bash
# build_flash.sh — synthesize, place & route, pack, and flash the SoC
# to the Tang Nano 9K, using the YoWASP toolchain + openFPGALoader.
#
# Usage:
#   ./build_flash.sh            (SRAM, temporary — default, safe for iterating)
#   ./build_flash.sh --flash    (writes to persistent flash instead)
#
# Assumes this script lives at the repo root, alongside cpu/, soc_top/,
# uart/, data_mem.v, and tangnano9k.cst, matching the project layout.

set -e   # stop immediately if any step fails, rather than continuing on a broken build

TOP_MODULE="soc_top"
DEVICE="GW1NR-LV9QN88PC6/I5"
FAMILY="GW1N-9C"
BOARD="tangnano9k"
CST="tangnano9k.cst"

# Every source file needed to build the full SoC.
SRC_FILES=(
    cpu/src/alu.v
    cpu/src/alu_control_unit.v
    cpu/src/control_unit.v
    cpu/src/imm_gen.v
    cpu/src/instr_mem.v
    cpu/src/pc.v
    cpu/src/reg_file.v
    cpu/src/cpu.v
    data_mem.v
    uart/src/uart_tx.v
    uart/src/uart_rx.v
    soc_top/soc_top.v
)

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Build the yosys read_verilog argument list from SRC_FILES
READ_CMDS=""
for f in "${SRC_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: expected source file not found: $f"
        exit 1
    fi
    READ_CMDS+="read_verilog ${f}; "
done

echo "==> [1/4] Synthesis (yosys)"
yowasp-yosys -p "${READ_CMDS} synth_gowin -top ${TOP_MODULE} -json ${BUILD_DIR}/${TOP_MODULE}.json"

echo "==> [2/4] Place & route (nextpnr)"
yowasp-nextpnr-himbaechel-gowin \
    --json "${BUILD_DIR}/${TOP_MODULE}.json" \
    --write "${BUILD_DIR}/${TOP_MODULE}_pnr.json" \
    --device "${DEVICE}" \
    --vopt family="${FAMILY}" \
    --vopt cst="${CST}"

echo "==> [3/4] Pack bitstream (gowin_pack)"
gowin_pack -d "${FAMILY}" -o "${BUILD_DIR}/${TOP_MODULE}.fs" "${BUILD_DIR}/${TOP_MODULE}_pnr.json"

echo "==> [4/4] Flash to board (openFPGALoader)"
if [ "$1" == "--flash" ]; then
    echo "    (writing to persistent FLASH)"
    openFPGALoader -b "${BOARD}" -f "${BUILD_DIR}/${TOP_MODULE}.fs"
else
    echo "    (writing to volatile SRAM — use --flash for persistent)"
    openFPGALoader -b "${BOARD}" "${BUILD_DIR}/${TOP_MODULE}.fs"
fi

echo "==> Done. Programmed ${BUILD_DIR}/${TOP_MODULE}.fs to the Tang Nano 9K."
