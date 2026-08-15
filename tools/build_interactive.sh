#!/bin/bash
set -e

# Budowanie interaktywnego symulatora SDL z tym samym rdzeniem co FPGA.
SDL_CFLAGS="$(sdl2-config --cflags 2>/dev/null || true)"
SDL_LIBS="$(sdl2-config --libs 2>/dev/null || echo -lSDL2)"

verilator -Wno-fatal --cc --exe --build -j 0 -O3 \
    -CFLAGS "-O3 ${SDL_CFLAGS}" \
    -LDFLAGS "${SDL_LIBS}" \
    --top-module top_interactive \
    rtl/Graphics/VGA/Target_res/vga_pkg.sv \
    rtl/Graphics/VGA/Low_res/low_res_pkg.sv \
    rtl/Graphics/VGA/Target_res/vga_if.sv \
    rtl/Graphics/VGA/Low_res/low_res_if.sv \
    rtl/Graphics/VGA/Target_res/vga_timing.sv \
    rtl/Graphics/VGA/LUT2RGB_converter.sv \
    rtl/Graphics/Rom_modules/BasicButton8chars_Rom.sv \
    rtl/Graphics/Rom_modules/Font_Rom.sv \
    rtl/Graphics/Rom_modules/BolidF1Default_Rom.sv \
    rtl/Graphics/Rom_modules/BolidF1NoWheels_Rom.sv \
    rtl/Graphics/Rom_modules/Cloud_Rom.sv \
    rtl/Graphics/Rom_modules/Grandstand_Rom.sv \
    rtl/Graphics/Rom_modules/Wheel_Rom.sv \
    rtl/Graphics/Rom_modules/WheelRack_Rom.sv \
    rtl/Graphics/Draw_modules/draw_bg.sv \
    rtl/Graphics/Draw_modules/draw_BolidF1Default.sv \
    rtl/Graphics/Draw_modules/draw_BolidF1NoWheels.sv \
    rtl/Graphics/Draw_modules/draw_Wheel.sv \
    rtl/Graphics/Draw_modules/draw_WheelRack.sv \
    rtl/Graphics/Draw_modules/draw_button_with_text.sv \
    rtl/Graphics/Draw_modules/draw_mouse_cursor.sv \
    rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv \
    rtl/Game_logic/Sprite_control/mouse_hitbox.sv \
    rtl/Game_logic/Sprite_control/wheel_physics.sv \
    rtl/Game_logic/Sprite_control/wheel_service_fsm.sv \
    rtl/Game_logic/system_fsm.sv \
    rtl/pit_stop_core.sv \
    rtl/top_interactive.sv \
    main.cpp

echo "Gotowe: obj_dir/Vtop_interactive.exe (Windows/MSYS) lub obj_dir/Vtop_interactive (Linux)."
