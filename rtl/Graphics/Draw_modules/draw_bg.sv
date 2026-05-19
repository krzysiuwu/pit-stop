/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_bg (
        input  logic clk,
        input  logic rst,

        low_res_if.in low_res_in,

        vga_if.in vga_in,
        vga_if.out vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;
    import low_res_pkg::*;

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
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.hblnk  <= vga_in.hblnk;
            vga_out.rgb    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        begin
            if (low_res_in.vcount == 0)                            // - top edge:
                rgb_nxt = 12'hf_f_0;                               // - - make a yellow line.
            else if (low_res_in.vcount == LOW_RES_VER_PIXELS - 1)  // - bottom edge:
                rgb_nxt = 12'hf_0_0;                               // - - make a red line.
            else if (low_res_in.hcount == 0)                       // - left edge:
                rgb_nxt = 12'h0_f_0;                               // - - make a green line.
            else if (low_res_in.hcount == LOW_RES_HOR_PIXELS - 1)  // - right edge:
                rgb_nxt = 12'h0_0_f;                               // - - make a blue line.
            else                                                   // The rest of active display pixels:
                rgb_nxt = 12'h8_8_8;                               // - fill with gray.
        end
    end

endmodule