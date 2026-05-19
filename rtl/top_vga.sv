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
    assign {r,g,b} = vga_mouse.rgb;

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
        .vcount (vga_timing.vcount),
        .vsync  (vga_timing.vsync),
        .vblnk  (vga_timing.vblnk),
        .hcount (vga_timing.hcount),
        .hsync  (vga_timing.hsync),
        .hblnk  (vga_timing.hblnk)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst,
        .vga_in (vga_timing),
        .vga_out (vga_bg),
        .low_res_in(low_res_pipe)
    );

    upscale_4x u_upscale_4x (
        .clk,
        .rst,
        .vga_in (vga_bg),
        .vga_out (vga_upscale),
        .rgb_in(vga_bg.rgb),
        .low_res_out(low_res_pipe)
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
        .rgb_in(vga_upscale.rgb),
        .rgb_out(vga_mouse.rgb),
        .pixel_clk(clk)
    );

endmodule