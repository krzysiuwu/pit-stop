/**
 * Testbench: top_vga_tb
 * Summary: Captures VGA frames from the legacy top-level simulation design.
 * Author: Adam Krupa
 * Based on: SJSU EE178/AGH UEC2 simulation framework.
 */
module top_vga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 15.38;     // 65 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;


    /**
     * Local variables and signals
     */

    logic clk, rst;
    wire vs, hs;
    wire [3:0] r, g, b;


    /**
     * Clock generation
     */

    initial begin
     clk = 1'b0;
     force dut.x_pos = 12'd200;
     force dut.y_pos = 12'd200;
     forever #(CLK_PERIOD/2) clk = ~clk;
     end


    /**
     * Submodules instances
     */

    top_vga dut (
        .clk(clk),
        .rst(rst),
        .vs(vs),
        .hs(hs),
        .r(r),
        .g(g),
        .b(b)
    );

    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(vs)
    );


    /**
     * Main test
     */

    initial begin
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;

        $display("If simulation ends before the testbench");
        $display("completes, use the menu option to run all.");
        $display("Prepare to wait a long time...");

        wait (vs == 1'b0);
        @(negedge vs) $display("Info: negedge VS at %t",$time);
        @(negedge vs) $display("Info: negedge VS at %t",$time);
        @(posedge vs);
        // End the simulation.
        $display("Simulation is over, check the waveforms.");
        
        $finish;
    end

endmodule
