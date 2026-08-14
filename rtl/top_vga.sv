/**
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic rst,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b,

        inout wire ps2_clk,
        inout wire ps2_data
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire [11:0] x_pos;
    wire [11:0] y_pos;
    wire [3:0] lut_pipe;
    wire [3:0] lut_game;
    wire [11:0] rgb_pipe;
    wire [11:0] rgb_out;
    wire [11:0] mouse_value_pipe;
    wire setmax_x_pipe;
    wire setmax_y_pipe;
    wire left_pipe;
    wire [2:0] state_pipe;
    wire play_pipe;

    // Pipes for low resolution h and v counts
    low_res_if low_res_bg();
    low_res_if low_res_pipe();

    // VGA signals from timing
    vga_if vga_timing();
    // VGA signals from background
    vga_if vga_bg();
    // VGA signals from upscaler
    vga_if vga_upscale();
    // VGA signals from mouse
    vga_if vga_mouse();
    // VGA signals from game drawing
    vga_if vga_game();

    /**
     * Signals assignments
     */

    assign vs = ~vga_game.vsync;
    assign hs = ~vga_game.hsync;
    assign {r,g,b} = rgb_out;

    /**
     * Signals synchronization
     */

    always_ff @(posedge clk or negedge rst) begin : bg_ff_blk
        if (!rst) begin
            vga_mouse.vsync  <= '0;
            vga_mouse.hsync  <= '0;
        end else begin
            vga_mouse.vsync  <= vga_game.vsync;
            vga_mouse.hsync  <= vga_game.hsync;
        end
    end

    /**
     * Submodules instances
     */

    mouse_limits u_mouse_limits (
        .clk,
        .rst,
        .value(mouse_value_pipe),
        .setmax_x(setmax_x_pipe),
        .setmax_y(setmax_y_pipe)
    );

    vga_timing u_vga_timing (
        .clk,
        .rst,
        .vga_out(vga_timing),
        .low_res_out(low_res_pipe)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst,
        .lut_out(lut_pipe),
        .low_res_in(low_res_pipe),
        .low_res_out(low_res_bg),
        .vga_in (vga_timing),
        .vga_out (vga_bg)
    );

    draw_game u_draw_game (
        .clk,
        .rst,
        .current_state(state_pipe),
        .bolid_x(50),
        .mouse_x(x_pos),
        .mouse_y(y_pos),
        .left_click(left_pipe),
        .click_play(play_pipe),
        .lut_in(lut_pipe),
        .vga_in(vga_bg),
        .low_res_in(low_res_bg),
        .lut_out(lut_game),
        .vga_out(vga_game)
    );

    LUT2RGB_converter u_LUT2RGB_converter (
        .clk,
        .rst_n(rst),
        .lut_value(lut_game),
        .rgb_out(rgb_pipe),
        .vga_in (vga_game),
        .vga_out (vga_upscale)
    );

    MouseCtl uMouseCtl(
        .clk,
        .rst(!rst),
        .ps2_clk,
        .ps2_data,
        .xpos(x_pos),
        .ypos(y_pos),
        .zpos(),
        .left(left_pipe),
        .middle(),
        .right(),
        .new_event(),
        .value(mouse_value_pipe),
        .setx(1'b0),
        .sety(1'b0),
        .setmax_x(setmax_x_pipe),
        .setmax_y(setmax_y_pipe)
    );

    MouseDisplay uMouseDisplay(
        .xpos(x_pos),
        .ypos(y_pos),
        .hcount(vga_upscale.hcount),
        .vcount(vga_upscale.vcount),
        .blank(vga_upscale.hblnk | vga_upscale.vblnk),
        .rgb_in(rgb_pipe),
        .rgb_out(rgb_out),
        .pixel_clk(clk),
        .enable_mouse_display_out()
    );

    game_fsm u_game_fsm (
        .clk(clk),
        .rst(!rst),             // Zmiana polaryzacji resetu (zależnie od projektu)
        .click_play(play_pipe),
        .wheels_attached(1'b0),
        .state_out(state_pipe)
    );

endmodule