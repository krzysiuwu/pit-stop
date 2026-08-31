/**
 * Module: draw_game_panel
 * Summary: Shares one pipelined text renderer between the options, UART-waiting, and match-summary panels.
 * Author: Adam Krupa
 */
import vga_pkg::*;
import game_pkg::*;

module draw_game_panel (
    input  logic        clk,
    input  logic        rst,
    input  logic        options_enable,
    input  logic        summary_enable,

    input  logic        options_multiplayer,
    input  logic        uart_connected,
    input  logic        uart_peer_ready,
    input  logic        uart_test_mode,
    input  logic        waiting_for_uart,
    input  logic [1:0]  options_game_mode,
    input  logic [7:0]  options_target_value,

    input  logic        summary_multiplayer,
    input  logic [1:0]  match_result,
    input  logic [1:0]  summary_game_mode,
    input  logic [7:0]  summary_target_value,
    input  logic [7:0]  score,
    input  logic [7:0]  remote_score,
    input  logic [15:0] elapsed_seconds,
    input  logic [7:0]  last_stop_seconds,
    input  logic [7:0]  best_stop_seconds,

    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int PANEL_X = 6;
    localparam int PANEL_W = 244;
    localparam int TEXT_X = 16;
    localparam int LINE_CHARS = 28;
    localparam int LINE_BITS = LINE_CHARS * 8;

    logic [11:0] cur_x;
    logic [11:0] cur_y;
    logic        panel_enable;
    logic        summary_active;
    logic [11:0] panel_y;
    logic [11:0] panel_h;
    logic        in_panel;
    logic [3:0]  panel_color;

    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;
    assign summary_active = summary_enable;
    assign panel_enable = options_enable || summary_enable;
    assign panel_y = summary_active ? 12'd12 : 12'd25;
    assign panel_h = summary_active ? 12'd140 : 12'd153;
    assign in_panel = panel_enable &&
                      (cur_x >= PANEL_X) && (cur_x < PANEL_X + PANEL_W) &&
                      (cur_y >= panel_y) && (cur_y < panel_y + panel_h);

    always_comb begin
        panel_color = 4'h1;

        if ((cur_x == PANEL_X) || (cur_x == PANEL_X + PANEL_W - 1) ||
            (cur_y == panel_y) || (cur_y == panel_y + panel_h - 1)) begin
            panel_color = 4'h0;
        end else if ((cur_x == PANEL_X + 1) ||
                     (cur_x == PANEL_X + PANEL_W - 2) ||
                     (cur_y == panel_y + 1) ||
                     (cur_y == panel_y + panel_h - 2)) begin
            if (summary_active) begin
                case (match_result)
                    RESULT_WIN:  panel_color = 4'h7;
                    RESULT_DRAW: panel_color = 4'h4;
                    default:     panel_color = 4'h5;
                endcase
            end else begin
                panel_color = 4'h5;
            end
        end else if (summary_active &&
                     ((cur_y == 12'd45) || (cur_y == 12'd61))) begin
            panel_color = 4'h6;
        end else if (!summary_active &&
                     ((cur_y == 12'd42) || (cur_y == 12'd76) ||
                      (cur_y == 12'd113))) begin
            panel_color = 4'h6;
        end
    end

    logic       in_text;
    logic [2:0] text_row;
    logic [2:0] text_local_y;
    logic [7:0] text_local_x;
    logic [4:0] char_index;

    always_comb begin
        in_text = 1'b0;
        text_row = 3'd0;
        text_local_y = 3'd0;

        if (panel_enable && (cur_x >= TEXT_X) &&
            (cur_x < TEXT_X + LINE_CHARS * 8)) begin
            if (summary_active) begin
                if ((cur_y >= 12'd18) && (cur_y < 12'd26)) begin
                    in_text = 1'b1; text_row = 3'd0;
                    text_local_y = cur_y - 12'd18;
                end else if ((cur_y >= 12'd34) && (cur_y < 12'd42)) begin
                    in_text = 1'b1; text_row = 3'd1;
                    text_local_y = cur_y - 12'd34;
                end else if ((cur_y >= 12'd50) && (cur_y < 12'd58)) begin
                    in_text = 1'b1; text_row = 3'd2;
                    text_local_y = cur_y - 12'd50;
                end else if ((cur_y >= 12'd66) && (cur_y < 12'd74)) begin
                    in_text = 1'b1; text_row = 3'd3;
                    text_local_y = cur_y - 12'd66;
                end else if ((cur_y >= 12'd82) && (cur_y < 12'd90)) begin
                    in_text = 1'b1; text_row = 3'd4;
                    text_local_y = cur_y - 12'd82;
                end else if ((cur_y >= 12'd98) && (cur_y < 12'd106)) begin
                    in_text = 1'b1; text_row = 3'd5;
                    text_local_y = cur_y - 12'd98;
                end else if ((cur_y >= 12'd114) && (cur_y < 12'd122)) begin
                    in_text = 1'b1; text_row = 3'd6;
                    text_local_y = cur_y - 12'd114;
                end else if ((cur_y >= 12'd130) && (cur_y < 12'd138)) begin
                    in_text = 1'b1; text_row = 3'd7;
                    text_local_y = cur_y - 12'd130;
                end
            end else begin
                if ((cur_y >= 12'd31) && (cur_y < 12'd39)) begin
                    in_text = 1'b1; text_row = 3'd0;
                    text_local_y = cur_y - 12'd31;
                end else if ((cur_y >= 12'd49) && (cur_y < 12'd57)) begin
                    in_text = 1'b1; text_row = 3'd1;
                    text_local_y = cur_y - 12'd49;
                end else if ((cur_y >= 12'd65) && (cur_y < 12'd73)) begin
                    in_text = 1'b1; text_row = 3'd2;
                    text_local_y = cur_y - 12'd65;
                end else if ((cur_y >= 12'd83) && (cur_y < 12'd91)) begin
                    in_text = 1'b1; text_row = 3'd3;
                    text_local_y = cur_y - 12'd83;
                end else if ((cur_y >= 12'd99) && (cur_y < 12'd107)) begin
                    in_text = 1'b1; text_row = 3'd4;
                    text_local_y = cur_y - 12'd99;
                end else if ((cur_y >= 12'd120) && (cur_y < 12'd128)) begin
                    in_text = 1'b1; text_row = 3'd5;
                    text_local_y = cur_y - 12'd120;
                end else if ((cur_y >= 12'd136) && (cur_y < 12'd144)) begin
                    in_text = 1'b1; text_row = 3'd6;
                    text_local_y = cur_y - 12'd136;
                end else if ((cur_y >= 12'd152) && (cur_y < 12'd160)) begin
                    in_text = 1'b1; text_row = 3'd7;
                    text_local_y = cur_y - 12'd152;
                end
            end
        end
    end

    assign text_local_x = cur_x[7:0] - TEXT_X;
    assign char_index = text_local_x[7:3];

    logic [9:0] selected_number;
    logic [9:0] selected_number_d1;
    logic [3:0] selected_hundreds;
    logic [3:0] selected_tens;
    logic [3:0] selected_ones;
    logic [23:0] selected_ascii_comb;
    logic [23:0] selected_ascii_d2;

    always_comb begin
        selected_number = {2'b0, options_target_value};

        if (summary_active) begin
            case (text_row)
                3'd3: selected_number = {2'b0, score};
                3'd4: selected_number = summary_multiplayer
                                      ? {2'b0, remote_score}
                                      : {2'b0, summary_target_value};
                3'd5: selected_number = (elapsed_seconds > 16'd999)
                                      ? 10'd999 : elapsed_seconds[9:0];
                3'd6: selected_number = {2'b0, last_stop_seconds};
                default: selected_number = {2'b0, best_stop_seconds};
            endcase
        end else if ((text_row == 3'd7) &&
                     (char_index >= 5'd11) && (char_index <= 5'd13)) begin
            // Only one character is rendered per pixel. Select the remote
            // value while scanning its three digit positions so both fields
            // can share this single BCD converter.
            selected_number = {2'b0, remote_score};
        end
    end

    bin_to_bcd3 u_selected_bcd (
        .binary(selected_number_d1),
        .hundreds(selected_hundreds),
        .tens(selected_tens),
        .ones(selected_ones)
    );

    assign selected_ascii_comb = {{4'h3, selected_hundreds},
                                  {4'h3, selected_tens},
                                  {4'h3, selected_ones}};

    // The BCD conversion and the 28-character line selector used to form one
    // long combinational path into the synchronous font ROM.  Pipeline the
    // slowly changing number first, then build the character for the matching
    // pixel two clocks later.  This keeps the 65 MHz video path comfortably
    // below one clock period without duplicating the font ROM.
    logic       summary_active_d1, summary_active_d2;
    logic       options_multiplayer_d1, options_multiplayer_d2;
    logic       uart_connected_d1, uart_connected_d2;
    logic       uart_peer_ready_d1, uart_peer_ready_d2;
    logic       uart_test_mode_d1, uart_test_mode_d2;
    logic       waiting_for_uart_d1, waiting_for_uart_d2;
    logic [1:0] options_game_mode_d1, options_game_mode_d2;
    logic       summary_multiplayer_d1, summary_multiplayer_d2;
    logic [1:0] match_result_d1, match_result_d2;
    logic [1:0] summary_game_mode_d1, summary_game_mode_d2;
    logic [2:0] text_row_d1, text_row_d2;
    logic [2:0] text_local_y_d1, text_local_y_d2;
    logic [4:0] char_index_d1, char_index_d2;
    logic [2:0] pixel_x_d1, pixel_x_d2;
    logic       in_panel_d1, in_panel_d2;
    logic       in_text_d1, in_text_d2;
    logic [3:0] panel_color_d1, panel_color_d2;
    logic [3:0] lut_in_d1, lut_in_d2;
    logic [10:0] vcount_d1, vcount_d2;
    logic        vsync_d1, vsync_d2;
    logic [10:0] hcount_d1, hcount_d2;
    logic        hsync_d1, hsync_d2;
    logic        vblnk_d1, vblnk_d2;
    logic        hblnk_d1, hblnk_d2;

    always_ff @(posedge clk) begin
        if (!rst) begin
            selected_number_d1    <= 10'd0;
            selected_ascii_d2     <= 24'h303030;
            summary_active_d1     <= 1'b0;
            summary_active_d2     <= 1'b0;
            options_multiplayer_d1 <= 1'b0;
            options_multiplayer_d2 <= 1'b0;
            uart_connected_d1     <= 1'b0;
            uart_connected_d2     <= 1'b0;
            uart_peer_ready_d1    <= 1'b0;
            uart_peer_ready_d2    <= 1'b0;
            uart_test_mode_d1     <= 1'b0;
            uart_test_mode_d2     <= 1'b0;
            waiting_for_uart_d1   <= 1'b0;
            waiting_for_uart_d2   <= 1'b0;
            options_game_mode_d1  <= 2'd0;
            options_game_mode_d2  <= 2'd0;
            summary_multiplayer_d1 <= 1'b0;
            summary_multiplayer_d2 <= 1'b0;
            match_result_d1       <= 2'd0;
            match_result_d2       <= 2'd0;
            summary_game_mode_d1  <= 2'd0;
            summary_game_mode_d2  <= 2'd0;
            text_row_d1           <= 3'd0;
            text_row_d2           <= 3'd0;
            text_local_y_d1       <= 3'd0;
            text_local_y_d2       <= 3'd0;
            char_index_d1         <= 5'd0;
            char_index_d2         <= 5'd0;
            pixel_x_d1            <= 3'd0;
            pixel_x_d2            <= 3'd0;
            in_panel_d1           <= 1'b0;
            in_panel_d2           <= 1'b0;
            in_text_d1            <= 1'b0;
            in_text_d2            <= 1'b0;
            panel_color_d1        <= 4'd0;
            panel_color_d2        <= 4'd0;
            lut_in_d1             <= 4'd0;
            lut_in_d2             <= 4'd0;
            vcount_d1             <= '0;
            vcount_d2             <= '0;
            vsync_d1              <= 1'b0;
            vsync_d2              <= 1'b0;
            hcount_d1             <= '0;
            hcount_d2             <= '0;
            hsync_d1              <= 1'b0;
            hsync_d2              <= 1'b0;
            vblnk_d1              <= 1'b0;
            vblnk_d2              <= 1'b0;
            hblnk_d1              <= 1'b0;
            hblnk_d2              <= 1'b0;
        end else begin
            selected_number_d1     <= selected_number;
            selected_ascii_d2      <= selected_ascii_comb;
            summary_active_d1      <= summary_active;
            summary_active_d2      <= summary_active_d1;
            options_multiplayer_d1 <= options_multiplayer;
            options_multiplayer_d2 <= options_multiplayer_d1;
            uart_connected_d1      <= uart_connected;
            uart_connected_d2      <= uart_connected_d1;
            uart_peer_ready_d1     <= uart_peer_ready;
            uart_peer_ready_d2     <= uart_peer_ready_d1;
            uart_test_mode_d1      <= uart_test_mode;
            uart_test_mode_d2      <= uart_test_mode_d1;
            waiting_for_uart_d1    <= waiting_for_uart;
            waiting_for_uart_d2    <= waiting_for_uart_d1;
            options_game_mode_d1   <= options_game_mode;
            options_game_mode_d2   <= options_game_mode_d1;
            summary_multiplayer_d1 <= summary_multiplayer;
            summary_multiplayer_d2 <= summary_multiplayer_d1;
            match_result_d1        <= match_result;
            match_result_d2        <= match_result_d1;
            summary_game_mode_d1   <= summary_game_mode;
            summary_game_mode_d2   <= summary_game_mode_d1;
            text_row_d1            <= text_row;
            text_row_d2            <= text_row_d1;
            text_local_y_d1        <= text_local_y;
            text_local_y_d2        <= text_local_y_d1;
            char_index_d1          <= char_index;
            char_index_d2          <= char_index_d1;
            pixel_x_d1             <= text_local_x[2:0];
            pixel_x_d2             <= pixel_x_d1;
            in_panel_d1            <= in_panel;
            in_panel_d2            <= in_panel_d1;
            in_text_d1             <= in_text;
            in_text_d2             <= in_text_d1;
            panel_color_d1         <= panel_color;
            panel_color_d2         <= panel_color_d1;
            lut_in_d1              <= lut_in;
            lut_in_d2              <= lut_in_d1;
            vcount_d1              <= vga_in.vcount;
            vcount_d2              <= vcount_d1;
            vsync_d1               <= vga_in.vsync;
            vsync_d2               <= vsync_d1;
            hcount_d1              <= vga_in.hcount;
            hcount_d2              <= hcount_d1;
            hsync_d1               <= vga_in.hsync;
            hsync_d2               <= hsync_d1;
            vblnk_d1               <= vga_in.vblnk;
            vblnk_d2               <= vblnk_d1;
            hblnk_d1               <= vga_in.hblnk;
            hblnk_d2               <= hblnk_d1;
        end
    end

    logic [LINE_BITS-1:0] line_text;

    always_comb begin
        line_text = {LINE_CHARS{8'h20}};

        if (summary_active_d2) begin
            case (text_row_d2)
                3'd0: begin
                    if (summary_multiplayer_d2)
                        line_text = {"MULTIPLAYER RESULT", {10{8'h20}}};
                    else
                        line_text = {"PIT STOP RESULT", {13{8'h20}}};
                end
                3'd1: begin
                    case (match_result_d2)
                        RESULT_WIN:  line_text = {"RESULT   YOU WIN", {12{8'h20}}};
                        RESULT_DRAW: line_text = {"RESULT   DRAW", {15{8'h20}}};
                        default:     line_text = {"RESULT   YOU LOSE", {11{8'h20}}};
                    endcase
                end
                3'd2: begin
                    case (summary_game_mode_d2)
                        2'b00: line_text = {"MODE     TIME ATTACK", {8{8'h20}}};
                        2'b01: line_text = {"MODE     POINT RACE", {9{8'h20}}};
                        2'b10: line_text = {"MODE     SPEED UP", {11{8'h20}}};
                        default: line_text = {"MODE     BEST OF", {12{8'h20}}};
                    endcase
                end
                3'd3: begin
                    if (summary_multiplayer_d2)
                        line_text = {"YOU      ", selected_ascii_d2,
                                     " PTS", {12{8'h20}}};
                    else
                        line_text = {"SCORE    ", selected_ascii_d2,
                                     " PTS", {12{8'h20}}};
                end
                3'd4: begin
                    if (summary_multiplayer_d2) begin
                        line_text = {"RIVAL    ", selected_ascii_d2,
                                     " PTS", {12{8'h20}}};
                    end else begin
                        case (summary_game_mode_d2)
                            2'b00, 2'b10:
                                line_text = {"TARGET   ", selected_ascii_d2,
                                             " SEC", {12{8'h20}}};
                            2'b01:
                                line_text = {"TARGET   ", selected_ascii_d2,
                                             " PTS", {12{8'h20}}};
                            default:
                                line_text = {"TARGET   ", selected_ascii_d2,
                                             " RUNS", {11{8'h20}}};
                        endcase
                    end
                end
                3'd5: line_text = {"TIME     ", selected_ascii_d2,
                                   " SEC", {12{8'h20}}};
                3'd6: line_text = {"LAST     ", selected_ascii_d2,
                                   " SEC", {12{8'h20}}};
                default: line_text = {"BEST     ", selected_ascii_d2,
                                      " SEC", {12{8'h20}}};
            endcase
        end else begin
            case (text_row_d2)
                3'd0: begin
                    if (waiting_for_uart_d2)
                        line_text = {"WAITING FOR UART LINK", {7{8'h20}}};
                    else
                        line_text = {"OPTIONS", {21{8'h20}}};
                end
                3'd1: begin
                    if (options_multiplayer_d2)
                        line_text = {"PLAYER   MULTIPLAYER", {8{8'h20}}};
                    else
                        line_text = {"PLAYER   SINGLE", {13{8'h20}}};
                end
                3'd2: begin
                    if (options_multiplayer_d2) begin
                        if (uart_peer_ready_d2)
                            line_text = {"UART     CONNECTED", {10{8'h20}}};
                        else if (uart_connected_d2)
                            line_text = {"UART     PEER NOT READY", {5{8'h20}}};
                        else
                            line_text = {"UART     OFFLINE", {12{8'h20}}};
                    end else if (uart_test_mode_d2) begin
                        if (uart_connected_d2)
                            line_text = {"UART     CONNECTED", {10{8'h20}}};
                        else
                            line_text = {"UART     OFFLINE", {12{8'h20}}};
                    end else begin
                        line_text = {"UART     NOT USED", {11{8'h20}}};
                    end
                end
                3'd3: begin
                    case (options_game_mode_d2)
                        2'b00: line_text = {"MODE     TIME ATTACK", {8{8'h20}}};
                        2'b01: line_text = {"MODE     POINT RACE", {9{8'h20}}};
                        2'b10: line_text = {"MODE     SPEED UP", {11{8'h20}}};
                        default: line_text = {"MODE     BEST OF", {12{8'h20}}};
                    endcase
                end
                3'd4: begin
                    case (options_game_mode_d2)
                        2'b00, 2'b10:
                            line_text = {"TARGET   ", selected_ascii_d2,
                                         " SEC", {12{8'h20}}};
                        2'b01:
                            line_text = {"TARGET   ", selected_ascii_d2,
                                         " PTS", {12{8'h20}}};
                        default:
                            line_text = {"TARGET   ", selected_ascii_d2,
                                         " RUNS", {11{8'h20}}};
                    endcase
                end
                3'd5: begin
                    case (options_game_mode_d2)
                        2'b00: line_text = {"GOAL     SCORE AT LEAST 1", {3{8'h20}}};
                        2'b01: line_text = {"GOAL     REACH TARGET", {7{8'h20}}};
                        2'b10: line_text = {"GOAL     SURVIVE 5 RUNS", {5{8'h20}}};
                        default: line_text = {"GOAL     FINISH ALL RUNS", {4{8'h20}}};
                    endcase
                end
                3'd6: begin
                    if (uart_test_mode_d2)
                        line_text = {"BTNU FINISHES TEST", {10{8'h20}}};
                    else
                        line_text = {"UART 115200 8N1", {13{8'h20}}};
                end
                default: begin
                    if (uart_test_mode_d2)
                        line_text = {"TX ", selected_ascii_d2, "  RX ",
                                     selected_ascii_d2, "  7SEG RX", {5{8'h20}}};
                    else
                        line_text = {"SW12 ENABLES UART TEST", {6{8'h20}}};
                end
            endcase
        end
    end

    logic [7:0] current_char;
    logic [3:0] text_color;

    always_comb begin
        current_char = 8'h20;
        if (in_text_d2 && (char_index_d2 < LINE_CHARS))
            current_char = line_text[((LINE_CHARS - 1 - char_index_d2) * 8) +: 8];

        text_color = 4'h3;
        if (text_row_d2 == 3'd0) begin
            text_color = 4'h4;
        end else if (summary_active_d2) begin
            if (text_row_d2 == 3'd1) begin
                case (match_result_d2)
                    RESULT_WIN:  text_color = 4'h7;
                    RESULT_DRAW: text_color = 4'h4;
                    default:     text_color = 4'h5;
                endcase
            end else if ((text_row_d2 >= 3'd3) && (char_index_d2 >= 5'd9)) begin
                text_color = 4'h7;
            end
        end else begin
            if ((text_row_d2 == 3'd1) && (char_index_d2 >= 5'd9))
                text_color = 4'h7;
            else if ((text_row_d2 == 3'd2) && (char_index_d2 >= 5'd9))
                text_color = ((options_multiplayer_d2 && uart_peer_ready_d2) ||
                              (uart_test_mode_d2 && uart_connected_d2))
                           ? 4'h7
                           : ((options_multiplayer_d2 || uart_test_mode_d2)
                              ? 4'h5 : 4'h3);
            else if (((text_row_d2 == 3'd3) || (text_row_d2 == 3'd4) ||
                      (text_row_d2 == 3'd5)) && (char_index_d2 >= 5'd9))
                text_color = 4'h7;
            else if (text_row_d2 >= 3'd6)
                text_color = uart_test_mode_d2 ? 4'h7 : 4'h3;
        end
    end

    logic [9:0] font_address;
    logic [7:0] font_data;

    assign font_address = in_text_d2
                        ? {current_char[6:0], text_local_y_d2}
                        : 10'd0;

    Font_Rom u_font_rom (
        .clk(clk),
        .address(font_address),
        .data_out(font_data)
    );

    logic       in_panel_d;
    logic       in_text_d;
    logic [2:0] pixel_x_d;
    logic [3:0] panel_color_d;
    logic [3:0] text_color_d;
    logic [3:0] lut_in_d;
    logic       text_pixel;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_panel_d     <= 1'b0;
            in_text_d      <= 1'b0;
            pixel_x_d      <= 3'd0;
            panel_color_d  <= 4'd0;
            text_color_d   <= 4'd0;
            lut_in_d       <= 4'd0;
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
        end else begin
            in_panel_d     <= in_panel_d2;
            in_text_d      <= in_text_d2;
            pixel_x_d      <= pixel_x_d2;
            panel_color_d  <= panel_color_d2;
            text_color_d   <= text_color;
            lut_in_d       <= lut_in_d2;
            vga_out.vcount <= vcount_d2;
            vga_out.vsync  <= vsync_d2;
            vga_out.hcount <= hcount_d2;
            vga_out.hsync  <= hsync_d2;
            vga_out.vblnk  <= vblnk_d2;
            vga_out.hblnk  <= hblnk_d2;
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

endmodule
