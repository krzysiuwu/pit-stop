/**
 * Module: top_interactive
 * Summary: Adapts the shared game core to the interactive Verilator frontend.
 * Author: Adam Krupa
 */
module top_interactive (
    input  logic clk,
    input  logic rst,

    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_btn_left,
    input  logic signed [3:0] mouse_scroll,
    input  logic              mouse_new_event,
    input  logic [15:0]       switches,
    input  logic              uart_rx,
    input  logic              uart_debug_finish,

    output logic vs,
    output logic hs,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,

    output logic [7:0] seven_segment_value,

    output logic [11:0] vga_x,
    output logic [11:0] vga_y
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [11:0] mouse_x_div4;
    logic [11:0] mouse_y_div4;
    logic [11:0] low_res_mouse_x;
    logic [11:0] low_res_mouse_y;

    assign mouse_x_div4 = mouse_x >> 2;
    assign mouse_y_div4 = mouse_y >> 2;

    assign low_res_mouse_x =
        (mouse_x_div4 > 12'd255) ? 12'd255 : mouse_x_div4;
    assign low_res_mouse_y =
        (mouse_y_div4 > 12'd191) ? 12'd191 : mouse_y_div4;

    // The simulator and FPGA use exactly the same game core.
    pit_stop_core u_pit_stop_core (
        .clk(clk),
        .rst(rst),
        .mouse_x(low_res_mouse_x),
        .mouse_y(low_res_mouse_y),
        .mouse_btn_left(mouse_btn_left),
        .mouse_scroll(mouse_scroll),
        .mouse_new_event(mouse_new_event),
        .switches(switches),
        .uart_rx_i(uart_rx),
        .uart_debug_finish(uart_debug_finish),
        .uart_tx_o(),
        .uart_link_connected(),
        .uart_rx_activity(),
        .uart_error(),
        .uart_remote_debug(),
        .uart_remote_score(),
        .r(r), .g(g), .b(b), .hs(hs), .vs(vs),
        .seven_segment_value(seven_segment_value),
        .vga_x(vga_x), .vga_y(vga_y)
    );

endmodule
