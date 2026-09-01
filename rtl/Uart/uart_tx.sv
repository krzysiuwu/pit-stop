/**
 * Module: uart_tx
 * Summary: Serializes bytes as 115200-baud 8N1 UART frames.
 * Author: Adam Krupa
 */
module uart_tx #(
    parameter int CLOCK_HZ = 65_000_000,
    parameter int BAUD     = 115_200
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       data_valid,
    input  logic [7:0] data,

    output logic       data_ready,
    output logic       tx
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CLKS_PER_BIT_RAW = CLOCK_HZ / BAUD;
    localparam int CLKS_PER_BIT = (CLKS_PER_BIT_RAW < 1) ? 1 : CLKS_PER_BIT_RAW;
    localparam int COUNTER_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    logic [9:0] frame;
    logic [3:0] bit_index;
    logic [COUNTER_WIDTH-1:0] clock_counter;
    logic busy;

    // data_ready forms a byte-level handshake with uart_game_link. The serial
    // line remains high between frames, as required by 8N1 UART.
    assign data_ready = !busy;
    assign tx = busy ? frame[bit_index] : 1'b1;

    always_ff @(posedge clk) begin
        if (!rst) begin
            frame         <= 10'h3ff;
            bit_index     <= 4'd0;
            clock_counter <= '0;
            busy          <= 1'b0;
        end else if (!busy) begin
            clock_counter <= '0;
            bit_index     <= 4'd0;

            if (data_valid) begin
                // 8N1: start bit, eight data bits LSB first, stop bit.
                frame <= {1'b1, data, 1'b0};
                busy  <= 1'b1;
            end
        end else if (clock_counter == CLKS_PER_BIT - 1) begin
            clock_counter <= '0;

            if (bit_index == 4'd9) begin
                bit_index <= 4'd0;
                busy      <= 1'b0;
            end else begin
                bit_index <= bit_index + 1'b1;
            end
        end else begin
            clock_counter <= clock_counter + 1'b1;
        end
    end

endmodule
