/**
 * Testbench: drawing_test_tb
 * Summary: Captures a fixed number of frames from the sprite-composition test pipeline.
 * Author: Adam Krupa
 * Based on: SJSU EE178/AGH UEC2 simulation framework.
 */
module drawing_test_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */
    localparam CLK_PERIOD = 15.38;     // 65 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;
    
    // Number of frames generated before the test stops automatically.
    localparam int FRAMES_TO_SIMULATE = 4;

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
    top_vga_basic dut (
        .clk(clk),
        .rst(rst),
        .vs(vs),
        .hs(hs),
        .r(r),
        .g(g),
        .b(b)
    );

    // Capture the rendered output with tiff_writer.
    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results") // Zmieniono na poprawny parametr
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}), // fabricate an 8-bit value (4 bity powielone 2x)
        .g({g,g}), 
        .b({b,b}), 
        .go(vs)    // Zgodnie z Twoim plikiem tiff_writer, tu wchodzi vs
    );

    /**
     * Main test & Auto-Stop Logic
     */
    initial begin
        // Initialize inputs and apply reset.
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;

        $display("Rozpoczeto symulacje...");
        $display("Czekam na wygenerowanie %0d klatek...", FRAMES_TO_SIMULATE);

        // Wait for the initial VSYNC pulse to deassert.
        wait (vs == 1'b0);
        
        // tiff_writer opens a frame on one VSYNC edge and closes it on the next.
        // Count enough edges to close the final requested frame.
        for (int i = 0; i <= FRAMES_TO_SIMULATE; i++) begin
            @(posedge vs);
            if (i > 0) begin
                $display("Info: Zapisano klatke %0d/%0d w czasie %0t", i, FRAMES_TO_SIMULATE, $time);
            end
        end

        // Finish the simulation.
        $display("==================================================");
        $display("Symulacja zakonczona sukcesem.");
        $display("Sprawdz folder 'results' i uzyj skryptu Python!");
        $display("==================================================");
        
        $finish;
    end

endmodule