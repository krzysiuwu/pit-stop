/**
 * Module: multiplayer_session_control
 * Summary: Captures local or remote game settings and latches the hardware diagnostic finish request.
 * Author: Adam Krupa
 */
import game_pkg::*;

module multiplayer_session_control (
    input  logic       clk,
    input  logic       rst,

    input  logic       play_clicked,
    input  logic       local_multiplayer,
    input  logic [1:0] local_game_mode,
    input  logic [7:0] local_target_value,

    input  logic       remote_start_pulse,
    input  logic [1:0] remote_game_mode,
    input  logic [7:0] remote_target_value,

    input  logic       game_start_pulse,
    input  logic       session_reset,
    input  logic       uart_test_mode,
    input  logic       uart_debug_finish,

    output logic       active_multiplayer,
    output logic       pending_multiplayer,
    output logic       pending_start_remote,
    output logic [1:0] pending_game_mode,
    output logic [7:0] pending_target_value,
    output logic       debug_finish_latched
);

    timeunit 1ns;
    timeprecision 1ps;

    (* ASYNC_REG = "TRUE" *) logic debug_finish_meta;
    (* ASYNC_REG = "TRUE" *) logic debug_finish_sync;

    // BTNU is asynchronous to the game clock. Synchronize it before latching
    // the diagnostic finish request into periodically transmitted UART frames.
    always_ff @(posedge clk) begin
        if (!rst) begin
            debug_finish_meta <= 1'b0;
            debug_finish_sync <= 1'b0;
        end else begin
            debug_finish_meta <= uart_debug_finish;
            debug_finish_sync <= debug_finish_meta;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst)
            debug_finish_latched <= 1'b0;
        else if (game_start_pulse || session_reset)
            debug_finish_latched <= 1'b0;
        else if (uart_test_mode && debug_finish_sync)
            debug_finish_latched <= 1'b1;
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            active_multiplayer   <= 1'b0;
            pending_multiplayer  <= 1'b0;
            pending_start_remote <= 1'b0;
            pending_game_mode    <= MODE_TIME_ATTACK;
            pending_target_value <= 8'd1;
        end else begin
            if (play_clicked) begin
                pending_multiplayer  <= local_multiplayer;
                pending_start_remote <= 1'b0;
                pending_game_mode    <= local_game_mode;
                pending_target_value <= local_target_value;
            end

            // A received start request overrides locally sampled settings so
            // the board that starts the session defines the shared game.
            if (remote_start_pulse) begin
                pending_multiplayer  <= 1'b1;
                pending_start_remote <= 1'b1;
                pending_game_mode    <= remote_game_mode;
                pending_target_value <= remote_target_value;
            end

            if (game_start_pulse)
                active_multiplayer <= pending_multiplayer;

            if (session_reset)
                active_multiplayer <= 1'b0;
        end
    end

endmodule
