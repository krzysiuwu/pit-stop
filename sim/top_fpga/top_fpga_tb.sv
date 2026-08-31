/**
 * Testbench: top_fpga_tb
 * Summary: Exercises the FPGA-oriented top and optionally captures its VGA output.
 * Author: Adam Krupa
 * Based on: SJSU EE178/AGH UEC2 simulation framework.
 */
module top_fpga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 10;     // 100 MHz
    localparam RST_START_TIME = 1000;
    localparam RST_ACTIVE_TIME = 2000;


    /**
     * Local variables and signals
     */

    logic clk, rst;
    logic [15:0] sw;
    wire pclk;
    wire vs, hs;
    wire [3:0] r, g, b;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;
    wire [15:0] led;
    logic uart_rx;
    logic btnU;
    wire uart_tx;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Submodules instances
     */

    top_vga_basys3 dut (
        .clk(clk),
        .btnC(rst),
        .btnU(btnU),
        .sw(sw),
        .Vsync(vs),
        .Hsync(hs),
        .vgaRed(r),
        .vgaGreen(g),
        .vgaBlue(b),
        .JA1(pclk),
        .seg(seg),
        .an(an),
        .dp(dp),
        .led(led),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    tiff_writer #(
        .XDIM(16'd1056),
        .YDIM(16'd628),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(pclk),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(vs)
    );


    /**
     * Main test
     */

    initial begin
        sw = 16'd60;
        uart_rx = 1'b1;
        btnU = 1'b0;
        rst = 1'b1;
        #(RST_START_TIME + RST_ACTIVE_TIME) rst = 1'b0;

        /*

        $display("If simulation ends before the testbench");
        $display("completes, use the menu option to run all.");
        $display("Prepare to wait a long time...");

        wait (vs == 1'b0);
        @(negedge vs) $display("Info: negedge VS at %t",$time);
        @(negedge vs) $display("Info: negedge VS at %t",$time);

        // End the simulation.
        $display("Simulation is over, check the waveforms.");

        */

        #20ms;
        $finish;
    end

endmodule
