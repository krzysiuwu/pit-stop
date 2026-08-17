module singleplayer_game_controller_tb;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk = 1'b0;
    logic rst = 1'b0;
    logic frame_tick = 1'b0;
    logic start_game = 1'b0;
    logic service_active = 1'b0;
    logic round_complete = 1'b0;
    logic [1:0] selected_game_mode = 2'b00;
    logic [7:0] selected_target_value = 8'd1;

    logic game_running;
    logic game_finished;
    logic player_won;
    logic [1:0] active_game_mode;
    logic [7:0] active_target_value;
    logic [7:0] score;
    logic [7:0] display_value;
    logic [7:0] remaining_seconds;
    logic [15:0] elapsed_seconds;
    logic [7:0] last_stop_seconds;
    logic [7:0] best_stop_seconds;

    always #5 clk = ~clk;

    singleplayer_game_controller #(
        .FRAMES_PER_SECOND(2),
        .SPEED_UP_ROUNDS(3)
    ) dut (
        .clk(clk), .rst(rst), .frame_tick(frame_tick),
        .start_game(start_game), .service_active(service_active),
        .round_complete(round_complete),
        .selected_game_mode(selected_game_mode),
        .selected_target_value(selected_target_value),
        .game_running(game_running), .game_finished(game_finished),
        .player_won(player_won), .active_game_mode(active_game_mode),
        .active_target_value(active_target_value), .score(score),
        .display_value(display_value),
        .remaining_seconds(remaining_seconds),
        .elapsed_seconds(elapsed_seconds),
        .last_stop_seconds(last_stop_seconds),
        .best_stop_seconds(best_stop_seconds)
    );

    task automatic clock_once;
        begin
            @(negedge clk);
            @(posedge clk);
        end
    endtask

    task automatic tick_frame;
        begin
            @(negedge clk);
            frame_tick = 1'b1;
            @(negedge clk);
            frame_tick = 1'b0;
        end
    endtask

    task automatic begin_game(input logic [1:0] mode,
                              input logic [7:0] target);
        begin
            selected_game_mode = mode;
            selected_target_value = target;
            @(negedge clk);
            start_game = 1'b1;
            @(negedge clk);
            start_game = 1'b0;
        end
    endtask

    task automatic complete_stop(input int frame_count);
        int i;
        begin
            @(negedge clk);
            service_active = 1'b1;
            clock_once();
            for (i = 0; i < frame_count; i++)
                tick_frame();
            @(negedge clk);
            round_complete = 1'b1;
            @(negedge clk);
            round_complete = 1'b0;
            service_active = 1'b0;
            clock_once();
        end
    endtask

    task automatic expect_finished(input logic expected_win,
                                   input logic [7:0] expected_score);
        begin
            if (!game_finished)
                $fatal(1, "Game did not finish");
            if (player_won != expected_win)
                $fatal(1, "Unexpected win state");
            if (score != expected_score)
                $fatal(1, "Unexpected score: %0d", score);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b1;

        // TIME ATTACK: jedna ukonczona wymiana oznacza wygrana po czasie.
        begin_game(2'b00, 8'd2);
        complete_stop(1);
        repeat (3) tick_frame();
        clock_once();
        expect_finished(1'b1, 8'd1);

        // TIME ATTACK bez punktu konczy sie porazka.
        begin_game(2'b00, 8'd1);
        repeat (2) tick_frame();
        clock_once();
        expect_finished(1'b0, 8'd0);

        // POINT RACE konczy sie dokladnie po osiagnieciu celu.
        begin_game(2'b01, 8'd2);
        complete_stop(1);
        if (game_finished)
            $fatal(1, "Point race ended too early");
        complete_stop(1);
        expect_finished(1'b1, 8'd2);

        // SPEED UP: trzy rundy w tescie oznaczaja wygrana.
        begin_game(2'b10, 8'd3);
        complete_stop(1);
        complete_stop(1);
        complete_stop(1);
        expect_finished(1'b1, 8'd3);

        // SPEED UP: przekroczenie limitu konczy sie porazka.
        begin_game(2'b10, 8'd1);
        service_active = 1'b1;
        clock_once();
        repeat (2) tick_frame();
        clock_once();
        expect_finished(1'b0, 8'd0);
        service_active = 1'b0;

        // BEST OF zbiera wynik oraz statystyki czasowe.
        begin_game(2'b11, 8'd2);
        complete_stop(1);
        complete_stop(2);
        expect_finished(1'b1, 8'd2);
        if ((last_stop_seconds != 8'd1) || (best_stop_seconds != 8'd1))
            $fatal(1, "Invalid stop statistics");

        $display("singleplayer_game_controller_tb: PASS");
        $finish;
    end

endmodule
