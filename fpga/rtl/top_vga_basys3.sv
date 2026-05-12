/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnC,
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire JA1,

        inout wire PS2Data,
        inout wire PS2Clk
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire locked;
    wire pclk_mirror;

    wire clk_100M;
    wire clk_40M;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;


    /**
     * FPGA submodules placement
     */

    clk_wiz_0 CLK0(

        .clk100MHz(clk_100M),
        .clk40MHz(clk_40M),
        .clk,
        .locked
    );


    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk_40M),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );


    /**
     *  Project functional top module
     */

    top_vga u_top_vga (
        .clk(clk_40M),
        .clk_100MHz(clk_100M),
        .rst(!btnC),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync),
        .ps2_data(PS2Data),             //do ogarnięcia
        .ps2_clk(PS2Clk)
    );

endmodule
