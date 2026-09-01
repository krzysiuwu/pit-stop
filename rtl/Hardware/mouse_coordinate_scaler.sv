/**
 * Module: mouse_coordinate_scaler
 * Summary: Converts 1024x768 mouse coordinates to the clamped 256x192 game coordinate space.
 * Author: Adam Krupa
 */
module mouse_coordinate_scaler (
    input  logic [11:0] full_res_x,
    input  logic [11:0] full_res_y,
    output logic [11:0] game_x,
    output logic [11:0] game_y
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [11:0] scaled_x;
    logic [11:0] scaled_y;

    always_comb begin
        scaled_x = full_res_x >> 2;
        scaled_y = full_res_y >> 2;

        game_x = (scaled_x > 12'd255) ? 12'd255 : scaled_x;
        game_y = (scaled_y > 12'd191) ? 12'd191 : scaled_y;
    end

endmodule
