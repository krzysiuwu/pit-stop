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

    logic [12:0] rom_addr;
    logic        rom_data;
    
    logic [3:0]  sprite_pixel;
    logic        sprite_active;

    Font_Rom u_font_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    char_renderer u_renderer (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        
        .x_pos(x_pos),
        .y_pos(y_pos),

        .hcount(low_res_in.hcount),
        .vcount(low_res_in.vcount),
        
        .char_code(char_code),
        .char_color(char_color),
        
        .rom_data(rom_data),
        .rom_addr(rom_addr),
        
        .pixel_out(sprite_pixel),
        .is_active(sprite_active)
    );

    logic [3:0] lut_in_d;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            lut_in_d       <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            lut_in_d       <= lut_in;
        end
    end

    always_comb begin
        if (sprite_active) begin
            lut_out = sprite_pixel;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule