/**
 * Package: game_pkg
 * Summary: Defines shared screen identifiers, game modes, and match-result encodings.
 * Author: Adam Krupa
 */
package game_pkg;

    localparam logic [1:0] MODE_TIME_ATTACK = 2'b00;
    localparam logic [1:0] MODE_POINT_RACE  = 2'b01;
    localparam logic [1:0] MODE_SPEED_UP    = 2'b10;
    localparam logic [1:0] MODE_BEST_OF     = 2'b11;

    localparam logic [2:0] SCREEN_MAIN_MENU = 3'b000;
    localparam logic [2:0] SCREEN_OPTIONS   = 3'b001;
    localparam logic [2:0] SCREEN_GAMEPLAY  = 3'b010;
    localparam logic [2:0] SCREEN_SUMMARY   = 3'b011;
    localparam logic [2:0] SCREEN_WAIT_UART = 3'b100;

    localparam logic [1:0] RESULT_LOSE = 2'b00;
    localparam logic [1:0] RESULT_WIN  = 2'b01;
    localparam logic [1:0] RESULT_DRAW = 2'b10;

endpackage
