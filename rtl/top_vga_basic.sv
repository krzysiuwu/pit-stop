/**
 * Basic VGA Top Module
 * Description:
 * Modul top do wyswietlania wylacznie tla i sprite'ow, z pominieciem obslugi myszki (PS2).
 */

module top_vga_basic (
        input  logic clk,
        input  logic rst,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire [3:0] lut_pipe;
    wire [11:0] rgb_pipe;

    low_res_if low_res_pipe();

    // VGA signals from timing
    vga_if vga_timing_if();
    // VGA signals from background
    vga_if vga_bg();
    // VGA signals from upscaler
    vga_if vga_upscale();

    /**
     * Signals assignments
     */
    assign vs = ~vga_upscale.vsync;
    assign hs = ~vga_upscale.hsync;
    assign {r,g,b} = rgb_pipe;

    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk,
        .rst,
        .vga_out(vga_timing_if),
        .low_res_out(low_res_pipe)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst,
        .lut_out(lut_pipe),
        .low_res_in(low_res_pipe),
        .vga_in(vga_timing_if),
        .vga_out(vga_bg)
    );

    LUT2RGB_converter u_LUT2RGB_converter (
        .clk,
        .rst_n(rst),
        .lut_value(lut_pipe),
        .rgb_out(rgb_pipe),
        .vga_in(vga_bg),
        .vga_out(vga_upscale)
    );

endmodule
