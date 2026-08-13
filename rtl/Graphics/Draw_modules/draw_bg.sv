/**
 * Description:
 * Draw background with static asphalt (dithering, depth, curbs) for 256x192 resolution
 * Now with animated, floating clouds!
 */

 module draw_bg (
    input  logic clk,
    input  logic rst,

    output logic [3:0] lut_out,

    low_res_if.in low_res_in,
    vga_if.in vga_in,
    vga_if.out vga_out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import low_res_pkg::*;

/**
 * Local variables and signals
 */

// --- Road Parameters (Horizontal, Resolution 256x192) ---
localparam int ROAD_TOP_EDGE    = 104; 
localparam int ROAD_BOTTOM_EDGE = 184; 
localparam int ROAD_CENTER_Y    = 144; 

// --- Cloud Sprite Parameters ---
localparam int CLOUD_W = 26;
localparam int CLOUD_H = 20;

// --- Grandstand Sprite Parameters ---
localparam int Grandstand_W = 55; 
localparam int Grandstand_H = 56;

// --- Cloud Positions (Base Y) ---
localparam int C1_X = 30,  C1_Y = 15;
localparam int C2_X = 120, C2_Y = 10;
localparam int C3_X = 220, C3_Y = 12;

// --- Grandstand Positions ---
localparam int G1_X = 0;
localparam int G2_X = G1_X + Grandstand_W;
localparam int G3_X = G2_X + Grandstand_W;
localparam int G4_X = G3_X + Grandstand_W;
localparam int G5_X = G4_X + Grandstand_W;
localparam int G6_X = G5_X + Grandstand_W;
localparam int G7_X = G6_X + Grandstand_W; 
localparam int GY   = 41;

// Cloud active signals
logic is_c1, is_c2, is_c3;
logic is_cloud;

// Grandstand active signals
logic is_g1, is_g2, is_g3, is_g4, is_g5, is_g6, is_g7;
logic is_grandstand;

// Local coordinates inside the current sprite
logic [7:0] local_x;
logic [7:0] local_y;

logic [9:0] addr_cloud;
logic [13:0] addr_grandstand; // Zwiększyłem szerokość adresu dla pewności

logic [3:0] cloud_lut;
logic [3:0] grandstand_lut;

logic [3:0] bg_lut;
logic [3:0] lut_nxt;

// --- Delayed signals ---
logic is_cloud_d;
logic is_grandstand_d;
logic [3:0] bg_lut_d;
logic [11:0] hcount_d, vcount_d;
logic vsync_d, hsync_d, vblnk_d, hblnk_d;

logic is_shadow;
assign is_shadow = (low_res_in.vcount >= 96 && low_res_in.vcount < 108);

/**
 * =========================================================================
 * CLOUD ANIMATION LOGIC (Floating effect)
 * =========================================================================
 */
logic vsync_prev;
logic [6:0] frame_cnt; 

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        frame_cnt <= '0;
        vsync_prev <= '0;
    end else begin
        vsync_prev <= vga_in.vsync;
        // Detekcja nowej klatki (zbocze na vsync). Zliczamy klatki do animacji.
        if (!vga_in.vsync && vsync_prev) begin
            frame_cnt <= frame_cnt + 1'b1;
        end
    end
end

// Tablica fali trójkątnej: wartości {2, 3, 4, 3, 2, 1, 0, 1}
// Odejmując od tego 2, uzyskujemy płynne wahanie: 0, +1, +2, +1, 0, -1, -2, -1
logic [2:0] cloud_anim_rom [0:7] = '{ 3'd2, 3'd3, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0, 3'd1 };

logic [11:0] dyn_c1_y, dyn_c2_y, dyn_c3_y;

always_comb begin
    // Bity [6:4] zmieniają się co 16 klatek (~0.25 sekundy na 1 piksel ruchu)
    // C2 ma odwróconą fazę (~frame_cnt), żeby chmury nie latały w idealnym szyku
    dyn_c1_y = 12'(C1_Y) + cloud_anim_rom[frame_cnt[6:4]] - 12'd2;
    dyn_c2_y = 12'(C2_Y) + cloud_anim_rom[~frame_cnt[6:4]] - 12'd2;
    dyn_c3_y = 12'(C3_Y) + cloud_anim_rom[frame_cnt[6:4]] - 12'd2;
end

/**
 * Active Region Detection & Address Calculation
 */

// 1. Sprawdzamy hitboxy na podstawie DYNAMICZNYCH pozycji Y chmur
assign is_c1 = (low_res_in.hcount >= C1_X) && (low_res_in.hcount < C1_X + CLOUD_W) &&
    (low_res_in.vcount >= dyn_c1_y) && (low_res_in.vcount < dyn_c1_y + CLOUD_H);

assign is_c2 = (low_res_in.hcount >= C2_X) && (low_res_in.hcount < C2_X + CLOUD_W) &&
    (low_res_in.vcount >= dyn_c2_y) && (low_res_in.vcount < dyn_c2_y + CLOUD_H);

assign is_c3 = (low_res_in.hcount >= C3_X) && (low_res_in.hcount < C3_X + CLOUD_W) &&
    (low_res_in.vcount >= dyn_c3_y) && (low_res_in.vcount < dyn_c3_y + CLOUD_H);

assign is_cloud = is_c1 | is_c2 | is_c3;

