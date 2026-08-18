module top_fsm (
    input  logic clk,
    input  logic rst,
    input  logic [15:0] switches,

    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    output logic hs,
    output logic vs,

    output logic       option_multiplayer,
    output logic [1:0] option_game_mode,
    output logic [7:0] option_target_value,
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
    logic        mouse_middle;
    logic        mouse_right;
    logic [3:0]  mouse_z_raw;
    logic signed [3:0] mouse_scroll;
    logic mouse_new_event;

    logic [11:0] mouse_x_div4;
    logic [11:0] mouse_y_div4;
    logic [11:0] low_res_mouse_x;
    logic [11:0] low_res_mouse_y;

    assign mouse_scroll = $signed(mouse_z_raw);
    assign mouse_x_div4 = mouse_x >> 2;
    assign mouse_y_div4 = mouse_y >> 2;

    assign low_res_mouse_x =
        (mouse_x_div4 > 12'd255) ? 12'd255 : mouse_x_div4;
    assign low_res_mouse_y =
        (mouse_y_div4 > 12'd191) ? 12'd191 : mouse_y_div4;

    MouseCtl u_mouse_ctl (
        .clk(clk),
        .rst(~rst),
        .xpos(mouse_x),
        .ypos(mouse_y),
        .zpos(mouse_z_raw),
        .left(mouse_btn_left),
        .middle(mouse_middle),
        .right(mouse_right),
        .new_event(mouse_new_event),
        .value(12'b0),
        .setx(1'b0),
        .sety(1'b0),
        .setmax_x(1'b0),
        .setmax_y(1'b0),
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
        .switches(switches),
        .r(r), .g(g), .b(b), .hs(hs), .vs(vs),
        .option_multiplayer(option_multiplayer),
        .option_game_mode(option_game_mode),
        .option_target_value(option_target_value),
        .seven_segment_value(seven_segment_value),
        .vga_x(), .vga_y()
    );

endmodule
