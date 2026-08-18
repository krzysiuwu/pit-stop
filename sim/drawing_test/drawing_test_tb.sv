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
 * Testbench for top_vga.
 * Automatically stops simulation after generating a specific number of frames.
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
    
    // Liczba klatek do wygenerowania przed automatycznym zakończeniem
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

    // Używamy Twojej wersji modułu tiff_writer
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
        // Inicjalizacja i Reset
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;

        $display("Rozpoczeto symulacje...");
        $display("Czekam na wygenerowanie %0d klatek...", FRAMES_TO_SIMULATE);

        // Poczekaj aż VS opadnie na początku
        wait (vs == 1'b0);
        
        // Moduł tiff_writer otwiera plik na posedge go (vs) i zamyka na kolejnym posedge.
        // Pętla odliczy dokładnie tyle cykli, by zamknąć ostatnią klatkę.
        for (int i = 0; i <= FRAMES_TO_SIMULATE; i++) begin
            @(posedge vs);
            if (i > 0) begin
                $display("Info: Zapisano klatke %0d/%0d w czasie %0t", i, FRAMES_TO_SIMULATE, $time);
            end
        end

        // Zakończenie symulacji
        $display("==================================================");
        $display("Symulacja zakonczona sukcesem.");
        $display("Sprawdz folder 'results' i uzyj skryptu Python!");
        $display("==================================================");
        
        $finish;
    end

endmodule