// Grandstands hitboxes (bez zmian)
assign is_g1 = (low_res_in.hcount >= G1_X) && (low_res_in.hcount < G1_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g2 = (low_res_in.hcount >= G2_X) && (low_res_in.hcount < G2_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g3 = (low_res_in.hcount >= G3_X) && (low_res_in.hcount < G3_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g4 = (low_res_in.hcount >= G4_X) && (low_res_in.hcount < G4_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g5 = (low_res_in.hcount >= G5_X) && (low_res_in.hcount < G5_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g6 = (low_res_in.hcount >= G6_X) && (low_res_in.hcount < G6_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);
assign is_g7 = (low_res_in.hcount >= G7_X) && (low_res_in.hcount < G7_X + Grandstand_W) &&
    (low_res_in.vcount >= GY) && (low_res_in.vcount < GY + Grandstand_H);

assign is_grandstand = is_g1 | is_g2 | is_g3 | is_g4 | is_g5 | is_g6 | is_g7;

// 2. Obliczanie local_x i local_y dla aktywnego sprite'a
always_comb begin
    if (is_c1) begin
        local_x = low_res_in.hcount - C1_X;
        local_y = low_res_in.vcount - dyn_c1_y;
    end else if (is_c2) begin
        local_x = low_res_in.hcount - C2_X;
        local_y = low_res_in.vcount - dyn_c2_y;
    end else if (is_c3) begin
        local_x = low_res_in.hcount - C3_X;
        local_y = low_res_in.vcount - dyn_c3_y;
        
    // Kaskada trybun    
    end else if (is_g1) begin
        local_x = low_res_in.hcount - G1_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g2) begin
        local_x = low_res_in.hcount - G2_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g3) begin
        local_x = low_res_in.hcount - G3_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g4) begin
        local_x = low_res_in.hcount - G4_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g5) begin
        local_x = low_res_in.hcount - G5_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g6) begin
        local_x = low_res_in.hcount - G6_X;
        local_y = low_res_in.vcount - GY;
    end else if (is_g7) begin
        local_x = low_res_in.hcount - G7_X;
        local_y = low_res_in.vcount - GY;
        
    end else begin
        local_x = '0;
        local_y = '0;
    end
end

// 3. Calculate memory address for the ROM module
assign addr_cloud = is_cloud ? ((local_y * CLOUD_W) + local_x) : 10'b0;
assign addr_grandstand = is_grandstand ? ((local_y * Grandstand_W) + local_x) : 14'b0;

/**
 * Internal logic
 */

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        is_cloud_d      <= '0;
        is_grandstand_d <= '0;
        bg_lut_d        <= '0;

        hcount_d <= '0;
        vcount_d <= '0;
        vsync_d  <= '0;
        hsync_d  <= '0;
        vblnk_d  <= '0;
        hblnk_d  <= '0;
    end else begin
        is_cloud_d      <= is_cloud;
        is_grandstand_d <= is_grandstand;
        bg_lut_d        <= bg_lut;

        hcount_d <= vga_in.hcount;
        vcount_d <= vga_in.vcount;
        vsync_d  <= vga_in.vsync;
        hsync_d  <= vga_in.hsync;
        vblnk_d  <= vga_in.vblnk;
        hblnk_d  <= vga_in.hblnk;
    end
end

always_ff @(posedge clk or negedge rst) begin : bg_ff_blk
    if (!rst) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        lut_out        <= '0;
    end else begin
        vga_out.vcount <= vcount_d;
        vga_out.vsync  <= vsync_d;
        vga_out.vblnk  <= vblnk_d;
        vga_out.hcount <= hcount_d;
        vga_out.hsync  <= hsync_d;
        vga_out.hblnk  <= hblnk_d;
        lut_out        <= lut_nxt;
    end
end

always_comb begin : bg_comb_blk
    bg_lut = 4'hB; 
    
    if (low_res_in.vcount >= 96) begin
        if (low_res_in.vcount < ROAD_TOP_EDGE || low_res_in.vcount > ROAD_BOTTOM_EDGE) begin
            if (low_res_in.hcount[4] == 1'b0) bg_lut = 4'h4; 
            else                              bg_lut = 4'h5; 
            
        end else if (low_res_in.vcount >= ROAD_CENTER_Y - 1 && low_res_in.vcount <= ROAD_CENTER_Y + 1) begin
            if (low_res_in.hcount[5] == 1'b0) bg_lut = 4'h4; 
            else                              bg_lut = 4'h1; 
            
        end else begin
            bg_lut = 4'h1; 
        end
        
        if (is_shadow) begin
            case (bg_lut)
                4'h4: bg_lut = 4'h2; 
                4'h5: bg_lut = 4'h6; 
                4'h1: bg_lut = 4'h0; 
                default: bg_lut = 4'h0; 
            endcase
        end
    end
end

Cloud_Rom u_Cloud_Rom (
    .clk,
    .address(addr_cloud),
    .LUT_value(cloud_lut)
);

Grandstand_Rom u_Grandstand_Rom (
    .clk,
    .address(addr_grandstand),
    .LUT_value(grandstand_lut)
);

always_comb begin
    if (is_cloud_d && cloud_lut != 4'hF ) begin
        lut_nxt = cloud_lut; 
    end else if(is_grandstand_d && grandstand_lut != 4'hF) begin
        lut_nxt = grandstand_lut; 
    end else begin
        lut_nxt = bg_lut_d;    
    end
end

endmodule