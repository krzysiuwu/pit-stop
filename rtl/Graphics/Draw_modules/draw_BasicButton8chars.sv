import vga_pkg::*;
import low_res_pkg::*;

module draw_BasicButton8chars (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    // --- Dodane sygnały interakcji ---
    input  logic is_hovered,  // 1, gdy kursor myszy znajduje się nad przyciskiem
    input  logic is_pressed,  // 1, gdy przycisk jest kliknięty (wciśnięty lewy przycisk myszy)
    
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);
     
    localparam int SPRITE_WIDTH  = 78;
    localparam int SPRITE_HEIGHT = 28;

    logic [$clog2(SPRITE_WIDTH * SPRITE_HEIGHT)-1:0] rom_addr;
    logic [3:0] rom_data;

    logic [3:0] sprite_pixel;
    logic       sprite_active;

    // 1. Logika wciśnięcia (przesunięcie w osi Y)
    // Kiedy przycisk jest naciśnięty, sprzętowo dodajemy 2 piksele do jego pozycji Y
    logic [11:0] dynamic_y_pos;
    assign dynamic_y_pos = is_pressed ? (y_pos + 12'd2) : y_pos;

    logic [11:0] cur_x;
    logic [11:0] cur_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    BasicButton8chars_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    sprite_renderer #(
        .WIDTH(SPRITE_WIDTH),
        .HEIGHT(SPRITE_HEIGHT)
    ) u_renderer (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        
        .x_pos(x_pos),
        .y_pos(dynamic_y_pos), // Przekazanie nowej, dynamicznej pozycji!
        
        .hcount(cur_x),
        .vcount(cur_y),
        
        .rom_data(rom_data),
        .rom_addr(rom_addr),
        
        .pixel_out(sprite_pixel),
        .is_active(sprite_active)
    );

    // 2. Opóźnienia potoku
    logic [3:0] lut_in_d;
    logic       is_hovered_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            
            lut_in_d       <= '0;
            is_hovered_d   <= 1'b0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            
            lut_in_d       <= lut_in;
            
            // Rejestrujemy sygnał najechania, by zrekompensować opóźnienie pamięci ROM
            is_hovered_d   <= is_hovered; 
        end
    end

    // 3. Nakładanie warstw i zmiana koloru (hover effect)
    always_comb begin
        if (sprite_active) begin
            // Zakładamy, że 4'h0 to Twój kolor czarny, a 4'3 to jasny/ciemny szary.
            // Zmień wartość 4'h3 na odpowiedni indeks koloru z Twojego pliku Default_LUT.mem
            if (is_hovered_d && sprite_pixel == 4'h0) begin
                lut_out = 4'h3; 
            end else begin
                lut_out = sprite_pixel;
            end
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule