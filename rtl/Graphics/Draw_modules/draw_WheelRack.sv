/**
 * Module: draw_WheelRack
 * Summary: Renders the wheel rack sprite and overlays it on the incoming palette stream.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_WheelRack (
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

    localparam int SPRITE_WIDTH  = 52;
    localparam int SPRITE_HEIGHT = 45;

    // Inline hitbox logic avoids a separate sprite_renderer instance.
    logic in_hitbox;
    logic [11:0] local_x;
    logic [11:0] local_y;

    logic [11:0] cur_x;
    logic [11:0] cur_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    assign in_hitbox =
        enable &&
        (cur_x >= x_pos) &&
        (cur_x <  x_pos + SPRITE_WIDTH) &&
        (cur_y >= y_pos) &&
        (cur_y <  y_pos + SPRITE_HEIGHT);

    assign local_x = cur_x - x_pos;
    assign local_y = cur_y - y_pos;

    // ROM address and storage
    logic [11:0] rom_addr;
    assign rom_addr = in_hitbox ? ((local_y * SPRITE_WIDTH) + local_x) : 12'd0;

    logic [3:0] rom_data;

    WheelRack_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    // Pipeline delay
    logic       in_hitbox_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;

            in_hitbox_d    <= '0;
            lut_in_d       <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;

            in_hitbox_d    <= in_hitbox;
            lut_in_d       <= lut_in;
        end
    end

    // Compose the wheel-rack layer. Its colors use the same global
    // palette indices as every other sprite.
    logic rack_pixel_active;
    assign rack_pixel_active = in_hitbox_d && (rom_data != 4'hF);

    always_comb begin
        if (rack_pixel_active) begin
            lut_out = rom_data;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
