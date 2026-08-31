/**
 * Testbench: anim_test_tb
 * Summary: Captures enough VGA frames to verify the complete scripted car animation.
 * Author: Adam Krupa
 * Based on: SJSU EE178/AGH UEC2 simulation framework.
 */
module anim_test_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */
    localparam CLK_PERIOD = 15.38;     // 65 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;
    
    // The capture covers smooth braking, a one-second stop, and acceleration.
    localparam int FRAMES_TO_SIMULATE = 360;

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
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    /**
     * Submodules instances
     */
    anim_test dut (
        .clk(clk),
        .rst(rst),
        .vs(vs),
        .hs(hs),
        .r(r),
        .g(g),
        .b(b)
    );

    // Capture VGA frames as TIFF files.
    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results") 
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}), // Replicate the four-bit red channel to eight bits.
        .g({g,g}), 
        .b({b,b}), 
        .go(vs)    // Start a new capture on each vertical-sync pulse.
    );

    /**
     * Main test & Auto-Stop Logic
     */
    initial begin
        // Initialize inputs and apply reset.
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;

        $display("Rozpoczeto symulacje animacji...");
        $display("Czekam na wygenerowanie %0d klatek (To moze chwile potrwac!)...", FRAMES_TO_SIMULATE);

        // Wait for the initial VSYNC pulse to deassert.
        wait (vs == 1'b0);
        
        // Count complete video frames.
        for (int i = 0; i <= FRAMES_TO_SIMULATE; i++) begin
            @(posedge vs);
            if (i > 0) begin
                // Report progress during the long frame capture.
                if (i % 10 == 0 || i == FRAMES_TO_SIMULATE) begin
                    $display("Info: Zapisano klatke %0d/%0d w czasie %0t", i, FRAMES_TO_SIMULATE, $time);
                end
            end
        end

        // Finish the simulation.
        $display("==================================================");
        $display("Symulacja animacji zakonczona sukcesem.");
        $display("Sprawdz folder 'results'. Klatki sa gotowe do zlaczenia!");
        $display("==================================================");
        
        $finish;
    end

endmodule
