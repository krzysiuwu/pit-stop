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

    // Ten modul pozostaje cienka warstwa sprzetowa: odbiera dane PS/2,
    // skaluje wspolrzedne i przekazuje je do wspolnego rdzenia gry.
    logic [11:0] mouse_x;
    logic [11:0] mouse_y;
    logic        mouse_btn_left;
    logic [3:0]  mouse_z_raw;
    logic signed [3:0] mouse_scroll;
    logic mouse_new_event;

    logic [11:0] mouse_x_div4;
    logic [11:0] mouse_y_div4;
    logic [11:0] low_res_mouse_x;
    logic [11:0] low_res_mouse_y;
    logic [11:0] mouse_limit_value;
    logic        mouse_setmax_x;
    logic        mouse_setmax_y;
    (* ASYNC_REG = "TRUE" *) logic [15:0] switches_meta;
    (* ASYNC_REG = "TRUE" *) logic [15:0] switches_sync;

    assign mouse_scroll = $signed(mouse_z_raw);
    assign mouse_x_div4 = mouse_x >> 2;
    assign mouse_y_div4 = mouse_y >> 2;

    assign low_res_mouse_x =
        (mouse_x_div4 > 12'd255) ? 12'd255 : mouse_x_div4;
    assign low_res_mouse_y =
        (mouse_y_div4 > 12'd191) ? 12'd191 : mouse_y_div4;

    always_ff @(posedge clk) begin
        if (!rst) begin
            switches_meta <= 16'd0;
            switches_sync <= 16'd0;
        end else begin
            switches_meta <= switches;
            switches_sync <= switches_meta;
        end
    end

    mouse_limits u_mouse_limits (
        .clk(clk),
        .rst(rst),
        .value(mouse_limit_value),
        .setmax_x(mouse_setmax_x),
        .setmax_y(mouse_setmax_y)
    );

    MouseCtl u_mouse_ctl (
        .clk(clk),
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
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data)
    );

    pit_stop_core u_pit_stop_core (
        .clk(clk),
        .rst(rst),
        .mouse_x(low_res_mouse_x),
        .mouse_y(low_res_mouse_y),
        .mouse_btn_left(mouse_btn_left),
        .mouse_scroll(mouse_scroll),
        .mouse_new_event(mouse_new_event),
        .switches(switches_sync),
        .uart_rx_i(uart_rx_i),
        .uart_debug_finish(uart_debug_finish),
        .uart_tx_o(uart_tx_o),
        .uart_link_connected(uart_link_connected),
        .uart_rx_activity(uart_rx_activity),
        .uart_error(uart_error),
        .uart_remote_debug(uart_remote_debug),
        .uart_remote_score(uart_remote_score),
        .r(r), .g(g), .b(b), .hs(hs), .vs(vs),
        .seven_segment_value(seven_segment_value),
        .vga_x(), .vga_y()
    );

endmodule
