/**
 * Module: game_ui_control
 * Summary: Selects the back-button layout, cursor icon, and seven-segment value for the active screen.
 * Author: Adam Krupa
 */
import game_pkg::*;

module game_ui_control #(
    parameter logic [11:0] BACK_OPTIONS_X = 12'd140,
    parameter logic [11:0] BACK_OPTIONS_Y = 12'd5,
    parameter logic [11:0] BACK_SUMMARY_X = 12'd89,
    parameter logic [11:0] BACK_SUMMARY_Y = 12'd158
)(
    input  logic [2:0] system_screen,
    input  logic       uart_test_mode,
    input  logic [7:0] uart_remote_score,
    input  logic [7:0] summary_local_score,
    input  logic [7:0] game_display_value,
    input  logic [7:0] option_target_value,

    input  logic front_hover,
    input  logic rear_hover,
    input  logic front_locked,
    input  logic rear_locked,
    input  logic front_service_done,
    input  logic rear_service_done,
    input  logic front_grab_enable,
    input  logic rear_grab_enable,
    input  logic rack_hover,
    input  logic front_needs_new,
    input  logic rear_needs_new,
    input  logic play_hover,
    input  logic options_hover,
    input  logic back_hover,

    output logic [11:0] back_button_x,
    output logic [11:0] back_button_y,
    output logic [1:0]  cursor_type,
    output logic [7:0]  seven_segment_value
);

    timeunit 1ns;
    timeprecision 1ps;

    always_comb begin
        if (system_screen == SCREEN_SUMMARY) begin
            back_button_x = BACK_SUMMARY_X;
            back_button_y = BACK_SUMMARY_Y;
        end else begin
            back_button_x = BACK_OPTIONS_X;
            back_button_y = BACK_OPTIONS_Y;
        end
    end

    always_comb begin
        if ((front_hover && front_locked && !front_service_done) ||
            (rear_hover && rear_locked && !rear_service_done))
            cursor_type = 2'b10;
        else if ((front_hover && front_grab_enable) ||
                 (rear_hover && rear_grab_enable) ||
                 (rack_hover && (front_needs_new || rear_needs_new)) ||
                 play_hover || options_hover || back_hover)
            cursor_type = 2'b01;
        else
            cursor_type = 2'b00;
    end

    always_comb begin
        if (uart_test_mode &&
            (system_screen != SCREEN_GAMEPLAY) &&
            (system_screen != SCREEN_SUMMARY))
            seven_segment_value = uart_remote_score;
        else if (system_screen == SCREEN_SUMMARY)
            seven_segment_value = summary_local_score;
        else if (system_screen == SCREEN_GAMEPLAY)
            seven_segment_value = game_display_value;
        else
            seven_segment_value = option_target_value;
    end

endmodule
