/**
 * Description:
 * Dynamic string renderer (default 10 characters).
 * Adapted for 10-bit row address / 8-bit data Font_Rom.
 * Pipelined version.
 */

import vga_pkg::*;
import low_res_pkg::*;

module draw_string #(
    parameter int MAX_CHARS = 10
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    input  logic [(MAX_CHARS*8)-1:0] text_string, 
    input  logic [3:0]  text_color,               

    // --- Wejścia potoku ---
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,

    // --- Wyjścia potoku ---
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    localparam int TOTAL_WIDTH = MAX_CHARS * 8;
    localparam int CHAR_HEIGHT = 8;

    logic in_hitbox;
    logic [7:0] local_x; // Od 0 do (MAX_CHARS*8 - 1)
    logic [2:0] local_y; // Od 0 do 7 wewnątrz jednego znaku

    logic [11:0] cur_x, cur_y;
    assign cur_x = vga_in.hcount >> 2;
    assign cur_y = vga_in.vcount >> 2;

    assign in_hitbox = enable && 
                       (cur_x >= x_pos) && (cur_x < x_pos + TOTAL_WIDTH) && 
                       (cur_y >= y_pos) && (cur_y < y_pos + CHAR_HEIGHT);

    assign local_x = cur_x[7:0] - x_pos[7:0]; 
    assign local_y = cur_y[2:0] - y_pos[2:0];

    logic [4:0] char_index; 
    assign char_index = local_x[7:3];

    logic [7:0] char_array [0:MAX_CHARS-1];
    
    genvar i;
    generate
        for (i = 0; i < MAX_CHARS; i++) begin : gen_char_array
            assign char_array[i] = text_string[((MAX_CHARS - 1 - i) * 8) +: 8];
        end
    endgenerate

    logic [7:0] current_char_code;
    always_comb begin
        current_char_code = 8'h20;
        if (in_hitbox && (char_index < MAX_CHARS))
            current_char_code = char_array[char_index];
    end

    // Zmiana rozmiarów pod Twój moduł Font_Rom
    logic [9:0] rom_addr;
    logic [7:0]  rom_data; 

    // Adresujemy tylko wiersz: 7 bitów znaku + 3 bity wiersza (Y)
    assign rom_addr = in_hitbox ? {current_char_code[6:0], local_y[2:0]} : 10'b0;

    // Instancja Twojego modułu ROM
    Font_Rom u_font_rom (
        .clk(clk),
        .address(rom_addr),
        .data_out(rom_data) // Wyjście to cały 8-bitowy wiersz
    );

    // --- Rejestry opóźniające potoku ---
    logic       in_hitbox_d;
    logic [3:0] lut_in_d;
    logic [2:0] pixel_x_d; // Rejestr do zapamiętania współrzędnej X wewnątrz znaku

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_hitbox_d    <= 1'b0;
            pixel_x_d      <= '0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            lut_in_d       <= '0;
        end else begin
            in_hitbox_d    <= in_hitbox;
            
            // Opóźniamy współrzędną X o 1 takt, aby spotkała się z wyjściem z ROMu
            pixel_x_d      <= local_x[2:0]; 
            
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            
            lut_in_d       <= lut_in;
        end
    end

    // --- Rysowanie konkretnego piksela ---
    logic       pixel_bit;
    logic       sprite_active;
    logic [3:0] sprite_pixel;

    // Wyciągamy 1 bit ze zwróconego 8-bitowego wiersza.
    // Najstarszy bit (7) jest z reguły rysowany po lewej stronie, stąd (7 - pixel_x)
    assign pixel_bit = rom_data[7 - pixel_x_d];

    assign sprite_active = in_hitbox_d && (pixel_bit == 1'b1);
    assign sprite_pixel  = text_color;

    // Nakładanie warstw (Z-Buffer)
    always_comb begin
        if (sprite_active) begin
            lut_out = sprite_pixel;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
