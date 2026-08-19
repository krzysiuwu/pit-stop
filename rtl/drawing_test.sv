/**
 * Basic VGA Top Module
 * Description:
 * Modul top do wyswietlania tla i potoku testowego dla nowych sprite'ow.
 */

module drawing_test (
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

    low_res_if low_res_pipe();

    // Magistrale VGA przekazujące koordynaty między etapami
    vga_if vga_timing_if();
    vga_if vga_step1_bg();
    vga_if vga_step2_btn1();
    vga_if vga_step3_btn2();
    vga_if vga_step4_btn3();
    vga_if vga_step5_bolid_def();
    vga_if vga_step6_bolid_nw();
    vga_if vga_step7_wheel();
    vga_if vga_upscale();

    // Sygnały z kolorami wędrujące z warstwy na warstwę
    logic [3:0] lut_step1_bg;
    logic [3:0] lut_step2_btn1;
    logic [3:0] lut_step3_btn2;
    logic [3:0] lut_step4_btn3;
    logic [3:0] lut_step5_bolid_def;
    logic [3:0] lut_step6_bolid_nw;
    logic [3:0] lut_step7_wheel;


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
        .vga_out(vga_timing_if)
    );

    assign low_res_pipe.hcount = vga_timing_if.hcount >> 2;
    assign low_res_pipe.vcount = vga_timing_if.vcount >> 2;

    // -------------------------------------------------------------------------
    // ETAP 1: Tło
    // -------------------------------------------------------------------------
    draw_bg u_draw_bg (
        .clk(clk),
        .rst(rst),
        .vga_in(vga_timing_if),
        
        .lut_out(lut_step1_bg),
        .vga_out(vga_step1_bg)
    );

    // -------------------------------------------------------------------------
    // ETAP 2: Przycisk 1 (Stan: Normalny)
    // -------------------------------------------------------------------------

    draw_button_with_text #(
        .STR_LEN(6) // Słowo ma dokładnie 6 liter
    ) u_btn_normal (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .is_hovered(1'b0),
        .is_pressed(1'b0),
        .x_pos(12'd5),
        .y_pos(12'd20),
        .text_string("NORMAL"), // Bez spacji!
        .low_res_in(low_res_pipe),
        
        .lut_in(lut_step1_bg),
        .vga_in(vga_step1_bg),
        .lut_out(lut_step2_btn1),
        .vga_out(vga_step2_btn1)
    );

    // -------------------------------------------------------------------------
    // ETAP 3: Przycisk 2 (Stan: Hovered)
    // -------------------------------------------------------------------------
    draw_button_with_text #(
        .STR_LEN(5) // Słowo ma dokładnie 5 liter
    ) u_btn_hover (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .is_hovered(1'b1),
        .is_pressed(1'b0),
        .x_pos(12'd88),
        .y_pos(12'd20),
        .text_string("HOVER"), // Bez spacji!
        .low_res_in(low_res_pipe),
        
        .lut_in(lut_step2_btn1),
        .vga_in(vga_step2_btn1),
        .lut_out(lut_step3_btn2),
        .vga_out(vga_step3_btn2)
    );

    // -------------------------------------------------------------------------
    // ETAP 4: Przycisk 3 (Stan: Pressed)
    // -------------------------------------------------------------------------
    draw_button_with_text #(
        .STR_LEN(7) // Słowo ma dokładnie 7 liter
    ) u_btn_pressed (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .is_hovered(1'b1),
        .is_pressed(1'b1),
        .x_pos(12'd171),
        .y_pos(12'd20),
        .text_string("PRESSED"), // Bez spacji!
        .low_res_in(low_res_pipe),
        
        .lut_in(lut_step3_btn2),
        .vga_in(vga_step3_btn2),
        .lut_out(lut_step4_btn3),
        .vga_out(vga_step4_btn3)
    );

    // -------------------------------------------------------------------------
    // ETAP 5: Bolid F1 (Domyślny / Z kołami)
    // -------------------------------------------------------------------------
    draw_BolidF1Default u_draw_bolid_def (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .wheel_anim_step(2'b00),
        .x_pos(12'd10),
        .lut_in(lut_step4_btn3),
        .vga_in(vga_step4_btn3),
        .lut_out(lut_step5_bolid_def),
        .vga_out(vga_step5_bolid_def)
    );

    // -------------------------------------------------------------------------
    // ETAP 6: Bolid F1 (Bez kół - podczas Pit Stopu)
    // -------------------------------------------------------------------------
    draw_BolidF1NoWheels u_draw_bolid_nw (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .x_pos(12'd140),
        .y_pos(12'd120),
        .lut_in(lut_step5_bolid_def),
        .vga_in(vga_step5_bolid_def),
        .lut_out(lut_step6_bolid_nw),
        .vga_out(vga_step6_bolid_nw)
    );

    // -------------------------------------------------------------------------
    // ETAP 7: Opona (Do testu zmiany kół)
    // -------------------------------------------------------------------------
    draw_Wheel u_draw_wheel (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .wheel_anim_step(2'b00),
        .x_pos(12'd110),
        .y_pos(12'd160),
        .lut_in(lut_step6_bolid_nw),
        .vga_in(vga_step6_bolid_nw),
        .lut_out(lut_step7_wheel),
        .vga_out(vga_step7_wheel)
    );

    // -------------------------------------------------------------------------
    // KONWERTER KOLORÓW (LUT -> FIZYCZNE Piny)
    // -------------------------------------------------------------------------
    LUT2RGB_converter u_LUT2RGB_converter (
        .clk(clk),
        .rst_n(rst),
        
        // Przyjmujemy zsumowane kolory z ostatniej warstwy (Koła)
        .lut_value(lut_step7_wheel),
        .vga_in(vga_step7_wheel),
        
        .rgb_out(rgb_pipe),
        .vga_out(vga_upscale)
    );

endmodule
