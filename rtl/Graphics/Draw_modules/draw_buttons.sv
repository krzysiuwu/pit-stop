/**
 * Module: draw_buttons
 * Summary: Shares one button sprite ROM and one font ROM across the PLAY, OPTS, and BACK buttons.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_buttons (
    input  logic clk,
    input  logic rst,

    input  logic enable_play,
    input  logic enable_options,
    input  logic enable_back,
    input  logic play_hovered,
    input  logic options_hovered,
    input  logic back_hovered,
    input  logic play_pressed,
    input  logic options_pressed,
    input  logic back_pressed,

    input  logic [11:0] play_x,
    input  logic [11:0] play_y,
    input  logic [11:0] options_x,
    input  logic [11:0] options_y,
    input  logic [11:0] back_x,
    input  logic [11:0] back_y,

    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int BTN_WIDTH = 78;
    localparam int BTN_HEIGHT = 28;
    localparam int TEXT_WIDTH = 32;
    localparam int TEXT_HEIGHT = 8;
    localparam int TEXT_OFFSET_X = (BTN_WIDTH - TEXT_WIDTH) / 2;
    localparam int TEXT_OFFSET_Y = 6;

    logic [11:0] cur_x;
    logic [11:0] cur_y;
    logic [11:0] play_y_dynamic;
    logic [11:0] options_y_dynamic;
    logic [11:0] back_y_dynamic;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;
    assign play_y_dynamic = play_y + (play_pressed ? 12'd2 : 12'd0);
    assign options_y_dynamic = options_y + (options_pressed ? 12'd2 : 12'd0);
    assign back_y_dynamic = back_y + (back_pressed ? 12'd2 : 12'd0);

    logic play_active;
    logic options_active;
    logic back_active;
    logic [11:0] selected_x;
    logic [11:0] selected_y;
    logic        selected_hovered;
    logic [31:0] selected_text;

    assign play_active = enable_play &&
                         (cur_x >= play_x) && (cur_x < play_x + BTN_WIDTH) &&
                         (cur_y >= play_y_dynamic) &&
                         (cur_y < play_y_dynamic + BTN_HEIGHT);
    assign options_active = enable_options &&
                            (cur_x >= options_x) &&
                            (cur_x < options_x + BTN_WIDTH) &&
                            (cur_y >= options_y_dynamic) &&
                            (cur_y < options_y_dynamic + BTN_HEIGHT);
    assign back_active = enable_back &&
                         (cur_x >= back_x) && (cur_x < back_x + BTN_WIDTH) &&
                         (cur_y >= back_y_dynamic) &&
                         (cur_y < back_y_dynamic + BTN_HEIGHT);

    always_comb begin
        selected_x = 12'd0;
        selected_y = 12'd0;
        selected_hovered = 1'b0;
        selected_text = "    ";

        if (play_active) begin
            selected_x = play_x;
            selected_y = play_y_dynamic;
            selected_hovered = play_hovered;
            selected_text = "PLAY";
        end else if (options_active) begin
            selected_x = options_x;
            selected_y = options_y_dynamic;
            selected_hovered = options_hovered;
            selected_text = "OPTS";
        end else if (back_active) begin
            selected_x = back_x;
            selected_y = back_y_dynamic;
            selected_hovered = back_hovered;
            selected_text = "BACK";
        end
    end

    logic in_button_raw;
    logic [11:0] local_button_x_raw;
    logic [11:0] local_button_y_raw;

    // Register the button selection before calculating the BRAM address.
    // The previous path crossed the screen FSM, hitbox comparisons, a DSP48
    // multiplication by 78 and the BRAM address port in a single 65 MHz cycle.
    logic        in_button_s0;
    logic [11:0] local_button_x_s0;
    logic [11:0] local_button_y_s0;
    logic        selected_hovered_s0;
    logic [31:0] selected_text_s0;
    logic [3:0]  lut_in_s0;
    logic [10:0] vcount_s0;
    logic        vsync_s0;
    logic [10:0] hcount_s0;
    logic        hsync_s0;
    logic        vblnk_s0;
    logic        hblnk_s0;

    assign in_button_raw = play_active || options_active || back_active;
    assign local_button_x_raw = cur_x - selected_x;
    assign local_button_y_raw = cur_y - selected_y;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_button_s0       <= 1'b0;
            local_button_x_s0  <= 12'd0;
            local_button_y_s0  <= 12'd0;
            selected_hovered_s0 <= 1'b0;
            selected_text_s0   <= "    ";
            lut_in_s0          <= 4'd0;
            vcount_s0          <= '0;
            vsync_s0           <= 1'b0;
            hcount_s0          <= '0;
            hsync_s0           <= 1'b0;
            vblnk_s0           <= 1'b0;
            hblnk_s0           <= 1'b0;
        end else begin
            in_button_s0       <= in_button_raw;
            local_button_x_s0  <= local_button_x_raw;
            local_button_y_s0  <= local_button_y_raw;
            selected_hovered_s0 <= selected_hovered;
            selected_text_s0   <= selected_text;
            lut_in_s0          <= lut_in;
            vcount_s0          <= vga_in.vcount;
            vsync_s0           <= vga_in.vsync;
            hcount_s0          <= vga_in.hcount;
            hsync_s0           <= vga_in.hsync;
            vblnk_s0           <= vga_in.vblnk;
            hblnk_s0           <= vga_in.hblnk;
        end
    end

    logic [11:0] button_address;
    logic [3:0]  button_data;
    logic [11:0] button_row_offset;

    // 78*y = 64*y + 16*y - 2*y.  Expressing the constant explicitly keeps
    // this small address calculation in the carry fabric instead of a DSP48.
    assign button_row_offset = (local_button_y_s0 << 6) +
                               (local_button_y_s0 << 4) -
                               (local_button_y_s0 << 1);
    assign button_address = in_button_s0
                          ? button_row_offset + local_button_x_s0
                          : 12'd0;

    BasicButton8chars_Rom u_button_rom (
        .clk(clk),
        .address(button_address),
        .LUT_value(button_data)
    );

    logic        in_text;
    logic [7:0]  local_text_x;
    logic [2:0]  local_text_y;
    logic [1:0]  char_index;
    logic [7:0]  current_char;
    logic [9:0]  font_address;
    logic [7:0]  font_data;

    assign in_text = in_button_s0 &&
                     (local_button_x_s0 >= TEXT_OFFSET_X) &&
                     (local_button_x_s0 < TEXT_OFFSET_X + TEXT_WIDTH) &&
                     (local_button_y_s0 >= TEXT_OFFSET_Y) &&
                     (local_button_y_s0 < TEXT_OFFSET_Y + TEXT_HEIGHT);
    assign local_text_x = local_button_x_s0 - TEXT_OFFSET_X;
    assign local_text_y = local_button_y_s0 - TEXT_OFFSET_Y;
    assign char_index = local_text_x[4:3];

    always_comb begin
        current_char = 8'h20;
        if (in_text)
            current_char = selected_text_s0[((3 - char_index) * 8) +: 8];
    end

    assign font_address = in_text
                        ? {current_char[6:0], local_text_y}
                        : 10'd0;

    Font_Rom u_font_rom (
        .clk(clk),
        .address(font_address),
        .data_out(font_data)
    );

    logic       in_button_d;
    logic       in_text_d;
    logic [2:0] text_pixel_x_d;
    logic       hovered_d;
    logic [3:0] lut_in_d;
    logic       text_pixel;
    logic [3:0] button_color;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_button_d    <= 1'b0;
            in_text_d      <= 1'b0;
            text_pixel_x_d <= 3'd0;
            hovered_d      <= 1'b0;
            lut_in_d       <= 4'd0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
        end else begin
            in_button_d    <= in_button_s0;
            in_text_d      <= in_text;
            text_pixel_x_d <= local_text_x[2:0];
            hovered_d      <= selected_hovered_s0;
            lut_in_d       <= lut_in_s0;
            vga_out.vcount <= vcount_s0;
            vga_out.vsync  <= vsync_s0;
            vga_out.hcount <= hcount_s0;
            vga_out.hsync  <= hsync_s0;
            vga_out.vblnk  <= vblnk_s0;
            vga_out.hblnk  <= hblnk_s0;
        end
    end

    assign text_pixel = in_text_d && font_data[7 - text_pixel_x_d];
    assign button_color = (hovered_d && button_data == 4'h0)
                        ? 4'h3 : button_data;

    always_comb begin
        if (text_pixel)
            lut_out = hovered_d ? 4'h3 : 4'h0;
        else if (in_button_d && button_data != 4'hf)
            lut_out = button_color;
        else
            lut_out = lut_in_d;
    end

endmodule
