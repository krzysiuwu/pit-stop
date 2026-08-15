# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name vga_project

# Top module name                               -- EDIT
set top_module top_vga_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_vga_basys3.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/Graphics/VGA/Target_res/vga_pkg.sv
    ../rtl/Graphics/VGA/Low_res/low_res_pkg.sv
    ../rtl/Graphics/VGA/Target_res/vga_if.sv
    ../rtl/Graphics/VGA/Low_res/low_res_if.sv
    ../rtl/Graphics/VGA/Target_res/vga_timing.sv
    ../rtl/Graphics/VGA/LUT2RGB_converter.sv
    ../rtl/Graphics/Rom_modules/Cloud_Rom.sv
    ../rtl/Graphics/Rom_modules/Grandstand_Rom.sv
    ../rtl/Graphics/Rom_modules/BasicButton8chars_Rom.sv
    ../rtl/Graphics/Rom_modules/Font_Rom.sv
    ../rtl/Graphics/Rom_modules/BolidF1Default_Rom.sv
    ../rtl/Graphics/Rom_modules/BolidF1NoWheels_Rom.sv
    ../rtl/Graphics/Rom_modules/PitstopLogo_Rom.sv
    ../rtl/Graphics/Rom_modules/Wheel_Rom.sv
    ../rtl/Graphics/Rom_modules/WheelRack_Rom.sv
    ../rtl/Graphics/Draw_modules/draw_button_with_text.sv
    ../rtl/Graphics/Draw_modules/draw_bg.sv
    ../rtl/Graphics/Draw_modules/draw_BolidF1Default.sv
    ../rtl/Graphics/Draw_modules/draw_BolidF1NoWheels.sv
    ../rtl/Graphics/Draw_modules/draw_Wheel.sv
    ../rtl/Graphics/Draw_modules/draw_WheelRack.sv
    ../rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv
    ../rtl/Game_logic/Sprite_control/mouse_hitbox.sv
    ../rtl/Game_logic/Sprite_control/wheel_physics.sv
    ../rtl/Game_logic/Sprite_control/wheel_service_fsm.sv
    ../rtl/Game_logic/system_fsm.sv
    ../rtl/Graphics/Draw_modules/draw_mouse_cursor.sv
    ../rtl/mouse_limits.sv
    ../rtl/top_vga.sv
    ../rtl/pit_stop_core.sv
    ../rtl/top_fsm.sv
    ../clock/clk_wiz_0.v
    ../clock/clk_wiz_0_clk_wiz.v
    rtl/top_vga_basys3.sv
}

# Specify Verilog design files location         -- EDIT
# set verilog_files {
#     path/to/file.v
# }

#Specify VHDL design files location            
set vhdl_files {
    ../vhd/MouseCtl.vhd
    ../vhd/MouseDisplay.vhd
    ../vhd/Ps2Interface.vhd
}

# Specify files for a memory initialization     -- EDIT
set mem_files {
    ../rtl/Graphics/Sprites_and_textures/Default_LUT.mem
    ../rtl/Graphics/Sprites_and_textures/Cloud_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/Grandstand_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/BasicButton8chars_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/font_zx.mem
    ../rtl/Graphics/Sprites_and_textures/BolidF1Default_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/BolidF1NoWheels_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/Wheel_sprite.mem
    ../rtl/Graphics/Sprites_and_textures/WheelRack_sprite.mem
}
