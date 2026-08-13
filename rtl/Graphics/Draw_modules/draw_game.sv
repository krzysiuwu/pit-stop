`timescale 1ns / 1ps
import vga_pkg::*;
import low_res_pkg::*;

module draw_game (
    input  logic clk,
    input  logic rst,

    // --- Sygnały stanu gry (FSM) ---
    input  logic [2:0]  current_state,
    input  logic signed [10:0] bolid_x, 

    // --- Interfejs myszy ---
    // (Koordynaty muszą być z pełnej rozdzielczości z MouseCtl)
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        left_click,

    // --- Sygnały wyjściowe do FSM (Kliknięcia) ---
    output logic click_play,
    output logic click_setup,
    output logic click_ready,
    output logic click_back,

    // --- Wejście potoku VGA (Od modułu draw_bg) ---
    input  logic [3:0]  lut_in,
    vga_if.in           vga_in,
    low_res_if.in       low_res_in,

    // --- Wyjście potoku VGA (Do LUT2RGB_converter) ---
    output logic [3:0]  lut_out,
    vga_if.out          vga_out
);

    // --------------------------------------------------------
    // Tłumaczenie Hitboxów Myszy (na układ Low Res 256x192)
    // --------------------------------------------------------
    logic [11:0] mx_low, my_low;
    assign mx_low = mouse_x >> 2;
    assign my_low = mouse_y >> 2;

    localparam int BTN_W = 78;
    localparam int BTN_H = 28;
    localparam int POS_CENTER_X = (256 - BTN_W) / 2; // Wyśrodkowane dla ekranu X=89

    logic hover_play, hover_setup, hover_ready, hover_back;
    
    // Obliczanie kolizji kursora z prostokątami przycisków
    assign hover_play  = (mx_low >= POS_CENTER_X) && (mx_low < POS_CENTER_X + BTN_W) && (my_low >= 70) && (my_low < 70 + BTN_H);
    assign hover_setup = (mx_low >= POS_CENTER_X) && (mx_low < POS_CENTER_X + BTN_W) && (my_low >= 110) && (my_low < 110 + BTN_H);
    assign hover_ready = (mx_low >= POS_CENTER_X) && (mx_low < POS_CENTER_X + BTN_W) && (my_low >= 80) && (my_low < 80 + BTN_H);
    assign hover_back  = (mx_low >= POS_CENTER_X) && (mx_low < POS_CENTER_X + BTN_W) && (my_low >= 140) && (my_low < 140 + BTN_H);

    // Wysyłanie pulsu "click", jeśli FSM znajduje się we właściwym stanie
    // Zapobiega to kliknięciu "w ciemno" niewidocznego przycisku
    assign click_play  = hover_play  && left_click && (current_state == 3'b000); // MENU
    assign click_setup = hover_setup && left_click && (current_state == 3'b000); // MENU
    assign click_ready = hover_ready && left_click && (current_state == 3'b010); // LOBBY
    assign click_back  = hover_back  && left_click && ((current_state == 3'b001) || (current_state == 3'b010) || (current_state == 3'b110)); // SETUP, LOBBY, DONE

    // --------------------------------------------------------
    // Logika sterowania widocznością 
    // --------------------------------------------------------
    logic en_logo, en_btn_play, en_btn_setup, en_btn_ready, en_btn_back;
    logic en_car_def, en_car_nw;

    always_comb begin
        en_logo      = (current_state == 3'b000); 
        en_btn_play  = (current_state == 3'b000); 
        en_btn_setup = (current_state == 3'b000); 
        en_btn_ready = (current_state == 3'b010); 
        en_btn_back  = (current_state == 3'b001) || (current_state == 3'b010) || (current_state == 3'b110); 
        
        // Zwykły bolid widoczny podczas wjazdu i wyjazdu
        en_car_def   = (current_state == 3'b011) || (current_state == 3'b101); 
        
        // Bolid bez kół widoczny tylko podczas obsługi (Pit Stopu)
        en_car_nw    = (current_state == 3'b100); 
    end

    // --------------------------------------------------------
    // Inicjalizacja linii potokowych (Pipeline)
    // --------------------------------------------------------
    vga_if vga_step1();
    vga_if vga_step2();
    vga_if vga_step3();
    vga_if vga_step4();
    vga_if vga_step5();
    vga_if vga_step6();

    logic [3:0] lut_step1, lut_step2, lut_step3, lut_step4, lut_step5, lut_step6;


    // Krok 2: Przycisk PLAY
    draw_button_with_text #(.STR_LEN(4)) u_btn_play (
        .clk(clk), .rst(rst), .enable(en_btn_play),
        .is_hovered(hover_play), .is_pressed(click_play), 
        .x_pos(POS_CENTER_X[11:0]), .y_pos(12'd70),
        .text_string("PLAY"),
        .lut_in(lut_step1), .vga_in(vga_step1), .low_res_in(low_res_in),
        .lut_out(lut_step2), .vga_out(vga_step2)
    );

    // Krok 3: Przycisk SETUP
    draw_button_with_text #(.STR_LEN(5)) u_btn_setup (
        .clk(clk), .rst(rst), .enable(en_btn_setup),
        .is_hovered(hover_setup), .is_pressed(click_setup),
        .x_pos(POS_CENTER_X[11:0]), .y_pos(12'd110),
        .text_string("SETUP"),
        .lut_in(lut_step2), .vga_in(vga_step2), .low_res_in(low_res_in),
        .lut_out(lut_step3), .vga_out(vga_step3)
    );

    // Krok 4: Przycisk READY
    draw_button_with_text #(.STR_LEN(5)) u_btn_ready (
        .clk(clk), .rst(rst), .enable(en_btn_ready),
        .is_hovered(hover_ready), .is_pressed(click_ready),
        .x_pos(POS_CENTER_X[11:0]), .y_pos(12'd80),
        .text_string("READY"),
        .lut_in(lut_step3), .vga_in(vga_step3), .low_res_in(low_res_in),
        .lut_out(lut_step4), .vga_out(vga_step4)
    );

    // Krok 5: Przycisk BACK
    draw_button_with_text #(.STR_LEN(4)) u_btn_back (
        .clk(clk), .rst(rst), .enable(en_btn_back),
        .is_hovered(hover_back), .is_pressed(click_back),
        .x_pos(POS_CENTER_X[11:0]), .y_pos(12'd140),
        .text_string("BACK"),
        .lut_in(lut_step4), .vga_in(vga_step4), .low_res_in(low_res_in),
        .lut_out(lut_step5), .vga_out(vga_step5)
    );

    // Krok 6: Bolid F1 (Standardowy - Z kołami)
    draw_BolidF1Default u_car_def (
        .clk(clk),
        .rst(rst),
        .enable(en_car_def),
        .x_pos({bolid_x[10], bolid_x}), // Rozszerzenie bitu znaku do 12 bitów
        .y_pos(12'd120),
        .lut_in(lut_step5),
        .vga_in(vga_step5),
        .low_res_in(low_res_in),
        .lut_out(lut_step6),
        .vga_out(vga_step6)
    );

    // Krok 7: Bolid F1 (Bez kół) - Podłączony bezpośrednio do wyjścia draw_game
    draw_BolidF1NoWheels u_car_nw (
        .clk(clk),
        .rst(rst),
        .enable(en_car_nw),
        .x_pos({bolid_x[10], bolid_x}), // Rozszerzenie bitu znaku do 12 bitów
        .y_pos(12'd120),
        .lut_in(lut_step6),
        .vga_in(vga_step6),
        .low_res_in(low_res_in),
        .lut_out(lut_out),
        .vga_out(vga_out) 
    );

endmodule