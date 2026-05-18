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
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    logic [10:0] vcount_nxt, hcount_nxt;
    logic vsync_nxt, vblnk_nxt, hsync_nxt, hblnk_nxt;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vcount <= 'b0;
            vsync <= 'b0;
            vblnk <= 'b0;
            hcount <= 'b0;
            hsync <= 'b0;
            hblnk <= 'b0;
        end else begin
            vcount <= vcount_nxt;
            vsync <= vsync_nxt;
            vblnk <= vblnk_nxt;
            hcount <= hcount_nxt;
            hsync <= hsync_nxt;
            hblnk <= hblnk_nxt;
        end
    end

    always_comb begin
        vcount_nxt = vcount;
        vsync_nxt = vsync;
        vblnk_nxt = vblnk;
        hcount_nxt = hcount;
        hsync_nxt = hsync;
        hblnk_nxt = hblnk;

        if(hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 'b0;

            if(vcount != 807) begin
                vcount_nxt++;
            end
            //vcount_nxt++;
            hblnk_nxt = 'b0;

            if (vcount >= VER_BLANK_START - 1) begin
                vblnk_nxt = 'b1;
            end

            if (vcount >= (VER_SYNC_START - 1 )&& vcount <= (VER_SYNC_START + VER_SYNC_TIME - 2)) begin
                vsync_nxt = 'b1;
            end else begin
                vsync_nxt = 'b0;
            end
        end else begin
            hcount_nxt++;
            if (hcount >= HOR_BLANK_START - 1) begin
                hblnk_nxt = 'b1;
            end
            if (hcount >= (HOR_SYNC_START -1 ) && hcount <= (HOR_SYNC_START + HOR_SYNC_TIME - 2)) begin
                hsync_nxt = 'b1;
            end else begin
                hsync_nxt = 'b0;
            end
        end

        if (vcount == VER_TOTAL_TIME -1 && hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 'b0;
            vcount_nxt = 'b0;
            vsync_nxt = 'b0;
            vblnk_nxt = 'b0;
            hsync_nxt = 'b0;
            hblnk_nxt = 'b0;
        end
    end

endmodule
