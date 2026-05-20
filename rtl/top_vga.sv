/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic rst,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b,

        inout wire ps2_clk,
        inout wire ps2_data
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire [11:0] x_pos;
    wire [11:0] y_pos;
    wire [3:0] lut_pipe;
    wire [11:0] rgb_pipe;
    wire [11:0] rgb_out;

    low_res_if low_res_pipe();

    // VGA signals from timing
    vga_if vga_timing();
    // VGA signals from background
    vga_if vga_bg();
    // VGA signals from upscaler
    vga_if vga_upscale();
    // VGA signals from mouse
    vga_if vga_mouse();

    /**
     * Signals assignments
     */

    assign vs = ~vga_mouse.vsync;
    assign hs = ~vga_mouse.hsync;
    assign {r,g,b} = rgb_out;

    /**
     * Signals synchronization
     */

    always_ff @(posedge clk or negedge rst) begin : bg_ff_blk
        if (!rst) begin
            vga_mouse.vcount <= '0;
            vga_mouse.vsync  <= '0;
            vga_mouse.vblnk  <= '0;
            vga_mouse.hcount <= '0;
            vga_mouse.hsync  <= '0;
            vga_mouse.hblnk  <= '0;
        end else begin
            vga_mouse.vcount <= vga_bg.vcount;
            vga_mouse.vsync  <= vga_bg.vsync;
            vga_mouse.vblnk <= vga_bg.vblnk;
            vga_mouse.hcount <= vga_bg.hcount;
            vga_mouse.hsync  <= vga_bg.hsync;
            vga_mouse.hblnk  <= vga_bg.hblnk;
        end
    end

    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk,
        .rst,
        .vga_out(vga_timing),
        .low_res_out(low_res_pipe)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst,
        .lut_out(lut_pipe),
        .low_res_in(low_res_pipe),
        .vga_in (vga_timing),
        .vga_out (vga_bg)
    );

    LUT2RGB_converter u_LUT2RGB_converter (
        .clk,
        .rst_n(rst),
        .lut_value(lut_pipe),
        .rgb_out(rgb_pipe),
        .vga_in (vga_bg),
        .vga_out (vga_upscale)
    );

    MouseCtl uMouseCtl(
        .clk,
        .rst(!rst),
        .ps2_clk,
        .ps2_data,
        .xpos(x_pos),
        .ypos(y_pos)
    );

    MouseDisplay uMouseDisplay(
        .xpos(x_pos),
        .ypos(y_pos),
        .hcount(vga_upscale.hcount),
        .vcount(vga_upscale.vcount),
        .blank(vga_upscale.hblnk | vga_upscale.vblnk),
        .rgb_in(rgb_pipe),
        .rgb_out(rgb_out),
        .pixel_clk(clk)
    );

endmodule