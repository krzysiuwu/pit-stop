/**
 * Description:
 * Draw background
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

    // --- Cloud Sprite Parameters ---
    localparam int CLOUD_W = 26;
    localparam int CLOUD_H = 20;

    // --- Grandstand Sprite Parameters ---
    localparam int Grandstand_W = 96;
    localparam int Grandstand_H = 56;

    // --- Cloud Positions ---
    localparam int C1_X = 30,  C1_Y = 15;
    localparam int C2_X = 120, C2_Y = 35;
    localparam int C3_X = 220, C3_Y = 10;

    // --- Grandstand Positions ---
    localparam int G1_X = 1,  G1_Y = 95;

    // Cloud active signals
    logic is_c1, is_c2, is_c3;
    logic is_cloud;
    logic is_grandstand;

    // Local coordinates inside the current sprite
    logic [7:0] local_x;
    logic [7:0] local_y;

    logic [9:0] addr_cloud;
    logic [3:0] cloud_lut;

    logic [12:0] addr_grandstand;
    logic [3:0] grandstand_lut;

    logic [3:0] bg_lut;
    logic [3:0] lut_nxt;

    // --- Delayed singnals ---
    logic is_cloud_d;
    logic is_grandstand_d;
    logic [3:0] bg_lut_d;
    logic [11:0] hcount_d, vcount_d;
    logic vsync_d, hsync_d, vblnk_d, hblnk_d;

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

    assign is_grandstand = (low_res_in.hcount >= G1_X) && (low_res_in.hcount < G1_X + Grandstand_W) &&
        (low_res_in.vcount >= G1_Y) && (low_res_in.vcount < G1_Y + Grandstand_H);

    assign is_cloud = is_c1 | is_c2 | is_c3;

    // 2. Determine the local X and Y for the currently drown sprite
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
        end else if (is_grandstand) begin
            local_x = low_res_in.hcount - G1_X;
            local_y = low_res_in.vcount - G1_Y;
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

    // Delaying signals because reading from ROM takes 1 clock cycle
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
        if (low_res_in.vcount >= 96) begin
            bg_lut = 4'h1;                                              //grey asphalt
        end else if (low_res_in.vcount >= 72) begin
            bg_lut = 4'hB;                                              //light blue sky
        end else if (low_res_in.vcount >= 48) begin
            bg_lut = (low_res_in.vcount[0]) ? 4'hB : 4'hA;              // 50/50 mixture of light blue and dark blue for a gradient
        end else if (low_res_in.vcount >= 24) begin
            bg_lut = (low_res_in.vcount[1:0] == 2'b11) ? 4'hB : 4'hA;   // 25/75 mixture of light blue and dark blue for a gradient
        end else begin
            bg_lut = 4'hA;                                              //dark blue sky 
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
            lut_nxt = cloud_lut; // Draw the cloud
        end else if(is_grandstand_d && grandstand_lut != 4'hF) begin
            lut_nxt = grandstand_lut; // Draw the grandstand
        end else begin
            lut_nxt = bg_lut_d;    // Draw the sky
        end
    end

endmodule