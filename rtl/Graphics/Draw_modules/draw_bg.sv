/**
 * Module: draw_bg
 * Summary: Generates the low-resolution race-track background with grandstands and animated clouds.
 * Author: Adam Krupa, Krzysztof Jędrzejek
 */
module draw_bg (
        input  logic clk,
        input  logic rst,

        output logic [3:0] lut_out,

        vga_if.in vga_in,
        vga_if.out vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

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
    logic [11:0] addr_grandstand;

    logic [3:0] cloud_lut;
    logic [3:0] grandstand_lut;

    logic [3:0] bg_lut;
    logic [3:0] lut_nxt;
    logic [11:0] cur_x;
    logic [11:0] cur_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

// --- Delayed signals ---
    logic is_cloud_d;
    logic is_grandstand_d;
    logic [3:0] bg_lut_d;
    logic [10:0] hcount_d, vcount_d;
    logic hsync_d, vblnk_d, hblnk_d;

    logic is_shadow;
    assign is_shadow = (cur_y >= 96 && cur_y < 108);

    /**
     * =========================================================================
     * CLOUD ANIMATION LOGIC (Floating effect)
     * =========================================================================
     */
    logic vsync_prev;
    logic [6:0] frame_cnt;

    always_ff @(posedge clk) begin
        if (!rst) begin
            frame_cnt <= '0;
            vsync_prev <= '0;
        end else begin
            vsync_prev <= vga_in.vsync;
            // Count VSYNC edges to advance the background animation once per frame.
            if (!vga_in.vsync && vsync_prev) begin
                frame_cnt <= frame_cnt + 1'b1;
            end
        end
    end

// Triangle-wave samples: {2, 3, 4, 3, 2, 1, 0, 1}.
// Subtracting two yields the smooth offset sequence 0, +1, +2, +1, 0, -1, -2, -1.
    logic [2:0] cloud_anim_rom [0:7] = '{ 3'd2, 3'd3, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0, 3'd1 };

    logic [11:0] dyn_c1_y, dyn_c2_y, dyn_c3_y;

    always_comb begin
        // Bits [6:4] advance every 16 frames, approximately one pixel per 0.25 s.
        // Invert C2's phase so the clouds do not move in perfect formation.
        dyn_c1_y = 12'(C1_Y) + cloud_anim_rom[frame_cnt[6:4]] - 12'd2;
        dyn_c2_y = 12'(C2_Y) + cloud_anim_rom[~frame_cnt[6:4]] - 12'd2;
        dyn_c3_y = 12'(C3_Y) + cloud_anim_rom[frame_cnt[6:4]] - 12'd2;
    end

    /**
     * Active Region Detection & Address Calculation
     */

// Detect cloud hitboxes using their animated vertical positions.
    assign is_c1 = (cur_x >= C1_X) && (cur_x < C1_X + CLOUD_W) &&
        (cur_y >= dyn_c1_y) && (cur_y < dyn_c1_y + CLOUD_H);

    assign is_c2 = (cur_x >= C2_X) && (cur_x < C2_X + CLOUD_W) &&
        (cur_y >= dyn_c2_y) && (cur_y < dyn_c2_y + CLOUD_H);

    assign is_c3 = (cur_x >= C3_X) && (cur_x < C3_X + CLOUD_W) &&
        (cur_y >= dyn_c3_y) && (cur_y < dyn_c3_y + CLOUD_H);

    assign is_cloud = is_c1 | is_c2 | is_c3;

// Detect the static grandstand hitboxes.
    assign is_g1 = (cur_x >= G1_X) && (cur_x < G1_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g2 = (cur_x >= G2_X) && (cur_x < G2_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g3 = (cur_x >= G3_X) && (cur_x < G3_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g4 = (cur_x >= G4_X) && (cur_x < G4_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g5 = (cur_x >= G5_X) && (cur_x < G5_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g6 = (cur_x >= G6_X) && (cur_x < G6_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);
    assign is_g7 = (cur_x >= G7_X) && (cur_x < G7_X + Grandstand_W) &&
        (cur_y >= GY) && (cur_y < GY + Grandstand_H);

    assign is_grandstand = is_g1 | is_g2 | is_g3 | is_g4 | is_g5 | is_g6 | is_g7;

// Calculate local coordinates for the active sprite.
    always_comb begin
        if (is_c1) begin
            local_x = cur_x - C1_X;
            local_y = cur_y - dyn_c1_y;
        end else if (is_c2) begin
            local_x = cur_x - C2_X;
            local_y = cur_y - dyn_c2_y;
        end else if (is_c3) begin
            local_x = cur_x - C3_X;
            local_y = cur_y - dyn_c3_y;

            // Select the active grandstand instance.
        end else if (is_g1) begin
            local_x = cur_x - G1_X;
            local_y = cur_y - GY;
        end else if (is_g2) begin
            local_x = cur_x - G2_X;
            local_y = cur_y - GY;
        end else if (is_g3) begin
            local_x = cur_x - G3_X;
            local_y = cur_y - GY;
        end else if (is_g4) begin
            local_x = cur_x - G4_X;
            local_y = cur_y - GY;
        end else if (is_g5) begin
            local_x = cur_x - G5_X;
            local_y = cur_y - GY;
        end else if (is_g6) begin
            local_x = cur_x - G6_X;
            local_y = cur_y - GY;
        end else if (is_g7) begin
            local_x = cur_x - G7_X;
            local_y = cur_y - GY;

        end else begin
            local_x = '0;
            local_y = '0;
        end
    end

// 3. Calculate memory address for the ROM module
    assign addr_cloud = is_cloud ? ((local_y * CLOUD_W) + local_x) : 10'b0;
    assign addr_grandstand = is_grandstand ? ((local_y * Grandstand_W) + local_x) : 12'b0;

    /**
     * Internal logic
     */

    always_ff @(posedge clk) begin
        if (!rst) begin
            is_cloud_d      <= '0;
            is_grandstand_d <= '0;
            bg_lut_d        <= '0;

            hcount_d <= '0;
            vcount_d <= '0;
            hsync_d  <= '0;
            vblnk_d  <= '0;
            hblnk_d  <= '0;
        end else begin
            is_cloud_d      <= is_cloud;
            is_grandstand_d <= is_grandstand;
            bg_lut_d        <= bg_lut;

            hcount_d <= vga_in.hcount;
            vcount_d <= vga_in.vcount;
            hsync_d  <= vga_in.hsync;
            vblnk_d  <= vga_in.vblnk;
            hblnk_d  <= vga_in.hblnk;
        end
    end

    always_ff @(posedge clk) begin : bg_ff_blk
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
            // vsync_prev already registers vga_in.vsync. Reusing it preserves
            // the two-cycle pipeline delay without synthesizing a duplicate register.
            vga_out.vsync  <= vsync_prev;
            vga_out.vblnk  <= vblnk_d;
            vga_out.hcount <= hcount_d;
            vga_out.hsync  <= hsync_d;
            vga_out.hblnk  <= hblnk_d;
            lut_out        <= lut_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        bg_lut = 4'hB;

        if (cur_y >= 96) begin
            if (cur_y < ROAD_TOP_EDGE || cur_y > ROAD_BOTTOM_EDGE) begin
                if (cur_x[4] == 1'b0) bg_lut = 4'h4;
                else                              bg_lut = 4'h5;

            end else if (cur_y >= ROAD_CENTER_Y - 1 && cur_y <= ROAD_CENTER_Y + 1) begin
                if (cur_x[5] == 1'b0) bg_lut = 4'h4;
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
