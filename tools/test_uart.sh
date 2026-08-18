#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/verilator_msys2_compat.sh"

BUILD_DIR="obj_dir/uart_multiplayer_test"
VERILATOR_CFLAGS=()
if ABI_FLAG="$(verilator_msys2_cxx_abi_flag)"; then
    BUILD_DIR="obj_dir/uart_multiplayer_test_msys2_abi0"
    VERILATOR_CFLAGS=(-CFLAGS "${ABI_FLAG}")
    echo "MSYS2 + GCC 16: uzywam zgodnego ABI C++ (${ABI_FLAG})."
fi

verilator --binary --timing --assert -Wall -Wno-fatal \
    --top-module uart_multiplayer_tb \
    --Mdir "${BUILD_DIR}" \
    "${VERILATOR_CFLAGS[@]}" \
    rtl/Game_logic/game_pkg.sv \
    rtl/Game_logic/multiplayer_result.sv \
    rtl/Uart/uart_tx.sv \
    rtl/Uart/uart_rx.sv \
    rtl/Uart/uart_game_link.sv \
    sim/uart/uart_multiplayer_tb.sv

TEST_BINARY="${BUILD_DIR}/Vuart_multiplayer_tb"
if [[ -x "${TEST_BINARY}.exe" ]]; then
    TEST_BINARY="${TEST_BINARY}.exe"
fi

"${TEST_BINARY}"
