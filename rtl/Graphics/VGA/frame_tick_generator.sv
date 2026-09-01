/**
 * Module: frame_tick_generator
 * Summary: Produces one synchronous animation tick on the falling edge of vertical synchronization.
 * Author: Adam Krupa
 */
module frame_tick_generator (
    input  logic clk,
    input  logic rst,
    input  logic vsync,
    output logic frame_tick
);

    timeunit 1ns;
    timeprecision 1ps;

    logic vsync_previous;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vsync_previous <= 1'b0;
            frame_tick     <= 1'b0;
        end else begin
            vsync_previous <= vsync;
            frame_tick     <= !vsync && vsync_previous;
        end
    end

endmodule
