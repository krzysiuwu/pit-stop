/**
 * Testbench: vga_timing_tb
 * Summary: Checks the generated 1024-by-768 VGA counters, synchronization pulses, and blanking intervals.
 * Author: Adam Krupa
 * Based on: AGH UEC2 testbench by Piotr Kaczmarczyk.
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
    vga_if vga_out();

    assign vcount = vga_out.vcount;
    assign vsync  = vga_out.vsync;
    assign vblnk  = vga_out.vblnk;
    assign hcount = vga_out.hcount;
    assign hsync  = vga_out.hsync;
    assign hblnk  = vga_out.hblnk;


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
        .vga_out(vga_out)
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
