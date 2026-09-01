/**
 * Module: system_fsm
 * Summary: Controls menu navigation and the complete car arrival, service, departure, and summary-screen sequence.
 * Author: Adam Krupa
 */
import game_pkg::*;

module system_fsm (
        input  logic clk,
        input  logic rst,

        input  logic click_play,
        input  logic click_setup,
        input  logic click_back,
        input  logic frame_tick,
        input  logic multiplayer_selected,
        input  logic multiplayer_ready,
        input  logic remote_start,

        input  logic front_wheel_done,
        input  logic rear_wheel_done,
        input  logic game_finishing,
        input  logic game_finished,
        input  logic bolid_arrive_done,
        input  logic bolid_depart_done,
        input  logic bolid_visible,

        output logic [2:0] state_out,

        output logic enable_bolid_default,
        output logic enable_bolid_no_wheels,
        output logic enable_button_play,
        output logic enable_button_options,
        output logic enable_button_back,
        output logic enable_wheel_rack,
        output logic enable_wheel_service,
        output logic game_start_pulse,
        output logic trigger_bolid_arrive,
        output logic trigger_bolid_depart,
        output logic trigger_bolid_drive_through
    );

    timeunit 1ns;
    timeprecision 1ps;

    // Sequence states are independent of screen identifiers. This keeps
    // the renderer interface simple while the complete round flow remains
    // outside the top-level module.
    typedef enum logic [3:0] {
        MENU_BOOT,
        MAIN_MENU,
        OPTIONS,
        WAITING_UART,
        GAME_SESSION_START,
        GAME_ARRIVE_START,
        GAME_ARRIVING,
        GAME_SERVICE,
        GAME_DEPART_START,
        GAME_DEPARTING,
        WAITING_RESULT,
        SUMMARY
    } system_state_t;

    system_state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!rst)
            state <= MENU_BOOT;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            MENU_BOOT: begin
                next_state = MAIN_MENU;
            end

            MAIN_MENU: begin
                if (remote_start)
                    next_state = GAME_SESSION_START;
                else if (click_play) begin
                    if (multiplayer_selected && !multiplayer_ready)
                        next_state = WAITING_UART;
                    else
                        next_state = GAME_SESSION_START;
                end
                else if (click_setup)
                    next_state = OPTIONS;
            end

            OPTIONS: begin
                if (remote_start)
                    next_state = GAME_SESSION_START;
                else if (click_back)
                    next_state = MAIN_MENU;
            end

            WAITING_UART: begin
                if (remote_start || multiplayer_ready)
                    next_state = GAME_SESSION_START;
                else if (click_back || !multiplayer_selected)
                    next_state = MAIN_MENU;
            end

            GAME_SESSION_START: begin
                next_state = GAME_ARRIVE_START;
            end

            GAME_ARRIVE_START: begin
                next_state = GAME_ARRIVING;
            end

            GAME_ARRIVING: begin
                if (game_finished)
                    next_state = SUMMARY;
                else if (game_finishing)
                    next_state = WAITING_RESULT;
                else if (bolid_arrive_done)
                    next_state = GAME_SERVICE;
            end

            GAME_SERVICE: begin
                if (game_finished)
                    next_state = SUMMARY;
                else if (game_finishing)
                    next_state = WAITING_RESULT;
                else if (front_wheel_done && rear_wheel_done)
                    next_state = GAME_DEPART_START;
            end

            GAME_DEPART_START: begin
                next_state = GAME_DEPARTING;
            end

            GAME_DEPARTING: begin
                if (bolid_depart_done) begin
                    if (game_finished)
                        next_state = SUMMARY;
                    else if (game_finishing)
                        next_state = WAITING_RESULT;
                    else
                        next_state = GAME_ARRIVE_START;
                end
            end

            WAITING_RESULT: begin
                if (game_finished)
                    next_state = SUMMARY;
            end

            SUMMARY: begin
                if (remote_start)
                    next_state = GAME_SESSION_START;
                else if (click_back)
                    next_state = MENU_BOOT;
            end

            default: begin
                next_state = MENU_BOOT;
            end
        endcase
    end

    always_comb begin
        trigger_bolid_arrive        = 1'b0;
        trigger_bolid_depart        = 1'b0;
        trigger_bolid_drive_through = 1'b0;

        state_out               = SCREEN_MAIN_MENU;
        enable_bolid_default    = 1'b0;
        enable_bolid_no_wheels  = 1'b0;
        enable_button_play      = 1'b0;
        enable_button_options   = 1'b0;
        enable_button_back      = 1'b0;
        enable_wheel_rack       = 1'b0;
        enable_wheel_service    = 1'b0;
        game_start_pulse        = 1'b0;

        case (state)
            MENU_BOOT: begin
                state_out             = SCREEN_MAIN_MENU;
                enable_button_play    = 1'b1;
                enable_button_options = 1'b1;
                trigger_bolid_drive_through = 1'b1;
            end

            MAIN_MENU: begin
                state_out             = SCREEN_MAIN_MENU;
                enable_bolid_default  = bolid_visible;
                enable_button_play    = 1'b1;
                enable_button_options = 1'b1;

                // bolid_depart_done remains asserted until a new command is accepted,
                // so one condition is enough to restart the menu animation seamlessly.
                if (bolid_depart_done)
                    trigger_bolid_drive_through = 1'b1;
            end

            OPTIONS: begin
                state_out            = SCREEN_OPTIONS;
                enable_bolid_default = bolid_visible;
                enable_button_back   = 1'b1;

                if (bolid_depart_done)
                    trigger_bolid_drive_through = 1'b1;
            end

            WAITING_UART: begin
                state_out          = SCREEN_WAIT_UART;
                enable_button_back = 1'b1;
            end

            GAME_SESSION_START: begin
                state_out            = SCREEN_GAMEPLAY;
                game_start_pulse     = 1'b1;
            end

            GAME_ARRIVE_START: begin
                state_out            = SCREEN_GAMEPLAY;
                trigger_bolid_arrive = 1'b1;
            end

            GAME_ARRIVING: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_bolid_default = bolid_visible;
            end

            GAME_SERVICE: begin
                state_out              = SCREEN_GAMEPLAY;
                enable_bolid_no_wheels = 1'b1;
                enable_wheel_rack      = 1'b1;
                enable_wheel_service   = 1'b1;
            end

            GAME_DEPART_START: begin
                state_out            = SCREEN_GAMEPLAY;
                trigger_bolid_depart = 1'b1;
            end

            GAME_DEPARTING: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_bolid_default = bolid_visible;
            end

            WAITING_RESULT: begin
                state_out = SCREEN_GAMEPLAY;
            end

            SUMMARY: begin
                state_out          = SCREEN_SUMMARY;
                enable_button_back = 1'b1;
            end

            default: begin
                state_out = SCREEN_MAIN_MENU;
            end
        endcase
    end

endmodule
