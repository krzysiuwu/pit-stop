/**
 * Module: draw_mouse_cursor
 * Summary: Draws the arrow, hand, or power-tool cursor directly from compact bitmap constants.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_mouse_cursor (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        input  logic [1:0] cursor_type, // 00=arrow, 01=hand, 10=power tool

        input  logic [11:0] mouse_x,
        input  logic [11:0] mouse_y,

        input  logic [3:0] lut_in,
        vga_if.in          vga_in,

        output logic [3:0] lut_out,
        vga_if.out         vga_out
    );

    localparam int CURSOR_SIZE = 16;

    // =========================================================================
    // 0: ARROW (black outline 0, white fill 4)
    // =========================================================================
    localparam logic [15:0] MASK_ARROW [0:15] = '{
        16'h8000, 16'hC000, 16'hE000, 16'hF000, 16'hF800, 16'hFC00, 16'hFE00, 16'hFF00,
        16'hFF80, 16'hFFC0, 16'hFC00, 16'hDC00, 16'h8E00, 16'h0E00, 16'h0700, 16'h0300
    };
    localparam logic [63:0] COLOR_ARROW [0:15] = '{
        64'h0000000000000000, 64'h0000000000000000, 64'h0400000000000000, 64'h0440000000000000,
        64'h0444000000000000, 64'h0444400000000000, 64'h0444440000000000, 64'h0444444000000000,
        64'h0444444400000000, 64'h0444444444000000, 64'h0444400000000000, 64'h0400000000000000,
        64'h0000000000000000, 64'h0000000000000000, 64'h0000000000000000, 64'h0000000000000000
    };

    // =========================================================================
    // 1: HAND (black outline 0, white fill 4)
    // =========================================================================
    localparam logic [15:0] MASK_HAND [0:15] = '{
        16'h0300, 16'h0780, 16'h07E0, 16'h07F0, 16'h07FA, 16'h37FD, 16'h7FFF, 16'hFFFF,
        16'hFFFF, 16'h7FFE, 16'h3FFE, 16'h1FFE, 16'h0FFC, 16'h07FC, 16'h03F8, 16'h0000
    };
    localparam logic [63:0] COLOR_HAND [0:15] = '{
        64'h0000000000000000, 64'h0000044000000000, 64'h0000044000000000, 64'h0000044004400000,
        64'h0000044044400000, 64'h0000004404440040, 64'h0044004404440440, 64'h0444444444444440,
        64'h0444444444444440, 64'h0044444444444400, 64'h0004444444444400, 64'h0000444444444400,
        64'h0000044444444000, 64'h0000004444444000, 64'h0000000000000000, 64'h0000000000000000
    };

    // =========================================================================
    // 2: POWER TOOL (2=dark gray, 3=light gray, 5=light red, 7=yellow)
    // =========================================================================
    localparam logic [15:0] MASK_WRENCH [0:15] = '{
        16'h1E00, 16'h3F00, 16'hFFFC, 16'hFFFC, 16'hFFFC, 16'h1F00, 16'h1F00, 16'h1F00,
        16'h1F00, 16'h1F00, 16'h3F80, 16'h3F80, 16'h3F80, 16'h0000, 16'h0000, 16'h0000
    };
    localparam logic [63:0] COLOR_WRENCH [0:15] = '{
        64'h0000000000000000, // Upper outline
        64'h0003333000000000, // Nasadka (Jasnoszary)
        64'h0002222777777000, // Upper body: dark gray with a yellow detail
        64'h0332222255555000, // Center body: socket, gray body, and red rear
        64'h0002222777777000, // Lower body
        64'h0000222000000000, // Gray handle
        64'h0000222000000000, // Handle
        64'h0000555000000000, // Spust (Czerwony)
        64'h0000222000000000, // Handle
        64'h0000555000000000, // Spust
        64'h0003333300000000, // Bateria na dole
        64'h0003333300000000, // Bateria na dole
        64'h0000000000000000,
        64'h0000000000000000,
        64'h0000000000000000,
        64'h0000000000000000
    };

    logic [11:0] cur_x, cur_y;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    logic in_hitbox;
    logic [3:0] local_x, local_y;

    assign in_hitbox =
        enable &&
        (cur_x >= mouse_x) &&
        (cur_x <  mouse_x + CURSOR_SIZE) &&
        (cur_y >= mouse_y) &&
        (cur_y <  mouse_y + CURSOR_SIZE);

    assign local_x = cur_x[3:0] - mouse_x[3:0];
    assign local_y = cur_y[3:0] - mouse_y[3:0];

    int color_shift;
    assign color_shift = 63 - (int'(local_x) * 4);

    logic       pixel_active;
    logic [3:0] pixel_color;

    always_comb begin
        pixel_active = 1'b0;
        pixel_color  = 4'h0;

        if (in_hitbox) begin
            case (cursor_type)
                2'b00: begin
                    pixel_active = MASK_ARROW[local_y][15 - local_x];
                    pixel_color  = COLOR_ARROW[local_y][color_shift -: 4];
                end
                2'b01: begin
                    pixel_active = MASK_HAND[local_y][15 - local_x];
                    pixel_color  = COLOR_HAND[local_y][color_shift -: 4];
                end
                2'b10: begin
                    pixel_active = MASK_WRENCH[local_y][15 - local_x];
                    pixel_color  = COLOR_WRENCH[local_y][color_shift -: 4];
                end
                default: begin
                    pixel_active = MASK_ARROW[local_y][15 - local_x];
                    pixel_color  = COLOR_ARROW[local_y][color_shift -: 4];
                end
            endcase
        end
    end

    logic       pixel_active_d;
    logic [3:0] pixel_color_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0; vga_out.vsync  <= '0; vga_out.hcount <= '0;
            vga_out.hsync  <= '0; vga_out.vblnk  <= '0; vga_out.hblnk  <= '0;
            pixel_active_d <= 1'b0; pixel_color_d <= 4'h0; lut_in_d <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount; vga_out.vsync  <= vga_in.vsync; vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;  vga_out.vblnk  <= vga_in.vblnk; vga_out.hblnk  <= vga_in.hblnk;

            pixel_active_d <= pixel_active;
            pixel_color_d  <= pixel_color;
            lut_in_d       <= lut_in;
        end
    end

    always_comb begin
        if (pixel_active_d) begin
            lut_out = pixel_color_d;
        end else begin
            lut_out = lut_in_d;
        end
    end
endmodule
