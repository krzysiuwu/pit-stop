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
    ../rtl/Graphics/VGA/vga_pkg.sv 
    ../rtl/Graphics/VGA/vga_timing.sv
    ../rtl/Graphics/Draw_modules/draw_bg.sv
    ../rtl/Graphics/VGA/upscale_4x.sv
    ../rtl/top_vga.sv
    ../rtl/Graphics/VGA/vga_if.sv
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
# set mem_files {
#    path/to/file.data
# }
