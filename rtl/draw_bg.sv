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
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.hblnk  <= vga_in.hblnk;
            vga_out.rgb    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        if (vga_in.vblnk || vga_in.hblnk) begin             // Blanking region:
            rgb_nxt = 12'h0_0_0;                    // - make it it black.
        end else begin                              // Active region:
            if (vga_in.vcount == 0)                     // - top edge:
                rgb_nxt = 12'hf_f_0;                // - - make a yellow line.
            else if (vga_in.vcount == VER_PIXELS - 1)   // - bottom edge:
                rgb_nxt = 12'hf_0_0;                // - - make a red line.
            else if (vga_in.hcount == 0)                // - left edge:
                rgb_nxt = 12'h0_f_0;                // - - make a green line.
            else if (vga_in.hcount == HOR_PIXELS - 1)   // - right edge:
                rgb_nxt = 12'h0_0_f;                // - - make a blue line.

                // Litera 'A' (X: 100-140)
            else if ( (vga_in.hcount >= 100 && vga_in.hcount <= 110 && vga_in.vcount >= 100 && vga_in.vcount <= 150) || // Lewa krawędź
            (vga_in.hcount >= 130 && vga_in.hcount <= 140 && vga_in.vcount >= 100 && vga_in.vcount <= 150) || // Prawa krawędź
            (vga_in.hcount >= 110 && vga_in.hcount <= 130 && vga_in.vcount >= 100 && vga_in.vcount <= 110) || // Góra
            (vga_in.hcount >= 110 && vga_in.hcount <= 130 && vga_in.vcount >= 120 && vga_in.vcount <= 130) )  // Środek
      rgb_nxt = 12'hf_f_f; // Biały kolor

  // Litera 'K' (X: 160-200)
  else if ( (vga_in.hcount >= 160 && vga_in.hcount <= 170 && vga_in.vcount >= 100 && vga_in.vcount <= 150) || // Lewa krawędź
            (vga_in.hcount >= 170 && vga_in.hcount <= 185 && vga_in.vcount >= 120 && vga_in.vcount <= 130) || // Łącznik
            (vga_in.hcount >= 185 && vga_in.hcount <= 200 && vga_in.vcount >= 100 && vga_in.vcount <= 120) || // Prawe górne ramię
            (vga_in.hcount >= 185 && vga_in.hcount <= 200 && vga_in.vcount >= 130 && vga_in.vcount <= 150) )  // Prawe dolne ramię
      rgb_nxt = 12'hf_f_f;

  // Znak '_' (X: 220-260)
  else if ( vga_in.hcount >= 220 && vga_in.hcount <= 260 && vga_in.vcount >= 140 && vga_in.vcount <= 150 )
      rgb_nxt = 12'hf_f_f;

  // Litera 'K' (X: 280-320)
  else if ( (vga_in.hcount >= 280 && vga_in.hcount <= 290 && vga_in.vcount >= 100 && vga_in.vcount <= 150) || // Lewa krawędź
            (vga_in.hcount >= 290 && vga_in.hcount <= 305 && vga_in.vcount >= 120 && vga_in.vcount <= 130) || // Łącznik
            (vga_in.hcount >= 305 && vga_in.hcount <= 320 && vga_in.vcount >= 100 && vga_in.vcount <= 120) || // Prawe górne ramię
            (vga_in.hcount >= 305 && vga_in.hcount <= 320 && vga_in.vcount >= 130 && vga_in.vcount <= 150) )  // Prawe dolne ramię
      rgb_nxt = 12'hf_f_f;

  // Litera 'J' (X: 340-380)
  else if ( (vga_in.hcount >= 370 && vga_in.hcount <= 380 && vga_in.vcount >= 100 && vga_in.vcount <= 150) || // Prawa długa krawędź
            (vga_in.hcount >= 340 && vga_in.hcount <= 370 && vga_in.vcount >= 140 && vga_in.vcount <= 150) || // Dolna krawędź
            (vga_in.hcount >= 340 && vga_in.hcount <= 350 && vga_in.vcount >= 120 && vga_in.vcount <= 140) )  // Lewy krótszy haczyk
      rgb_nxt = 12'hf_f_f;

            else                                    // The rest of active display pixels:
                rgb_nxt = 12'h8_8_8;                // - fill with gray.
        end
    end

endmodule
