import game_pkg::*;

module multiplayer_result (
    input  logic       active,
    input  logic       local_game_finished,
    input  logic       remote_game_finished,
    input  logic [7:0] local_score,
    input  logic [7:0] remote_score,

    output logic       publish_finished,
    output logic       match_complete,
    output logic       freeze_local_game,
    output logic [1:0] result
);

    always_comb begin
        publish_finished = active &&
                           (local_game_finished || remote_game_finished);
        match_complete    = active && publish_finished &&
                            remote_game_finished;
        freeze_local_game = active && remote_game_finished;

        if (local_score > remote_score)
            result = RESULT_WIN;
        else if (local_score < remote_score)
            result = RESULT_LOSE;
        else
            result = RESULT_DRAW;
    end

endmodule
