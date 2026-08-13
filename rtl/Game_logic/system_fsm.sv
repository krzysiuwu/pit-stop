module system_fsm (
    input  logic clk,
    input  logic rst,              

    // --- Sygnały z przycisków (np. z modułów mouse_hitbox) ---
    input  logic click_play,
    input  logic click_setup,
    input  logic click_back,
    
    // --- Sygnały synchronizacji ---
    input  logic frame_tick,       
    
    // --- Wyjścia do renderowania ---
    output logic [2:0] state_out,  
    output logic signed [11:0] bolid_x    
);

    timeunit 1ns;
    timeprecision 1ps;

    // Zdefiniowane 4 główne stany gry
    typedef enum logic [2:0] {
        MAIN_MENU = 3'b000, // Stan 1: Menu główne (Bolid w tle, przyciski Play, Options)
        OPTIONS   = 3'b001, // Stan 2: Opcje (Bolid w tle, przycisk Back)
        GAMEPLAY  = 3'b010, // Stan 3: Właściwa gra z kołem (Przycisk Back)
        SUMMARY   = 3'b011  // Stan 4: Podsumowanie (Przycisk Back)
    } state_t;

    state_t state, next_state;

    logic signed [11:0] current_x, next_x;

    // Parametry dla tła w Menu (dostosowane pod rozdzielczość 256x192)
    localparam int START_POS = 300;  // Zaczyna poza ekranem z prawej
    localparam int END_POS   = -200; // Kończy poza ekranem z lewej
    localparam int SPEED     = 2;    // Szybkość przejazdu w tle (piksele na klatkę)

    // =========================================================================
    // REJESTRY STANU
    // =========================================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state     <= MAIN_MENU;
            current_x <= START_POS;
        end else begin
            state     <= next_state;
            current_x <= next_x;
        end
    end

    // =========================================================================
    // LOGIKA PRZEJŚĆ I RUCHU
    // =========================================================================
    always_comb begin
        // Wartości domyślne (zatrzymanie stanu)
        next_state = state;
        next_x     = current_x;

        // --- Logika ruchu bolidu w tle (Tylko w MENU i OPTIONS) ---
        if (state == MAIN_MENU || state == OPTIONS) begin
            if (frame_tick) begin
                if (current_x <= END_POS) begin
                    next_x = START_POS; // Zapętlenie przelotu
                end else begin
                    next_x = current_x - SPEED; // Ciągły ruch w lewo
                end
            end
        end else begin
            next_x = START_POS; // Reset pozycji, gdy wchodzimy do gry
        end

        // --- Logika przechodzenia między ekranami ---
        case (state)
            MAIN_MENU: begin
                if (click_play) begin
                    next_state = GAMEPLAY;
                end else if (click_setup) begin
                    next_state = OPTIONS;
                end
            end

            OPTIONS: begin
                if (click_back) begin
                    next_state = MAIN_MENU;
                end
            end

            GAMEPLAY: begin
                // Tutaj dzieje się fizyka koła w innych modułach.
                // Maszyna stanów czeka tylko na wyjście z gry.
                if (click_back) begin
                    next_state = SUMMARY;
                end
            end

            SUMMARY: begin
                if (click_back) begin 
                    next_state = MAIN_MENU;
                end
            end

            default: next_state = MAIN_MENU;
        endcase
    end

    // =========================================================================
    // PRZYPISANIE WYJŚĆ
    // =========================================================================
    assign state_out = state;
    assign bolid_x   = current_x;

endmodule