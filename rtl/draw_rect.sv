/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_rect #(

    parameter logic [10:0] rect_height,
    parameter logic [10:0] rect_width,
    parameter logic [11:0] rect_rgb
)(
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
            vga_out.rgb   <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        
        if(vga_in.hcount >= x_pos && vga_in.hcount < (x_pos + rect_width) && vga_in.vcount >= y_pos && vga_in.vcount < (y_pos + rect_height)) begin

            rgb_nxt = rect_rgb;
        end else begin

            rgb_nxt = vga_in.rgb;
        end

    end

endmodule
