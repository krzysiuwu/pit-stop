/**
 * Module: vga_timing
 * Summary: Generates pixel coordinates, synchronization pulses, and blanking flags for 1024-by-768 VGA output.
 * Author: Adam Krupa
 * Based on: AGH UEC2 VGA timing controller by Piotr Kaczmarczyk.
 */
module vga_timing (
        input  logic clk,
        input  logic rst,

        vga_if.out vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    logic [10:0] vcount_nxt, hcount_nxt;
    logic vsync_nxt, vblnk_nxt, hsync_nxt, hblnk_nxt;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= 11'b0;
            vga_out.vsync <= 1'b0;
            vga_out.vblnk <= 1'b0;
            vga_out.hcount <= 11'b0;
            vga_out.hsync <= 1'b0;
            vga_out.hblnk <= 1'b0;
        end else begin
            vga_out.vcount <= vcount_nxt;
            vga_out.vsync <= vsync_nxt;
            vga_out.vblnk <= vblnk_nxt;
            vga_out.hcount <= hcount_nxt;
            vga_out.hsync <= hsync_nxt;
            vga_out.hblnk <= hblnk_nxt;
        end
    end

    always_comb begin
   
        if (vga_out.hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 11'b0;
            if (vga_out.vcount == VER_TOTAL_TIME - 1) begin
                vcount_nxt = 11'b0;
            end else begin
                vcount_nxt = vga_out.vcount + 1;
            end
        end else begin
            hcount_nxt = vga_out.hcount + 1;
            vcount_nxt = vga_out.vcount;
        end

        hblnk_nxt = (hcount_nxt >= HOR_BLANK_START);
        hsync_nxt = (hcount_nxt >= HOR_SYNC_START && hcount_nxt < HOR_SYNC_START + HOR_SYNC_TIME);
        
        vblnk_nxt = (vcount_nxt >= VER_BLANK_START);
        vsync_nxt = (vcount_nxt >= VER_SYNC_START && vcount_nxt < VER_SYNC_START + VER_SYNC_TIME);
    end

endmodule
