/**
 * Module: draw_PitstopLogo
 * Summary: Renders a four-frame animated pit-stop logo while compensating for synchronous ROM latency.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_PitstopLogo (
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,

    input  logic [3:0] lut_in,
    vga_if.in          vga_in,

    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int WIDTH  = 128;
    localparam int HEIGHT = 32;

    logic in_hitbox;
    logic [6:0] local_x; 
    logic [4:0] local_y; 

    logic [11:0] cur_x;
    logic [11:0] cur_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    assign in_hitbox =
        enable &&
        (cur_x >= x_pos) &&
        (cur_x <  x_pos + WIDTH) &&
        (cur_y >= y_pos) &&
        (cur_y <  y_pos + HEIGHT);

    assign local_x = cur_x - x_pos;
    assign local_y = cur_y - y_pos;

    logic [5:0] anim_counter;
    logic [1:0] frame_index;

    always_ff @(posedge clk) begin
        if (!rst) begin
            anim_counter <= '0;
        end else begin
            // The registered synchronization output also serves as
            // the previous sample used to detect the start of a frame.
            if (vga_in.vsync && !vga_out.vsync) begin
                anim_counter <= anim_counter + 1'b1;
            end
        end
    end

    assign frame_index = anim_counter[5:4];

    logic [13:0] rom_addr;
    logic [3:0]  rom_data;

    assign rom_addr = in_hitbox ? {frame_index, local_y, local_x} : 14'b0;

    PitstopLogo_Rom u_logo_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    logic in_hitbox_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_hitbox_d    <= 1'b0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            lut_in_d       <= '0;
        end else begin
            in_hitbox_d    <= in_hitbox;
            
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            lut_in_d       <= lut_in;
        end
    end

    logic       sprite_active;
    logic [3:0] sprite_pixel;

    assign sprite_active = in_hitbox_d && (rom_data != 4'hF);
    assign sprite_pixel  = rom_data;

    always_comb begin
        if (sprite_active) begin
            lut_out = sprite_pixel;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
