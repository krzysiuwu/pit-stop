/**
 * Module: draw_char
 * Summary: Legacy single-character overlay that aligns font-ROM data with the VGA pipeline.
 * Author: Adam Krupa
 */
import vga_pkg::*;
import low_res_pkg::*;

module draw_char (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    input  logic [6:0]  char_code,
    input  logic [3:0]  char_color,
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    logic [9:0] rom_addr;
    logic [7:0] rom_data;
    
    logic [3:0]  sprite_pixel;
    logic        sprite_active;

    logic [11:0] cur_x;
    logic [11:0] cur_y;
    logic        in_hitbox;
    logic [2:0]  local_x;
    logic [2:0]  local_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;
    assign in_hitbox = enable &&
                       (cur_x >= x_pos) && (cur_x < x_pos + 12'd8) &&
                       (cur_y >= y_pos) && (cur_y < y_pos + 12'd8);
    assign local_x = cur_x - x_pos;
    assign local_y = cur_y - y_pos;
    assign rom_addr = in_hitbox ? {char_code, local_y} : 10'd0;

    Font_Rom u_font_rom (
        .clk(clk),
        .address(rom_addr),
        .data_out(rom_data)
    );

    logic [3:0] lut_in_d;
    logic       in_hitbox_d;
    logic [2:0] pixel_x_d;
    logic [3:0] char_color_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            lut_in_d       <= '0;
            in_hitbox_d    <= 1'b0;
            pixel_x_d      <= 3'd0;
            char_color_d   <= 4'd0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            lut_in_d       <= lut_in;
            in_hitbox_d    <= in_hitbox;
            pixel_x_d      <= local_x;
            char_color_d   <= char_color;
        end
    end

    assign sprite_active = in_hitbox_d && rom_data[7 - pixel_x_d];
    assign sprite_pixel = char_color_d;

    always_comb begin
        if (sprite_active) begin
            lut_out = sprite_pixel;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
