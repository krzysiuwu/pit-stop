/**
 * Module: upscale_4x
 * Description: Upscales a 256x192 virtual resolution to a 1024x768 physical
 * display resolution by dividing coordinates by 4.
 */

module upscale_4x (
    input  logic clk,
    input  logic rst,

    // 256x192 RGB signal to upscale
    input  logic [11:0] rgb_in,

    // 1024x768 timing from vga_timing
    vga_if.in  vga_in,

    // Scaled coordinates going TO your 256x192 drawing logic
    output logic [10:0] hcount_scaled,
    output logic [10:0] vcount_scaled,

    // Final 1024x768 output going to the screen/next module
    vga_if.out vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Divide by 4 (shift right by 2) to generate 256x192 bounds
     */
    assign hcount_scaled = vga_in.hcount >> 2;
    assign vcount_scaled = vga_in.vcount >> 2;

    /**
     * Sync signals delay
     */
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vga_out.hcount <= '0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hsync  <= '0;
            vga_out.hblnk  <= '0;
        end else begin
            vga_out.hcount <= vga_in.hcount;
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync <=  vga_in.vsync;
            vga_out.vblnk <=  vga_in.vblnk;
            vga_out.hsync <=  vga_in.hsync;
            vga_out.hblnk <=  vga_in.hblnk;
        end
    end

    // Black color for blank regions
    assign vga_out.rgb    = (vga_out.vblnk || vga_out.hblnk) ? 12'h0_0_0 : rgb_in;

endmodule