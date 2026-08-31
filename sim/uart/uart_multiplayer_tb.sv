/**
 * Testbench: uart_multiplayer_tb
 * Summary: Connects two game-link instances and verifies synchronization, scores, finish exchange, and match results.
 * Author: Adam Krupa
 */
import game_pkg::*;

module uart_multiplayer_tb;

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CLOCK_HZ = 1_000;
    localparam int BAUD = 100;
    localparam int TX_INTERVAL = 120;
    localparam int LINK_TIMEOUT = 5_000;

    logic clk = 1'b0;
    logic rst = 1'b0;
    always #5 clk = ~clk;

    logic uart_a_to_b;
    logic uart_b_to_a;

    logic start_a = 1'b0;
    logic start_b = 1'b0;
    logic reset_a = 1'b0;
    logic reset_b = 1'b0;
    logic multiplayer_a = 1'b1;
    logic multiplayer_b = 1'b1;
    logic debug_a = 1'b1;
    logic debug_b = 1'b1;
    logic [1:0] mode_a = MODE_POINT_RACE;
    logic [1:0] mode_b = MODE_TIME_ATTACK;
    logic [7:0] target_a = 8'd7;
    logic [7:0] target_b = 8'd9;
    logic [7:0] score_a = 8'd12;
    logic [7:0] score_b = 8'd34;

    logic controller_finished_a = 1'b0;
    logic controller_finished_b = 1'b0;
    logic publish_finished_a;
    logic publish_finished_b;
    logic match_complete_a;
    logic match_complete_b;
    logic freeze_a;
    logic freeze_b;
    logic [1:0] result_a;
    logic [1:0] result_b;

    logic connected_a;
    logic connected_b;
    logic remote_multiplayer_a;
    logic remote_multiplayer_b;
    logic remote_debug_a;
    logic remote_debug_b;
    logic remote_start_a;
    logic remote_start_b;
    logic remote_finished_a;
    logic remote_finished_b;
    logic [1:0] remote_mode_a;
    logic [1:0] remote_mode_b;
    logic [7:0] remote_target_a;
    logic [7:0] remote_target_b;
    logic [7:0] remote_score_a;
    logic [7:0] remote_score_b;
    logic activity_a;
    logic activity_b;
    logic error_a;
    logic error_b;
    logic active_a = 1'b0;
    logic active_b = 1'b0;

    uart_game_link #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD(BAUD),
        .TX_INTERVAL_CYCLES(TX_INTERVAL),
        .LINK_TIMEOUT_CYCLES(LINK_TIMEOUT)
    ) link_a (
        .clk(clk), .rst(rst),
        .uart_rx_i(uart_b_to_a), .uart_tx_o(uart_a_to_b),
        .local_session_start(start_a),
        .local_session_reset(reset_a),
        .local_multiplayer_selected(multiplayer_a),
        .local_debug_mode(debug_a),
        .local_game_finished(publish_finished_a),
        .local_game_mode(mode_a),
        .local_target_value(target_a),
        .local_score(score_a),
        .link_connected(connected_a),
        .remote_multiplayer_selected(remote_multiplayer_a),
        .remote_debug_mode(remote_debug_a),
        .remote_start_pulse(remote_start_a),
        .remote_game_finished(remote_finished_a),
        .remote_game_mode(remote_mode_a),
        .remote_target_value(remote_target_a),
        .remote_score(remote_score_a),
        .rx_activity(activity_a),
        .rx_error_sticky(error_a)
    );

    uart_game_link #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD(BAUD),
        .TX_INTERVAL_CYCLES(TX_INTERVAL),
        .LINK_TIMEOUT_CYCLES(LINK_TIMEOUT)
    ) link_b (
        .clk(clk), .rst(rst),
        .uart_rx_i(uart_a_to_b), .uart_tx_o(uart_b_to_a),
        .local_session_start(start_b),
        .local_session_reset(reset_b),
        .local_multiplayer_selected(multiplayer_b),
        .local_debug_mode(debug_b),
        .local_game_finished(publish_finished_b),
        .local_game_mode(mode_b),
        .local_target_value(target_b),
        .local_score(score_b),
        .link_connected(connected_b),
        .remote_multiplayer_selected(remote_multiplayer_b),
        .remote_debug_mode(remote_debug_b),
        .remote_start_pulse(remote_start_b),
        .remote_game_finished(remote_finished_b),
        .remote_game_mode(remote_mode_b),
        .remote_target_value(remote_target_b),
        .remote_score(remote_score_b),
        .rx_activity(activity_b),
        .rx_error_sticky(error_b)
    );

    multiplayer_result result_logic_a (
        .active(active_a),
        .local_game_finished(controller_finished_a),
        .remote_game_finished(remote_finished_a),
        .local_score(score_a),
        .remote_score(remote_score_a),
        .publish_finished(publish_finished_a),
        .match_complete(match_complete_a),
        .freeze_local_game(freeze_a),
        .result(result_a)
    );

    multiplayer_result result_logic_b (
        .active(active_b),
        .local_game_finished(controller_finished_b),
        .remote_game_finished(remote_finished_b),
        .local_score(score_b),
        .remote_score(remote_score_b),
        .publish_finished(publish_finished_b),
        .match_complete(match_complete_b),
        .freeze_local_game(freeze_b),
        .result(result_b)
    );

    task automatic wait_for_connections;
        int cycles;
        begin
            cycles = 0;
            while (!(connected_a && connected_b) && (cycles < 20_000)) begin
                @(posedge clk);
                cycles++;
            end
            if (!(connected_a && connected_b))
                $fatal(1, "UART links did not connect");
        end
    endtask

    task automatic wait_for_debug_scores;
        int cycles;
        begin
            cycles = 0;
            while (((remote_score_a != score_b) ||
                    (remote_score_b != score_a)) && (cycles < 20_000)) begin
                @(posedge clk);
                cycles++;
            end
            if ((remote_score_a != score_b) || (remote_score_b != score_a))
                $fatal(1, "Bidirectional score transfer failed");
        end
    endtask

    task automatic wait_for_remote_start_b;
        int cycles;
        begin
            cycles = 0;
            while (!remote_start_b && (cycles < 20_000)) begin
                @(posedge clk);
                cycles++;
            end
            if (!remote_start_b)
                $fatal(1, "Remote board did not receive session start");
        end
    endtask

    task automatic wait_for_match_complete;
        int cycles;
        begin
            cycles = 0;
            while (!(match_complete_a && match_complete_b) &&
                   (cycles < 30_000)) begin
                @(posedge clk);
                cycles++;
            end
            if (!(match_complete_a && match_complete_b))
                $fatal(1, "Final scores were not exchanged");
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst = 1'b1;

        wait_for_connections();
        wait_for_debug_scores();

        // Only board A starts. Board B must adopt A's mode and target.
        @(negedge clk);
        start_a = 1'b1;
        active_a = 1'b1;
        @(negedge clk);
        start_a = 1'b0;

        wait_for_remote_start_b();
        active_b = 1'b1;
        mode_b = remote_mode_b;
        target_b = remote_target_b;

        if ((remote_mode_b != MODE_POINT_RACE) ||
            (remote_target_b != 8'd7))
            $fatal(1, "Remote configuration was not adopted");

        // Exchange changing in-game scores in both directions.
        score_a = 8'd5;
        score_b = 8'd5;
        wait_for_debug_scores();
        if ((result_a != RESULT_DRAW) || (result_b != RESULT_DRAW))
            $fatal(1, "DRAW comparison is inconsistent");

        score_a = 8'd7;
        score_b = 8'd3;
        wait_for_debug_scores();

        // A finishes first. B must freeze, publish its final value, and both
        // boards must reach complementary final results.
        controller_finished_a = 1'b1;
        wait_for_match_complete();

        if ((result_a != RESULT_WIN) || (result_b != RESULT_LOSE))
            $fatal(1, "WIN/LOSE comparison is inconsistent");
        if (!freeze_b)
            $fatal(1, "Remote finish did not freeze board B");
        if (error_a || error_b)
            $fatal(1, "UART framing or checksum error detected");

        $display("uart_multiplayer_tb: PASS");
        $finish;
    end

endmodule
