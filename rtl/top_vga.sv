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
        input logic clk_100MHz,
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

    // VGA signals from timing
     vga_if vga_timing();
    // VGA signals from background
     vga_if vga_bg();
    //VGA signals from rectangle
    vga_if vga_rect();

    vga_if vga_mouse();

    /**
     * Signals assignments
     */


    assign vs = vga_mouse.vsync;
    assign hs = vga_mouse.hsync;
    assign {r,g,b} = vga_mouse.rgb;


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

        .vga_out (vga_bg)
    );

    wire [11:0] x_pos;
    wire [11:0] y_pos;

    
    logic [11:0] xpos_sync1, xpos_sync2;
    logic [11:0] ypos_sync1, ypos_sync2;

    always_ff @(posedge clk) begin
        if (!rst) begin
            xpos_sync1 <= 12'd0;
            xpos_sync2 <= 12'd0;
            ypos_sync1 <= 12'd0;
            ypos_sync2 <= 12'd0;
        end else begin
            
            xpos_sync1 <= x_pos;
            xpos_sync2 <= xpos_sync1;

            ypos_sync1 <= y_pos;
            ypos_sync2 <= ypos_sync1;
        end
    end

    draw_rect #(.rect_height(50), .rect_width(70), .rect_rgb(12'h4_f_2)) u_draw_rect (

        .clk,
        .rst,
        .x_pos(xpos_sync2),
        .y_pos(ypos_sync2),

        .vga_in (vga_bg),
        .vga_out (vga_rect)
    );

    MouseCtl uMouseCtl(
        .clk(clk_100MHz),
        .rst(!rst),
        .ps2_clk,
        .ps2_data,
        .xpos(x_pos),
        .ypos(y_pos)
    );

    draw_mouse u_draw_mouse(

        .clk,
        .rst,
        .x_pos,
        .y_pos,
        .vga_in(vga_rect),
        .vga_out(vga_mouse)
    );

endmodule
