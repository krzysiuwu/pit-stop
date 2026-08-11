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
 * Testbench for anim_test.
 * Generates enough frames to capture the full F1 pit stop animation.
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
    
    // Generujemy 180 klatek (ok. 3 sekundy w 60FPS), by uchwycić cały wjazd i odjazd bolidu
    localparam int FRAMES_TO_SIMULATE = 180;

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

    // Moduł zapisujący klatki do plików .tiff
    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results") 
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}), // powielenie z 4 do 8 bitów
        .g({g,g}), 
        .b({b,b}), 
        .go(vs)    // Zapis nowej klatki przy każdym impulsie synchronizacji pionowej
    );

    /**
     * Main test & Auto-Stop Logic
     */
    initial begin
        // Inicjalizacja i Reset
        rst = 1'b1;
        #(RST_START_TIME) rst = 1'b0;
        #(RST_ACTIVE_TIME) rst = 1'b1;

        $display("Rozpoczeto symulacje animacji...");
        $display("Czekam na wygenerowanie %0d klatek (To moze chwile potrwac!)...", FRAMES_TO_SIMULATE);

        // Poczekaj aż VS opadnie na początku
        wait (vs == 1'b0);
        
        // Pętla odliczająca klatki wideo
        for (int i = 0; i <= FRAMES_TO_SIMULATE; i++) begin
            @(posedge vs);
            if (i > 0) begin
                // Wyświetlanie postępu, abyś wiedział, że symulacja nie "zamarzła"
                if (i % 10 == 0 || i == FRAMES_TO_SIMULATE) begin
                    $display("Info: Zapisano klatke %0d/%0d w czasie %0t", i, FRAMES_TO_SIMULATE, $time);
                end
            end
        end

        // Zakończenie symulacji
        $display("==================================================");
        $display("Symulacja animacji zakonczona sukcesem.");
        $display("Sprawdz folder 'results'. Klatki sa gotowe do zlaczenia!");
        $display("==================================================");
        
        $finish;
    end

endmodule