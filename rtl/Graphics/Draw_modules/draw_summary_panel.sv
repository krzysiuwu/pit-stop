import vga_pkg::*;
import low_res_pkg::*;
import game_pkg::*;

module draw_summary_panel (
    input  logic        clk,
    input  logic        rst,
    input  logic        enable,
    input  logic        multiplayer,
    input  logic [1:0]  match_result,
    input  logic [1:0]  game_mode,
    input  logic [7:0]  target_value,
    input  logic [7:0]  score,
    input  logic [7:0]  remote_score,
    input  logic [15:0] elapsed_seconds,
    input  logic [7:0]  last_stop_seconds,
    input  logic [7:0]  best_stop_seconds,

    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,

    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int PANEL_X = 6;
    localparam int PANEL_Y = 12;
    localparam int PANEL_W = 244;
    localparam int PANEL_H = 140;
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

    always_comb begin
        panel_color = 4'h1;

        if ((cur_x == PANEL_X) || (cur_x == PANEL_X + PANEL_W - 1) ||
            (cur_y == PANEL_Y) || (cur_y == PANEL_Y + PANEL_H - 1)) begin
            panel_color = 4'h0;
        end else if ((cur_x == PANEL_X + 1) ||
                     (cur_x == PANEL_X + PANEL_W - 2) ||
                     (cur_y == PANEL_Y + 1) ||
                     (cur_y == PANEL_Y + PANEL_H - 2)) begin
            case (match_result)
                RESULT_WIN:  panel_color = 4'h7;
                RESULT_DRAW: panel_color = 4'h4;
                default:     panel_color = 4'h5;
            endcase
        end else if ((cur_y == 12'd45) || (cur_y == 12'd61)) begin
            panel_color = 4'h6;
        end
    end

    logic       in_text;
    logic [2:0] text_row;
    logic [2:0] text_local_y;
    logic [7:0] text_local_x;
    logic [4:0] char_index;

    always_comb begin
        in_text      = 1'b0;
        text_row     = 3'd0;
        text_local_y = 3'd0;

        if (enable && (cur_x >= TEXT_X) &&
            (cur_x < TEXT_X + LINE_CHARS * 8)) begin
            if ((cur_y >= 12'd18) && (cur_y < 12'd26)) begin
                in_text = 1'b1;
                text_row = 3'd0;
                text_local_y = cur_y - 12'd18;
            end else if ((cur_y >= 12'd34) && (cur_y < 12'd42)) begin
                in_text = 1'b1;
                text_row = 3'd1;
                text_local_y = cur_y - 12'd34;
            end else if ((cur_y >= 12'd50) && (cur_y < 12'd58)) begin
                in_text = 1'b1;
                text_row = 3'd2;
                text_local_y = cur_y - 12'd50;
            end else if ((cur_y >= 12'd66) && (cur_y < 12'd74)) begin
                in_text = 1'b1;
                text_row = 3'd3;
                text_local_y = cur_y - 12'd66;
            end else if ((cur_y >= 12'd82) && (cur_y < 12'd90)) begin
                in_text = 1'b1;
                text_row = 3'd4;
                text_local_y = cur_y - 12'd82;
            end else if ((cur_y >= 12'd98) && (cur_y < 12'd106)) begin
                in_text = 1'b1;
                text_row = 3'd5;
                text_local_y = cur_y - 12'd98;
            end else if ((cur_y >= 12'd114) && (cur_y < 12'd122)) begin
                in_text = 1'b1;
                text_row = 3'd6;
                text_local_y = cur_y - 12'd114;
            end else if ((cur_y >= 12'd130) && (cur_y < 12'd138)) begin
                in_text = 1'b1;
                text_row = 3'd7;
                text_local_y = cur_y - 12'd130;
            end
        end
    end

    assign text_local_x = cur_x[7:0] - TEXT_X;
    assign char_index = text_local_x[7:3];

    function automatic logic [23:0] decimal_ascii3(input logic [9:0] value);
        logic [9:0] capped_value;
        logic [7:0] hundreds;
        logic [7:0] tens;
        logic [7:0] ones;
        begin
            capped_value = (value > 10'd999) ? 10'd999 : value;
            hundreds = 8'h30 + (capped_value / 10'd100);
            tens     = 8'h30 + ((capped_value % 10'd100) / 10'd10);
            ones     = 8'h30 + (capped_value % 10'd10);
            decimal_ascii3 = {hundreds, tens, ones};
        end
    endfunction

    logic [9:0] elapsed_display;
    logic [23:0] score_ascii;
    logic [23:0] remote_score_ascii;
    logic [23:0] target_ascii;
    logic [23:0] elapsed_ascii;
    logic [23:0] last_ascii;
    logic [23:0] best_ascii;

    assign elapsed_display = (elapsed_seconds > 16'd999)
                           ? 10'd999 : elapsed_seconds[9:0];
    assign score_ascii   = decimal_ascii3({2'b0, score});
    assign remote_score_ascii = decimal_ascii3({2'b0, remote_score});
    assign target_ascii  = decimal_ascii3({2'b0, target_value});
    assign elapsed_ascii = decimal_ascii3(elapsed_display);
    assign last_ascii    = decimal_ascii3({2'b0, last_stop_seconds});
    assign best_ascii    = decimal_ascii3({2'b0, best_stop_seconds});

    logic [LINE_BITS-1:0] line_text;

    always_comb begin
        line_text = {LINE_CHARS{8'h20}};

        case (text_row)
            3'd0: begin
                if (multiplayer)
                    line_text = {"MULTIPLAYER RESULT", {10{8'h20}}};
                else
                    line_text = {"PIT STOP RESULT", {13{8'h20}}};
            end

            3'd1: begin
                case (match_result)
                    RESULT_WIN:
                        line_text = {"RESULT   YOU WIN", {12{8'h20}}};
                    RESULT_DRAW:
                        line_text = {"RESULT   DRAW", {15{8'h20}}};
                    default:
                        line_text = {"RESULT   YOU LOSE", {11{8'h20}}};
                endcase
            end

            3'd2: begin
                case (game_mode)
                    2'b00: line_text = {"MODE     TIME ATTACK", {8{8'h20}}};
                    2'b01: line_text = {"MODE     POINT RACE", {9{8'h20}}};
                    2'b10: line_text = {"MODE     SPEED UP", {11{8'h20}}};
                    default: line_text = {"MODE     BEST OF", {12{8'h20}}};
                endcase
            end

            3'd3: begin
                if (multiplayer)
                    line_text = {"YOU      ", score_ascii,
                                 " PTS", {12{8'h20}}};
                else
                    line_text = {"SCORE    ", score_ascii,
                                 " PTS", {12{8'h20}}};
            end

            3'd4: begin
                if (multiplayer) begin
                    line_text = {"RIVAL    ", remote_score_ascii,
                                 " PTS", {12{8'h20}}};
                end else begin
                    case (game_mode)
                        2'b00, 2'b10:
                            line_text = {"TARGET   ", target_ascii,
                                         " SEC", {12{8'h20}}};
                        2'b01:
                            line_text = {"TARGET   ", target_ascii,
                                         " PTS", {12{8'h20}}};
                        default:
                            line_text = {"TARGET   ", target_ascii,
                                         " RUNS", {11{8'h20}}};
                    endcase
                end
            end

            3'd5:
                line_text = {"TIME     ", elapsed_ascii, " SEC", {12{8'h20}}};
            3'd6:
                line_text = {"LAST     ", last_ascii, " SEC", {12{8'h20}}};
            default:
                line_text = {"BEST     ", best_ascii, " SEC", {12{8'h20}}};
        endcase
    end

    logic [7:0] current_char_code;
    logic [3:0] text_color;

    always_comb begin
        current_char_code = 8'h20;
        if (in_text && (char_index < LINE_CHARS)) begin
            current_char_code =
                line_text[((LINE_CHARS - 1 - char_index) * 8) +: 8];
        end

        text_color = 4'h3;
        if (text_row == 3'd0)
            text_color = 4'h4;
        else if (text_row == 3'd1)
            case (match_result)
                RESULT_WIN:  text_color = 4'h7;
                RESULT_DRAW: text_color = 4'h4;
                default:     text_color = 4'h5;
            endcase
        else if ((text_row >= 3'd3) && (char_index >= 5'd9))
            text_color = 4'h7;
    end

    logic [9:0] font_addr;
    logic [7:0]  font_data;

    assign font_addr = in_text
                     ? {current_char_code[6:0], text_local_y}
                     : 10'b0;

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

    logic unused_low_res;
    assign unused_low_res = ^{low_res_in.hcount, low_res_in.vcount};

endmodule
