import vga_pkg::*;
import low_res_pkg::*;

module draw_WheelRack (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);
     
    localparam int SPRITE_WIDTH  = 52;
    localparam int SPRITE_HEIGHT = 45;

    // 1. Własna, wbudowana logika hitboxa (zamiast sprite_renderer)
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

    // 2. Adres i Pamięć ROM
    logic [11:0] rom_addr;
    assign rom_addr = in_hitbox ? ((local_y * SPRITE_WIDTH) + local_x) : 12'd0;

    logic [3:0] rom_data;

    WheelRack_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    // 3. Potok opóźniający
    logic       in_hitbox_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk or negedge rst) begin
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

    // 4. Inteligentne nakładanie warstw
    always_comb begin
        if (in_hitbox_d) begin
            if (rom_data === 4'hx || rom_data === 4'hz) begin
                // BŁĄD ODCZYTU PAMIĘCI (X): Rysuj czerwony prostokąt
                lut_out = 4'h5; 
            end else if (rom_data != 4'hF) begin
                // POPRAWNY ODCZYT: Rysuj normalny piksel z ROM
                lut_out = rom_data; 
            end else begin
                // KOLOR PRZEZROCZYSTY: Przepuść tło
                lut_out = lut_in_d; 
            end
        end else begin
            // POZA HITBOXEM: Przepuść tło
            lut_out = lut_in_d;
        end
    end

endmodule