/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */

module vga_timing (
        input  logic clk,
        input  logic rst,

        vga_if.out vga_out,
        low_res_if.out low_res_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    logic [10:0] vcount_nxt, hcount_nxt;
    logic vsync_nxt, vblnk_nxt, hsync_nxt, hblnk_nxt;

    always_ff @(posedge clk or negedge rst) begin
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
        vcount_nxt = vga_out.vcount;
        vsync_nxt = vga_out.vsync;
        vblnk_nxt = vga_out.vblnk;
        hcount_nxt = vga_out.hcount;
        hsync_nxt = vga_out.hsync;
        hblnk_nxt = vga_out.hblnk;

        if(vga_out.hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 11'b0;

            if(vga_out.vcount != 807) begin
                vcount_nxt++;
            end
            //vcount_nxt++;
            hblnk_nxt = 1'b0;

            if (vga_out.vcount >= VER_BLANK_START - 1) begin
                vblnk_nxt = 1'b1;
            end

            if (vga_out.vcount >= (VER_SYNC_START - 1 )&& vga_out.vcount <= (VER_SYNC_START + VER_SYNC_TIME - 2)) begin
                vsync_nxt = 1'b1;
            end else begin
                vsync_nxt = 1'b0;
            end
        end else begin
            hcount_nxt++;
            if (vga_out.hcount >= HOR_BLANK_START - 1) begin
                hblnk_nxt = 1'b1;
            end
            if (vga_out.hcount >= (HOR_SYNC_START -1 ) && vga_out.hcount <= (HOR_SYNC_START + HOR_SYNC_TIME - 2)) begin
                hsync_nxt = 1'b1;
            end else begin
                hsync_nxt = 1'b0;
            end
        end

        if (vga_out.vcount == VER_TOTAL_TIME -1 && vga_out.hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 11'b0;
            vcount_nxt = 11'b0;
            vsync_nxt = 1'b0;
            vblnk_nxt = 1'b0;
            hsync_nxt = 1'b0;
            hblnk_nxt = 1'b0;
        end
    end

    assign low_res_out.hcount = vga_out.hcount >> 2;
    assign low_res_out.vcount = vga_out.vcount >> 2;

endmodule
