/**
 * Module: singleplayer_game_controller
 * Summary: Tracks rounds, score, timers, pit-stop statistics, and end conditions for every game mode.
 * Author: Adam Krupa
 */
import game_pkg::*;

module singleplayer_game_controller #(
    parameter int FRAMES_PER_SECOND = 60,
    parameter int SPEED_UP_ROUNDS   = 5
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       frame_tick,
    input  logic       start_game,
    input  logic       service_active,
    input  logic       round_complete,
    input  logic [1:0] selected_game_mode,
    input  logic [7:0] selected_target_value,

    output logic       game_running,
    output logic       game_finished,
    output logic       player_won,
    output logic [1:0] active_game_mode,
    output logic [7:0] active_target_value,
    output logic [7:0] score,
    output logic [7:0] display_value,
    output logic [7:0] remaining_seconds,
    output logic [15:0] elapsed_seconds,
    output logic [7:0] last_stop_seconds,
    output logic [7:0] best_stop_seconds
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int FRAME_COUNTER_WIDTH =
        (FRAMES_PER_SECOND <= 1) ? 1 : $clog2(FRAMES_PER_SECOND);
    localparam logic [7:0] SPEED_UP_TARGET = SPEED_UP_ROUNDS;

    logic [FRAME_COUNTER_WIDTH-1:0] game_frame_counter;
    logic [FRAME_COUNTER_WIDTH-1:0] service_frame_counter;
    logic [7:0] current_stop_seconds;
    logic [7:0] speed_up_limit;
    logic       service_active_d;
    logic       round_complete_d;
    logic       round_complete_pulse;
    logic [7:0] completed_stop_seconds;

    assign round_complete_pulse = round_complete && !round_complete_d;

    // Round a partial second up so an exceptionally fast
    // pit stop is never reported as zero seconds.
    always_comb begin
        completed_stop_seconds = current_stop_seconds;
        if (service_frame_counter != 0) begin
            if (current_stop_seconds != 8'hff)
                completed_stop_seconds = current_stop_seconds + 1'b1;
        end
    end

    always_comb begin
        case (active_game_mode)
            MODE_TIME_ATTACK,
            MODE_SPEED_UP:   display_value = remaining_seconds;
            default:         display_value = score;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            game_running          <= 1'b0;
            game_finished         <= 1'b0;
            player_won            <= 1'b0;
            active_game_mode      <= MODE_TIME_ATTACK;
            active_target_value   <= 8'd1;
            score                 <= 8'd0;
            remaining_seconds     <= 8'd0;
            elapsed_seconds       <= 16'd0;
            last_stop_seconds     <= 8'd0;
            best_stop_seconds     <= 8'd0;
            game_frame_counter    <= '0;
            service_frame_counter <= '0;
            current_stop_seconds  <= 8'd0;
            speed_up_limit        <= 8'd1;
            service_active_d      <= 1'b0;
            round_complete_d      <= 1'b0;
        end else begin
            service_active_d <= service_active;
            round_complete_d <= round_complete;

            if (start_game) begin
                game_running          <= 1'b1;
                game_finished         <= 1'b0;
                player_won            <= 1'b0;
                active_game_mode      <= selected_game_mode;
                active_target_value   <= selected_target_value;
                score                 <= 8'd0;
                remaining_seconds     <= selected_target_value;
                elapsed_seconds       <= 16'd0;
                last_stop_seconds     <= 8'd0;
                best_stop_seconds     <= 8'd0;
                game_frame_counter    <= '0;
                service_frame_counter <= '0;
                current_stop_seconds  <= 8'd0;
                speed_up_limit        <= selected_target_value;
                round_complete_d      <= 1'b0;
            end else if (game_running) begin
                // Track total match time and the main TIME ATTACK countdown.
                if (frame_tick) begin
                    if (game_frame_counter == FRAMES_PER_SECOND - 1) begin
                        game_frame_counter <= '0;
                        if (elapsed_seconds != 16'hffff)
                            elapsed_seconds <= elapsed_seconds + 1'b1;

                        if (active_game_mode == MODE_TIME_ATTACK) begin
                            if (remaining_seconds > 8'd1) begin
                                remaining_seconds <= remaining_seconds - 1'b1;
                            end else begin
                                remaining_seconds <= 8'd0;
                                game_running      <= 1'b0;
                                game_finished     <= 1'b1;
                                player_won        <= (score != 0) ||
                                                     round_complete_pulse;
                            end
                        end
                    end else begin
                        game_frame_counter <= game_frame_counter + 1'b1;
                    end
                end

                // Each arriving car starts a separate pit-stop measurement.
                if (service_active && !service_active_d) begin
                    service_frame_counter <= '0;
                    current_stop_seconds  <= 8'd0;
                    if (active_game_mode == MODE_SPEED_UP)
                        remaining_seconds <= speed_up_limit;
                end else if (service_active && frame_tick) begin
                    if (service_frame_counter == FRAMES_PER_SECOND - 1) begin
                        service_frame_counter <= '0;
                        if (current_stop_seconds != 8'hff)
                            current_stop_seconds <= current_stop_seconds + 1'b1;

                        // Completing a round on the final frame takes priority
                        // over losing because the time limit expired.
                        if ((active_game_mode == MODE_SPEED_UP) &&
                            !round_complete_pulse) begin
                            if (remaining_seconds > 8'd1) begin
                                remaining_seconds <= remaining_seconds - 1'b1;
                            end else begin
                                remaining_seconds <= 8'd0;
                                game_running      <= 1'b0;
                                game_finished     <= 1'b1;
                                player_won        <= 1'b0;
                            end
                        end
                    end else begin
                        service_frame_counter <= service_frame_counter + 1'b1;
                    end
                end

                if (round_complete_pulse) begin
                    if (score != 8'hff)
                        score <= score + 1'b1;

                    last_stop_seconds <= completed_stop_seconds;
                    if ((best_stop_seconds == 0) ||
                        (completed_stop_seconds < best_stop_seconds)) begin
                        best_stop_seconds <= completed_stop_seconds;
                    end

                    case (active_game_mode)
                        MODE_POINT_RACE: begin
                            if ((score + 1'b1) >= active_target_value) begin
                                game_running  <= 1'b0;
                                game_finished <= 1'b1;
                                player_won    <= 1'b1;
                            end
                        end

                        MODE_SPEED_UP: begin
                            if ((score + 1'b1) >= SPEED_UP_TARGET) begin
                                game_running      <= 1'b0;
                                game_finished     <= 1'b1;
                                player_won        <= 1'b1;
                                remaining_seconds <= 8'd0;
                            end else if (speed_up_limit > 8'd1) begin
                                speed_up_limit <= speed_up_limit - 1'b1;
                            end
                        end

                        MODE_BEST_OF: begin
                            if ((score + 1'b1) >= active_target_value) begin
                                game_running  <= 1'b0;
                                game_finished <= 1'b1;
                                player_won    <= 1'b1;
                            end
                        end

                        default: begin
                            // TIME ATTACK ends only after its time limit expires.
                        end
                    endcase
                end
            end
        end
    end

endmodule
