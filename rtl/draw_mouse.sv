/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

 module draw_mouse (

        input  logic clk,
        input  logic rst,
        input logic [11:0] x_pos,
        input logic [11:0] y_pos,

        vga_if.in vga_in, 

        vga_if.out vga_out

        
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    logic [11:0] rgb_nxt;

   


    /**
     * Internal logic
     */

    always_ff @(posedge clk or negedge rst) begin : bg_ff_blk
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.hblnk  <= '0;
            vga_out.rgb    <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.vblnk <= vga_in.vblnk;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.hblnk  <= vga_in.hblnk;
        end
    end

    assign vga_out.rgb = rgb_nxt;

    MouseDisplay uMouseDisplay(
        
        .xpos(x_pos),
        .ypos(y_pos),
        .hcount(vga_in.hcount),
        .vcount(vga_in.vcount),
        .blank(vga_in.hblnk | vga_in.vblnk),
        .rgb_in(vga_in.rgb),
        .rgb_out(rgb_nxt),
        .pixel_clk(clk)

    );

endmodule
