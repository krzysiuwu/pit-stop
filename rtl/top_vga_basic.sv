/**
 * Basic VGA Top Module
 * Description:
 * Modul top do wyswietlania tla i zbuforowanego potoku sprite'ow.
 */

module top_vga_basic (
        input  logic clk,
        input  logic rst,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    // -------------------------------------------------------------------------
    // Sygnały wewnętrzne i Interfejsy
    // -------------------------------------------------------------------------
    logic [11:0] rgb_pipe;

    // Współrzędne o niskiej rozdzielczości wspóldzielone dla wszystkich modułów
    low_res_if low_res_pipe();

    // Magistrale VGA przekazujące koordynaty między etapami
    vga_if vga_timing_if();
    vga_if vga_step1_bg();
    vga_if vga_step2_wr();
    vga_if vga_step3_str();
    vga_if vga_step4_logo();
    vga_if vga_upscale();

    // Sygnały z kolorami wędrujące z warstwy na warstwę
    logic [3:0] lut_step1_bg;
    logic [3:0] lut_step2_wr;
    logic [3:0] lut_step3_str;
    logic [3:0] lut_step4_logo;


    // -------------------------------------------------------------------------
    // Przypisanie wyjść
    // -------------------------------------------------------------------------
    assign vs = ~vga_upscale.vsync;
    assign hs = ~vga_upscale.hsync;
    
    // Zabezpieczenie sprzętowe: Wygaszanie kolorów poza obszarem ekranu
    assign r = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[11:8];
    assign g = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[7:4];
    assign b = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[3:0];


    // -------------------------------------------------------------------------
    // ETAP 0: Generator Synchronizacji
    // -------------------------------------------------------------------------
    vga_timing u_vga_timing (
        .clk(clk),
        .rst(rst),
        .vga_out(vga_timing_if),
        .low_res_out(low_res_pipe)
    );

    // -------------------------------------------------------------------------
    // ETAP 1: Tło (Najniższa warstwa - generuje pierwotny kolor)
    // -------------------------------------------------------------------------
    draw_bg u_draw_bg (
        .clk(clk),
        .rst(rst),
        .low_res_in(low_res_pipe),
        .vga_in(vga_timing_if),
        
        .lut_out(lut_step1_bg),
        .vga_out(vga_step1_bg)
    );

    // -------------------------------------------------------------------------
    // ETAP 2: Stojak z Oponami (Krok 2)
    // -------------------------------------------------------------------------
    draw_WheelRack u_draw_WheelRack (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .x_pos(12'd10),     // Ustaw testową pozycję X
        .y_pos(12'd120),    // Ustaw testową pozycję Y
        .low_res_in(low_res_pipe),
        
        // Wejście z Etapu 1
        .lut_in(lut_step1_bg),
        .vga_in(vga_step1_bg),
        
        // Wyjście do Etapu 3
        .lut_out(lut_step2_wr),
        .vga_out(vga_step2_wr)
    );

    // -------------------------------------------------------------------------
    // ETAP 3: Napis na ekranie (Krok 3)
    // -------------------------------------------------------------------------
    draw_string #(
        .MAX_CHARS(10)
    ) u_draw_string (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .x_pos(12'd88),     // Centrowanie w osi X
        .y_pos(12'd100),
        .text_string(" PIT STOP "), // Równo 10 znaków
        .text_color(4'hE),  // Żółty z Twojej palety
        .low_res_in(low_res_pipe),
        
        // Wejście z Etapu 2
        .lut_in(lut_step2_wr),
        .vga_in(vga_step2_wr),
        
        // Wyjście do Etapu 4
        .lut_out(lut_step3_str),
        .vga_out(vga_step3_str)
    );

    // -------------------------------------------------------------------------
    // ETAP 4: Animowane Logo (Krok 4 - Najwyższa warstwa)
    // -------------------------------------------------------------------------
    draw_PitstopLogo u_draw_logo (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .x_pos(12'd64),
        .y_pos(12'd10),
        .low_res_in(low_res_pipe),
        
        // Wejście z Etapu 3
        .lut_in(lut_step3_str),
        .vga_in(vga_step3_str),
        
        // Wyjście do Konwertera
        .lut_out(lut_step4_logo),
        .vga_out(vga_step4_logo)
    );

    // -------------------------------------------------------------------------
    // KONWERTER KOLORÓW (LUT -> FIZYCZNE Piny)
    // -------------------------------------------------------------------------
    LUT2RGB_converter u_LUT2RGB_converter (
        .clk(clk),
        .rst_n(rst),
        
        // Przyjmujemy zsumowane kolory z najwyższej warstwy (Logo)
        .lut_value(lut_step4_logo),
        .vga_in(vga_step4_logo),
        
        .rgb_out(rgb_pipe),
        .vga_out(vga_upscale)
    );

endmodule