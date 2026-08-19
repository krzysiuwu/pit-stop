#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/verilator_msys2_compat.sh"

# Budowanie interaktywnego symulatora SDL z tym samym rdzeniem co FPGA.
SDL_CFLAGS="$(sdl2-config --cflags 2>/dev/null || true)"
SDL_LIBS="$(sdl2-config --libs 2>/dev/null || echo -lSDL2)"
BUILD_DIR="obj_dir/interactive_sdl"
USER_CFLAGS="-O3 ${SDL_CFLAGS}"

if ABI_FLAG="$(verilator_msys2_cxx_abi_flag)"; then
    BUILD_DIR="obj_dir/interactive_sdl_msys2_abi0"
    USER_CFLAGS="${USER_CFLAGS} ${ABI_FLAG}"
    echo "MSYS2 + GCC 16: uzywam zgodnego ABI C++ (${ABI_FLAG})."
fi

verilator -Wno-fatal --cc --exe --build -j 0 -O3 \
    --Mdir "${BUILD_DIR}" \
    -CFLAGS "${USER_CFLAGS}" \
    -LDFLAGS "${SDL_LIBS}" \
    --top-module top_interactive \
    rtl/Game_logic/game_pkg.sv \
    rtl/Graphics/VGA/Target_res/vga_pkg.sv \
    rtl/Graphics/VGA/Target_res/vga_if.sv \
    rtl/Graphics/VGA/Target_res/vga_timing.sv \
    rtl/Graphics/VGA/LUT2RGB_converter.sv \
    rtl/Graphics/Rom_modules/BasicButton8chars_Rom.sv \
    rtl/Graphics/Rom_modules/Font_Rom.sv \
    rtl/Graphics/Rom_modules/BolidF1Default_Rom.sv \
    rtl/Graphics/Rom_modules/BolidF1NoWheels_Rom.sv \
    rtl/Graphics/Rom_modules/Cloud_Rom.sv \
    rtl/Graphics/Rom_modules/Grandstand_Rom.sv \
    rtl/Graphics/Rom_modules/PitstopLogo_Rom.sv \
    rtl/Graphics/Rom_modules/Wheel_Rom.sv \
    rtl/Graphics/Rom_modules/WheelRack_Rom.sv \
    rtl/Graphics/Draw_modules/draw_bg.sv \
    rtl/Graphics/Draw_modules/draw_PitstopLogo.sv \
    rtl/Graphics/Draw_modules/draw_BolidF1Default.sv \
    rtl/Graphics/Draw_modules/draw_BolidF1NoWheels.sv \
    rtl/Graphics/Draw_modules/draw_Wheel.sv \
    rtl/Graphics/Draw_modules/draw_WheelRack.sv \
    rtl/Hardware/bin_to_bcd3.sv \
    rtl/Graphics/Draw_modules/draw_game_panel.sv \
    rtl/Graphics/Draw_modules/draw_buttons.sv \
    rtl/Graphics/Draw_modules/draw_mouse_cursor.sv \
    rtl/Game_logic/game_options.sv \
    rtl/Game_logic/singleplayer_game_controller.sv \
    rtl/Game_logic/multiplayer_result.sv \
    rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv \
    rtl/Game_logic/Sprite_control/mouse_hitbox.sv \
    rtl/Game_logic/Sprite_control/mouse_hover.sv \
    rtl/Game_logic/Sprite_control/wheel_physics.sv \
    rtl/Game_logic/Sprite_control/wheel_service_fsm.sv \
    rtl/Game_logic/system_fsm.sv \
    rtl/Uart/uart_tx.sv \
    rtl/Uart/uart_rx.sv \
    rtl/Uart/uart_game_link.sv \
    rtl/pit_stop_core.sv \
    rtl/top_interactive.sv \
    main.cpp

echo "Gotowe: ${BUILD_DIR}/Vtop_interactive.exe (Windows/MSYS) lub ${BUILD_DIR}/Vtop_interactive (Linux)."
