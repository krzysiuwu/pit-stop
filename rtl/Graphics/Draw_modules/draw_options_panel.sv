import vga_pkg::*;
import low_res_pkg::*;

module draw_options_panel (
    input  logic       clk,
    input  logic       rst,
    input  logic       enable,
    input  logic       multiplayer,
    input  logic       uart_connected,
    input  logic       uart_peer_ready,
    input  logic       uart_test_mode,
    input  logic       waiting_for_uart,
    input  logic [1:0] game_mode,
    input  logic [7:0] target_value,
    input  logic [7:0] remote_score,

    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,

    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int PANEL_X = 6;
    localparam int PANEL_Y = 25;
    localparam int PANEL_W = 244;
    localparam int PANEL_H = 153;
    localparam int TEXT_X = 16;
    localparam int LINE_CHARS = 28;
    localparam int LINE_BITS = LINE_CHARS * 8;

    logic [11:0] cur_x;
    logic [11:0] cur_y;
    logic        in_panel;
    logic [3:0]  panel_color;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    assign in_panel = enable &&
                      (cur_x >= PANEL_X) && (cur_x < PANEL_X + PANEL_W) &&
                      (cur_y >= PANEL_Y) && (cur_y < PANEL_Y + PANEL_H);

    // Dark, high-contrast panel using only the game's existing fixed palette.
    always_comb begin
        panel_color = 4'h1;

        if ((cur_x == PANEL_X) || (cur_x == PANEL_X + PANEL_W - 1) ||
            (cur_y == PANEL_Y) || (cur_y == PANEL_Y + PANEL_H - 1)) begin
            panel_color = 4'h0;
        end else if ((cur_x == PANEL_X + 1) ||
                     (cur_x == PANEL_X + PANEL_W - 2) ||
                     (cur_y == PANEL_Y + 1) ||
                     (cur_y == PANEL_Y + PANEL_H - 2)) begin
            panel_color = 4'h5;
        end else if ((cur_y == 12'd42) || (cur_y == 12'd76) ||
                     (cur_y == 12'd113)) begin
            panel_color = 4'h6;
        end
    end

    // Select one of eight 8-pixel-high text rows.
    logic       in_text;
    logic [2:0] text_row;
    logic [2:0] text_local_y;
    logic [7:0] text_local_x;
    logic [4:0] char_index;

    always_comb begin
        in_text     = 1'b0;
        text_row    = 3'd0;
        text_local_y = 3'd0;

        if (enable && (cur_x >= TEXT_X) &&
            (cur_x < TEXT_X + LINE_CHARS * 8)) begin
            if ((cur_y >= 12'd31) && (cur_y < 12'd39)) begin
                in_text = 1'b1;
                text_row = 3'd0;
                text_local_y = cur_y - 12'd31;
            end else if ((cur_y >= 12'd49) && (cur_y < 12'd57)) begin
                in_text = 1'b1;
                text_row = 3'd1;
                text_local_y = cur_y - 12'd49;
            end else if ((cur_y >= 12'd65) && (cur_y < 12'd73)) begin
                in_text = 1'b1;
                text_row = 3'd2;
                text_local_y = cur_y - 12'd65;
            end else if ((cur_y >= 12'd83) && (cur_y < 12'd91)) begin
                in_text = 1'b1;
                text_row = 3'd3;
                text_local_y = cur_y - 12'd83;
            end else if ((cur_y >= 12'd99) && (cur_y < 12'd107)) begin
                in_text = 1'b1;
                text_row = 3'd4;
                text_local_y = cur_y - 12'd99;
            end else if ((cur_y >= 12'd120) && (cur_y < 12'd128)) begin
                in_text = 1'b1;
                text_row = 3'd5;
                text_local_y = cur_y - 12'd120;
            end else if ((cur_y >= 12'd136) && (cur_y < 12'd144)) begin
                in_text = 1'b1;
                text_row = 3'd6;
                text_local_y = cur_y - 12'd136;
            end else if ((cur_y >= 12'd152) && (cur_y < 12'd160)) begin
                in_text = 1'b1;
                text_row = 3'd7;
                text_local_y = cur_y - 12'd152;
            end
        end
    end

    assign text_local_x = cur_x[7:0] - TEXT_X;
    assign char_index = text_local_x[7:3];

    logic [7:0] target_hundreds;
    logic [7:0] target_tens;
    logic [7:0] target_ones;
    logic [7:0] remote_hundreds;
    logic [7:0] remote_tens;
    logic [7:0] remote_ones;

    always_comb begin
        target_hundreds = 8'h30 + (target_value / 8'd100);
        target_tens     = 8'h30 + ((target_value % 8'd100) / 8'd10);
        target_ones     = 8'h30 + (target_value % 8'd10);
        remote_hundreds = 8'h30 + (remote_score / 8'd100);
        remote_tens     = 8'h30 + ((remote_score % 8'd100) / 8'd10);
        remote_ones     = 8'h30 + (remote_score % 8'd10);
    end

    logic [LINE_BITS-1:0] line_text;

    always_comb begin
        line_text = {LINE_CHARS{8'h20}};

        case (text_row)
            3'd0: begin
                if (waiting_for_uart)
                    line_text = {"WAITING FOR UART LINK", {7{8'h20}}};
                else
                    line_text = {"OPTIONS", {21{8'h20}}};
            end

            3'd1: begin
                if (multiplayer)
                    line_text = {"PLAYER   MULTIPLAYER", {8{8'h20}}};
                else
                    line_text = {"PLAYER   SINGLE", {13{8'h20}}};
            end

            3'd2: begin
                if (multiplayer) begin
                    if (uart_peer_ready)
                        line_text = {"UART     CONNECTED", {10{8'h20}}};
                    else if (uart_connected)
                        line_text = {"UART     PEER NOT READY", {5{8'h20}}};
                    else
                        line_text = {"UART     OFFLINE", {12{8'h20}}};
                end else if (uart_test_mode) begin
                    if (uart_connected)
                        line_text = {"UART     CONNECTED", {10{8'h20}}};
                    else
                        line_text = {"UART     OFFLINE", {12{8'h20}}};
                end
                else
                    line_text = {"UART     NOT USED", {11{8'h20}}};
            end

            3'd3: begin
                case (game_mode)
                    2'b00: line_text = {"MODE     TIME ATTACK", {8{8'h20}}};
                    2'b01: line_text = {"MODE     POINT RACE", {9{8'h20}}};
                    2'b10: line_text = {"MODE     SPEED UP", {11{8'h20}}};
                    default: line_text = {"MODE     BEST OF", {12{8'h20}}};
                endcase
            end

            3'd4: begin
                case (game_mode)
                    2'b00, 2'b10:
                        line_text = {"TARGET   ", target_hundreds,
                                     target_tens, target_ones,
                                     " SEC", {12{8'h20}}};
                    2'b01:
                        line_text = {"TARGET   ", target_hundreds,
                                     target_tens, target_ones,
                                     " PTS", {12{8'h20}}};
                    default:
                        line_text = {"TARGET   ", target_hundreds,
                                     target_tens, target_ones,
                                     " RUNS", {11{8'h20}}};
                endcase
            end

            3'd5: begin
                case (game_mode)
                    2'b00:
                        line_text = {"GOAL     SCORE AT LEAST 1", {3{8'h20}}};
                    2'b01:
                        line_text = {"GOAL     REACH TARGET", {7{8'h20}}};
                    2'b10:
                        line_text = {"GOAL     SURVIVE 5 RUNS", {5{8'h20}}};
                    default:
                        line_text = {"GOAL     FINISH ALL RUNS", {4{8'h20}}};
                endcase
            end
            3'd6: begin
                if (uart_test_mode)
                    line_text = {"BTNU FINISHES TEST", {10{8'h20}}};
                else
                    line_text = {"UART 115200 8N1", {13{8'h20}}};
            end

            default: begin
                if (uart_test_mode)
                    line_text = {"TX ", target_hundreds, target_tens,
                                 target_ones, "  RX ", remote_hundreds,
                                 remote_tens, remote_ones,
                                 "  7SEG RX", {5{8'h20}}};
                else
                    line_text = {"SW12 ENABLES UART TEST", {6{8'h20}}};
            end
        endcase
    end

    logic [7:0] current_char_code;
    logic [3:0] text_color;

    always_comb begin
        current_char_code = 8'h20;
        if (in_text && (char_index < LINE_CHARS))
            current_char_code =
                line_text[((LINE_CHARS - 1 - char_index) * 8) +: 8];

        text_color = 4'h3;
        if (text_row == 3'd0)
            text_color = 4'h4;
        else if ((text_row == 3'd1) && (char_index >= 5'd9))
            text_color = 4'h7;
        else if ((text_row == 3'd2) && (char_index >= 5'd9))
            text_color = ((multiplayer && uart_peer_ready) ||
                          (uart_test_mode && uart_connected))
                       ? 4'h7 : ((multiplayer || uart_test_mode) ? 4'h5 : 4'h3);
        else if (((text_row == 3'd3) || (text_row == 3'd4)) &&
                 (char_index >= 5'd9))
            text_color = 4'h7;
        else if ((text_row == 3'd5) && (char_index >= 5'd9))
            text_color = 4'h7;
        else if (text_row >= 3'd6)
            text_color = uart_test_mode ? 4'h7 : 4'h3;
    end

    logic [10:0] font_addr;
    logic [7:0]  font_data;

    assign font_addr = in_text
                     ? {current_char_code[6:0], text_local_y}
                     : 11'b0;

    Font_Rom u_font_rom (
        .clk(clk),
        .address(font_addr),
        .data_out(font_data)
    );

    logic       in_panel_d;
    logic       in_text_d;
    logic [2:0] pixel_x_d;
    logic [3:0] panel_color_d;
    logic [3:0] text_color_d;
    logic [3:0] lut_in_d;
    logic       text_pixel;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            in_panel_d     <= 1'b0;
            in_text_d      <= 1'b0;
            pixel_x_d      <= 3'b0;
            panel_color_d  <= 4'b0;
            text_color_d   <= 4'b0;
            lut_in_d       <= 4'b0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
        end else begin
            in_panel_d     <= in_panel;
            in_text_d      <= in_text;
            pixel_x_d      <= text_local_x[2:0];
            panel_color_d  <= panel_color;
            text_color_d   <= text_color;
            lut_in_d       <= lut_in;
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
        end
    end

    assign text_pixel = in_text_d && font_data[7 - pixel_x_d];

    always_comb begin
        if (text_pixel)
            lut_out = text_color_d;
        else if (in_panel_d)
            lut_out = panel_color_d;
        else
            lut_out = lut_in_d;
    end

    // The interface is kept for consistency with the other low-resolution
    // layers; coordinates are taken from the pipelined VGA interface.
    logic unused_low_res;
    assign unused_low_res = ^{low_res_in.hcount, low_res_in.vcount};

endmodule
