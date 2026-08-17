#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/verilator_msys2_compat.sh"

BUILD_DIR="obj_dir/game_controller_test"
VERILATOR_CFLAGS=()
if ABI_FLAG="$(verilator_msys2_cxx_abi_flag)"; then
    BUILD_DIR="obj_dir/game_controller_test_msys2_abi0"
    VERILATOR_CFLAGS=(-CFLAGS "${ABI_FLAG}")
    echo "MSYS2 + GCC 16: uzywam zgodnego ABI C++ (${ABI_FLAG})."
fi

verilator --binary --timing --assert -Wall -Wno-fatal \
    --top-module singleplayer_game_controller_tb \
    --Mdir "${BUILD_DIR}" \
    "${VERILATOR_CFLAGS[@]}" \
    rtl/Game_logic/singleplayer_game_controller.sv \
    sim/game_controller/singleplayer_game_controller_tb.sv

TEST_BINARY="${BUILD_DIR}/Vsingleplayer_game_controller_tb"
if [[ -x "${TEST_BINARY}.exe" ]]; then
    TEST_BINARY="${TEST_BINARY}.exe"
fi

"${TEST_BINARY}"
