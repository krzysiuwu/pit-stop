/**
 * Module: vector_synchronizer
 * Summary: Synchronizes an asynchronous input vector through two register stages.
 * Author: Adam Krupa
 */
module vector_synchronizer #(
    parameter int WIDTH = 1
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] async_in,
    output logic [WIDTH-1:0] sync_out
);

    timeunit 1ns;
    timeprecision 1ps;

    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] input_meta;
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] input_sync;

    always_ff @(posedge clk) begin
        if (!rst) begin
            input_meta <= '0;
            input_sync <= '0;
        end else begin
            input_meta <= async_in;
            input_sync <= input_meta;
        end
    end

    assign sync_out = input_sync;

endmodule
