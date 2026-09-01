/**
 * Module: draw_Wheel
 * Summary: Renders an independently positioned wheel with animated tread colors and transparency.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_Wheel (
        input  logic clk,
        input  logic rst,
        input  logic enable,
        input  logic [1:0] wheel_anim_step,

        input  logic signed [12:0] x_pos,
        input  logic signed [12:0] y_pos,

        input  logic [3:0] lut_in,
        vga_if.in          vga_in,

        output logic [3:0] lut_out,
        vga_if.out         vga_out
    );

    localparam int SPRITE_WIDTH  = 26;
    localparam int SPRITE_HEIGHT = 27;

    localparam logic signed [12:0] WIDTH_S  = 13'(SPRITE_WIDTH);
    localparam logic signed [12:0] HEIGHT_S = 13'(SPRITE_HEIGHT);

    logic in_hitbox;
    logic signed [12:0] cur_x_signed;
    logic signed [12:0] cur_y_signed;

    logic [11:0] local_x;
    logic [11:0] local_y;

    assign cur_x_signed =
        $signed({2'b00, vga_in.hcount}) >>> 2;

    assign cur_y_signed =
        $signed({2'b00, vga_in.vcount}) >>> 2;

    assign in_hitbox =
        enable &&
        (cur_x_signed >= x_pos) &&
        (cur_x_signed <  x_pos + WIDTH_S) &&
        (cur_y_signed >= y_pos) &&
        (cur_y_signed <  y_pos + HEIGHT_S);

    assign local_x = $unsigned(cur_x_signed - x_pos);
    assign local_y = $unsigned(cur_y_signed - y_pos);

    logic [$clog2(SPRITE_WIDTH * SPRITE_HEIGHT)-1:0] rom_addr;
    (* use_dsp = "no" *) logic [9:0] row_offset;
    logic [9:0] local_y_ext;

    // 26*y = 16*y + 8*y + 2*y.  A small carry-chain adder is more
    // appropriate here than an unpipelined DSP48 multiplier.
    assign local_y_ext = local_y[9:0];
    assign row_offset = (local_y_ext << 4)
                      + (local_y_ext << 3)
                      + (local_y_ext << 1);
    assign rom_addr = in_hitbox ? (row_offset + local_x[9:0]) : '0;

    logic [3:0] rom_data;

    Wheel_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    logic       in_hitbox_d;
    logic [3:0] lut_in_d;
    logic [1:0] wheel_anim_step_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;

            in_hitbox_d    <= 1'b0;
            lut_in_d       <= '0;
            wheel_anim_step_d <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;

            in_hitbox_d    <= in_hitbox;
            lut_in_d       <= lut_in;
            wheel_anim_step_d <= wheel_anim_step;
        end
    end

    // Rotate the three tread colors using the same palette entries
    // as the wheel animation in draw_BolidF1Default.
    logic [3:0] mapped_color;

    always_comb begin
        mapped_color = rom_data;

        case (rom_data)
            4'hA: begin
                if      (wheel_anim_step_d == 2'd1) mapped_color = 4'h9;
                else if (wheel_anim_step_d == 2'd2) mapped_color = 4'hE;
            end

            4'h9: begin
                if      (wheel_anim_step_d == 2'd1) mapped_color = 4'hE;
                else if (wheel_anim_step_d == 2'd2) mapped_color = 4'hA;
            end

            4'hE: begin
                if      (wheel_anim_step_d == 2'd1) mapped_color = 4'hA;
                else if (wheel_anim_step_d == 2'd2) mapped_color = 4'h9;
            end

            default: mapped_color = rom_data;
        endcase
    end

    always_comb begin
        if (in_hitbox_d && rom_data != 4'hF) begin
            lut_out = mapped_color;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
