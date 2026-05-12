/**
 *  Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for vga_timing module.
 */


module vga_timing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 25;     // 40 MHz
    localparam RST_START_TIME  = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;


    /**
     * Local variables and signals
     */

    logic clk;
    logic rst;

    wire [10:0] vcount, hcount;
    wire        vsync,  hsync;
    wire        vblnk,  hblnk;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Reset generation
     */

    initial begin
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;
    end


    /**
     * Dut placement
     */

    vga_timing dut(
        .clk,
        .rst,
        .vcount,
        .vsync,
        .vblnk,
        .hcount,
        .hsync,
        .hblnk
    );

    /**
     * Tasks and functions
     */

    // Here you can declare tasks with immediate assertions (assert).


    /**
     * Assertions
     */

    // Here you can declare concurrent assertions (assert property).


    /**
     * Main test
     */

    initial begin

        /*
        @(posedge rst);
        @(negedge rst);

        wait (vsync == 1'b0);
        @(negedge vsync);
        @(negedge vsync);

        */

        #20ms;

        $finish;
    end

endmodule
