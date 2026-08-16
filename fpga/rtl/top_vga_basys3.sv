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
        input  wire [15:0] sw,
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire JA1,
        output wire [6:0] seg,
        output wire [3:0] an,
        output wire dp,

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

    wire clk_65M;
    wire core_rst;
    wire option_multiplayer;
    wire [1:0] option_game_mode;
    wire [7:0] option_target_value;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;
    assign core_rst = !btnC && locked;


    /**
     * FPGA submodules placement
     */

    clk_wiz_0 CLK0(
        .clk_in(clk),       // Zmieniono na clk_in1 (domyślna nazwa Vivado)
        .clk_out1(clk_65M),
        .locked(locked)
    );


    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk_65M),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );


    /**
     *  Project functional top module
     */

    top_fsm u_top_fsm (
        .clk(clk_65M),
        .rst(core_rst), // Bezpieczny reset Active Low (!btnC to 1, gdy nie wciśnięty)
        .switches(sw),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync),
        .option_multiplayer(option_multiplayer),
        .option_game_mode(option_game_mode),
        .option_target_value(option_target_value),
        .ps2_data(PS2Data),             
        .ps2_clk(PS2Clk)
    );

    seven_segment_display u_seven_segment_display (
        .clk(clk_65M),
        .rst(core_rst),
        .value(option_target_value),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

endmodule
