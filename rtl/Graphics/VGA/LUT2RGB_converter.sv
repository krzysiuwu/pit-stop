/*
 * Module to upscale our low-res resolution, to the target 1024x768 resolution. Basically every 1 pixel of low resolution will correspond to 4 pixels of target resolution.
 * This module will also take the LUT color values, and convert them to 12-bit color coding, which is used by VGA displays
 *
 */

module LUT2RGB_converter (

        input logic clk,
        input logic rst_n,
        input logic [3:0] lut_value,

        output logic [11:0] rgb_out,

        vga_if.in  vga_in,
        vga_if.out vga_out
    );

    logic  [11:0] rgb_next;

    always_comb begin                                           //convervsion to 12-bit colors from lut values
        case (lut_value)
            4'h0: rgb_next = 12'h000; // Black
            4'h1: rgb_next = 12'h333; // Dark Gray
            4'h2: rgb_next = 12'h777; // Medium Gray
            4'h3: rgb_next = 12'hCCC; // Light Gray
            4'h4: rgb_next = 12'hFFF; // White
            4'h5: rgb_next = 12'hF00; // Bright Red
            4'h6: rgb_next = 12'h900; // Dark Red
            4'h7: rgb_next = 12'hFF0; // Yellow
            4'h8: rgb_next = 12'hF80; // Orange
            4'h9: rgb_next = 12'h0B0; // Green
            4'hA: rgb_next = 12'h03A; // Dark Blue
            4'hB: rgb_next = 12'h0AF; // Light Blue
            4'hC: rgb_next = 12'hFCA; // Beige
            4'hD: rgb_next = 12'h631; // Brown
            4'hE: rgb_next = 12'hF0A; // Hot Pink
            4'hF: rgb_next = 12'hF0F; // Magenta
            default: rgb_next = 12'h000; // Default to Black
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin

        if(!rst_n) begin
            vga_out.vcount <= '0;
            vga_out.vblnk <= '0;
            vga_out.vsync <= '0;
            vga_out.hcount <= '0;
            vga_out.hblnk <= '0;
            vga_out.hsync <= '0;
            rgb_out <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vblnk <= vga_in.vblnk;
            vga_out.vsync <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hblnk <= vga_in.hblnk;
            vga_out.hsync <= vga_in.hsync;

            // Sygnał RGB musi być zerowany podczas trwania HBLANK i VBLANK
            if (vga_in.hblnk || vga_in.vblnk)
                rgb_out <= 12'h000;
            else
                rgb_out <= rgb_next;

        end
    end

endmodule
