/**
 * Module: game_options
 * Summary: Synchronizes and decodes the Basys 3 switches into game mode, target, multiplayer, and UART-test settings.
 * Author: Adam Krupa
 */
module game_options (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] switches,

    output logic        multiplayer,
    output logic        uart_test_mode,
    output logic [1:0]  game_mode,
    output logic [7:0]  target_value
);

    timeunit 1ns;
    timeprecision 1ps;

    // Mechanical slide switches are asynchronous to the video clock. Two
    // flip-flops prevent a metastable signal from entering the game logic.
    (* ASYNC_REG = "TRUE" *) logic [15:0] switches_meta;
    (* ASYNC_REG = "TRUE" *) logic [15:0] switches_sync;

    always_ff @(posedge clk) begin
        if (!rst) begin
            switches_meta <= 16'b0;
            switches_sync <= 16'b0;
        end else begin
            switches_meta <= switches;
            switches_sync <= switches_meta;
        end
    end

    assign multiplayer = switches_sync[15];
    assign uart_test_mode = switches_sync[12];
    assign game_mode   = switches_sync[14:13];

    // A target of zero would make every planned mode end immediately. Keeping
    // the visible value at one also makes an all-zero switch setting usable.
    assign target_value = (switches_sync[7:0] == 8'd0)
                        ? 8'd1
                        : switches_sync[7:0];

endmodule
