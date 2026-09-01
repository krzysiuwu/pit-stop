/**
 * Module: top_fsm
 * Summary: Bridges synchronized PS/2 mouse data and board controls into the shared pit-stop game core.
 * Author: Adam Krupa
 */
module top_fsm (
        input  logic clk,
        input  logic rst,
        input  logic [15:0] switches,
        input  logic uart_rx_i,
        input  logic uart_debug_finish,

        output logic uart_tx_o,
        output logic uart_link_connected,
        output logic uart_rx_activity,
        output logic uart_error,
        output logic uart_remote_debug,
        output logic [7:0] uart_remote_score,

        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b,
        output logic hs,
        output logic vs,

        output logic [7:0] seven_segment_value,

        inout  logic ps2_data,
        inout  logic ps2_clk
    );

    timeunit 1ns;
    timeprecision 1ps;

    // This module is a thin hardware adapter: it receives PS/2 data,
    // scales coordinates, and forwards them to the shared game core.
    logic [11:0] mouse_x;
    logic [11:0] mouse_y;
    logic        mouse_btn_left;
    logic [3:0]  mouse_z_raw;
    logic signed [3:0] mouse_scroll;
    logic mouse_new_event;

    logic [11:0] low_res_mouse_x;
    logic [11:0] low_res_mouse_y;
    logic [11:0] mouse_limit_value;
    logic        mouse_setmax_x;
    logic        mouse_setmax_y;
    logic [15:0] switches_sync;

    assign mouse_scroll = $signed(mouse_z_raw);

    vector_synchronizer #(
        .WIDTH(16)
    ) u_switch_synchronizer (
        .clk,
        .rst,
        .async_in(switches),
        .sync_out(switches_sync)
    );

    mouse_coordinate_scaler u_mouse_coordinate_scaler (
        .full_res_x(mouse_x),
        .full_res_y(mouse_y),
        .game_x(low_res_mouse_x),
        .game_y(low_res_mouse_y)
    );

    mouse_limits u_mouse_limits (
        .clk,
        .rst,
        .value(mouse_limit_value),
        .setmax_x(mouse_setmax_x),
        .setmax_y(mouse_setmax_y)
    );

    MouseCtl u_mouse_ctl (
        .clk,
        .rst(~rst),
        .xpos(mouse_x),
        .ypos(mouse_y),
        .zpos(mouse_z_raw),
        .left(mouse_btn_left),
        .middle(),
        .right(),
        .new_event(mouse_new_event),
        .value(mouse_limit_value),
        .setx(1'b0),
        .sety(1'b0),
        .setmax_x(mouse_setmax_x),
        .setmax_y(mouse_setmax_y),
        .ps2_clk,
        .ps2_data
    );

    pit_stop_core u_pit_stop_core (
        .clk,
        .rst,
        .mouse_x(low_res_mouse_x),
        .mouse_y(low_res_mouse_y),
        .mouse_btn_left(mouse_btn_left),
        .mouse_scroll,
        .mouse_new_event,
        .switches(switches_sync),
        .uart_rx_i,
        .uart_debug_finish,
        .uart_tx_o,
        .uart_link_connected,
        .uart_rx_activity,
        .uart_error,
        .uart_remote_debug,
        .uart_remote_score,
        .r, .g, .b, .hs, .vs,
        .seven_segment_value,
        .vga_x(), .vga_y()
    );

endmodule
