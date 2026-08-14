/**
 * Description:
 * Draw background with static asphalt (dithering, depth, curbs) for 256x192 resolution
 */

module draw_bg (
        input  logic clk,
        input  logic rst,

        output logic [3:0] lut_out,

        low_res_if.in low_res_in,
        low_res_if.out low_res_out,
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
    localparam int ROAD_TOP_EDGE    = 104; // Asfalt zaczyna się trochę poniżej horyzontu (zostawiamy miejsce na krawężnik/trawę)
    localparam int ROAD_BOTTOM_EDGE = 184; // Asfalt kończy się przed samym dołem ekranu
    localparam int ROAD_CENTER_Y    = 144; // Środek drogi w osi Y

// --- Cloud Sprite Parameters ---
    localparam int CLOUD_W = 26;
    localparam int CLOUD_H = 20;

// --- Grandstand Sprite Parameters ---
    localparam int Grandstand_W = 55;
    localparam int Grandstand_H = 56;

// --- Cloud Positions ---
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
    logic [12:0] addr_grandstand;

    logic [3:0] cloud_lut;
    logic [3:0] grandstand_lut;

    logic [3:0] bg_lut;
    logic [3:0] lut_nxt;

// --- Delayed singnals ---
    logic is_cloud_d;
    logic is_grandstand_d;
    logic [3:0] bg_lut_d;
    logic [10:0] hcount_d, vcount_d;
    logic vsync_d, hsync_d, vblnk_d, hblnk_d;

    logic is_shadow;
// Cień rzucany przez trybuny - pas od 96 do 107 piksela w osi Y
    assign is_shadow = (low_res_in.vcount >= 96 && low_res_in.vcount < 108);

    /**
     * Active Region Detection & Address Calculation
     */

// 1. Check if the coordinate is inside any sprite
    assign is_c1 = (low_res_in.hcount >= C1_X) && (low_res_in.hcount < C1_X + CLOUD_W) &&
        (low_res_in.vcount >= C1_Y) && (low_res_in.vcount < C1_Y + CLOUD_H);

    assign is_c2 = (low_res_in.hcount >= C2_X) && (low_res_in.hcount < C2_X + CLOUD_W) &&
        (low_res_in.vcount >= C2_Y) && (low_res_in.vcount < C2_Y + CLOUD_H);

    assign is_c3 = (low_res_in.hcount >= C3_X) && (low_res_in.hcount < C3_X + CLOUD_W) &&
        (low_res_in.vcount >= C3_Y) && (low_res_in.vcount < C3_Y + CLOUD_H);

    assign is_cloud = is_c1 | is_c2 | is_c3;

// Grandstands hitboxes
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

// 2. Determine the local X and Y for the currently drawn sprite
    always_comb begin
        if (is_c1) begin
            local_x = low_res_in.hcount - C1_X;
            local_y = low_res_in.vcount - C1_Y;
        end else if (is_c2) begin
            local_x = low_res_in.hcount - C2_X;
            local_y = low_res_in.vcount - C2_Y;
        end else if (is_c3) begin
            local_x = low_res_in.hcount - C3_X;
            local_y = low_res_in.vcount - C3_Y;

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
    assign addr_grandstand = is_grandstand ? ((local_y * Grandstand_W) + local_x) : 13'b0;

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
            low_res_out.vcount <= low_res_in.vcount;
            low_res_out.hcount <= low_res_in.hcount;
        end
    end

    always_comb begin : bg_comb_blk
        // Domyślne tło (jasnoniebieskie niebo)
        bg_lut = 4'hB;

        if (low_res_in.vcount >= 96) begin

            // 1. ELEMENTY STRUKTURALNE (Statyczna jezdnia w POZIOMIE)
            if (low_res_in.vcount < ROAD_TOP_EDGE || low_res_in.vcount > ROAD_BOTTOM_EDGE) begin
                // Poziome krawężniki (zmiana koloru co 16 pikseli w osi X)
                if (low_res_in.hcount[4] == 1'b0) bg_lut = 4'h4; // Biały
                else                              bg_lut = 4'h5; // Czerwony

                // Przerywana linia na środku asfaltu (zmiana co 32 piksele w osi X)
            end else if (low_res_in.vcount >= ROAD_CENTER_Y - 1 && low_res_in.vcount <= ROAD_CENTER_Y + 1) begin
                if (low_res_in.hcount[5] == 1'b0) bg_lut = 4'h4; // Biały
                else                              bg_lut = 4'h1; // Przerwa w linii (kolor asfaltu)

            end else begin
                // Właściwy, gładki asfalt
                bg_lut = 4'h1; // Średni szary
            end

            // 2. CIEŃ OD TRYBUN
            if (is_shadow) begin
                // Sprzętowe mapowanie kolorów na ciemniejsze w strefie cienia
                case (bg_lut)
                    4'h4: bg_lut = 4'h2; // Biały -> Ciemnoszary
                    4'h5: bg_lut = 4'h6; // Czerwony -> Ciemnoczerwony
                    4'h1: bg_lut = 4'h0; // Średni asfalt -> Ciemny (Czarny)
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

// Setting correct LUT value based on the active sprite
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