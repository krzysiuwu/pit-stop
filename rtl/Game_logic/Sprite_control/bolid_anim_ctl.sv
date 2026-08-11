module bolid_anim_ctrl (
    input  logic clk,
    input  logic rst,

    // --- Sygnały od/do głównej maszyny stanów gry (Game FSM) ---
    input  logic trigger_arrive,  // Sygnał startu wjazdu
    input  logic trigger_depart,  // Sygnał startu odjazdu po zmianie kół
    
    output logic arrive_done,     // Informuje Game FSM, że bolid stoi w pit stopie
    output logic depart_done,     // Informuje Game FSM, że bolid zniknął za ekranem

    // --- Sygnały sterujące modułem rysującym (draw_BolidF1Default) ---
    output logic        car_enable,
    output logic [11:0] car_x_pos,
    output logic [1:0]  wheel_anim_step
);

    // Pozycje na ekranie (zakładając low_res_in 256x192)
    localparam int POS_START = 260; // Poza ekranem z prawej
    localparam int POS_STOP  = 60;  // Miejsce zatrzymania w pit stopie
    localparam int POS_END   = -170; // Poza ekranem z lewej (bolid ma 165px szerokości)

    // Stany kontrolera animacji
    typedef enum logic [2:0] {
        IDLE,           // Oczekiwanie na wjazd
        ARRIVING,       // Wjazd do pit stopu (z hamowaniem)
        PITSTOP_WAIT,   // Oczekiwanie na zmianę kół
        DEPARTING,      // Odjazd (z przyspieszeniem)
        DONE            // Koniec
    } anim_state_t;

    anim_state_t state, next_state;

    // --- Rejestry i liczniki ---
    logic signed [12:0] current_x;       
    logic [19:0]        speed_counter;   // Licznik opóźnienia ruchu (steruje prędkością)
    logic [19:0]        speed_threshold; // Próg licznika (mniejszy = szybciej, większy = wolniej)
    logic [1:0]         wheel_step;      // Aktualna klatka animacji kół

    // --- Logika ruchu i animacji ---
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state           <= IDLE;
            current_x       <= POS_START;
            speed_counter   <= '0;
            speed_threshold <= 20'd30_000; // Szybki wjazd na start
            wheel_step      <= '0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    current_x       <= POS_START;
                    speed_threshold <= 20'd30_000; // Niski próg -> duża prędkość na starcie
                    wheel_step      <= '0;
                    if (trigger_arrive) speed_counter <= '0;
                end

                ARRIVING: begin
                    speed_counter <= speed_counter + 1'b1;
                    if (speed_counter >= speed_threshold) begin
                        speed_counter <= '0;
                        current_x     <= current_x - 1'b1; // Przesunięcie w lewo
                        
                        // HAMOWANIE: Zwiększamy próg opóźnienia z każdym pikselem
                        // Bolid będzie zwalniał, aż próg osiągnie dużą wartość przed samym zatrzymaniem
                        if (speed_threshold < 20'd900_000) begin
                            speed_threshold <= speed_threshold + 20'd4_000; 
                        end
                        
                        // Animacja koła (kręci się proporcjonalnie do aktualnej prędkości)
                        if (wheel_step == 2'd2) wheel_step <= '0;
                        else                    wheel_step <= wheel_step + 1'b1;
                    end
                end

                PITSTOP_WAIT: begin
                    // Bolid stoi w miejscu, resetujemy liczniki pod start odjazdu
                    speed_counter   <= '0;
                    speed_threshold <= 20'd900_000; // Wysoki próg -> bolid rusza bardzo ciężko i powoli
                end

                DEPARTING: begin
                    speed_counter <= speed_counter + 1'b1;
                    if (speed_counter >= speed_threshold) begin
                        speed_counter <= '0;
                        current_x     <= current_x - 1'b1;
                        
                        // PRZYSPIESZANIE: Zmniejszamy próg opóźnienia
                        if (speed_threshold > 20'd30_000) begin
                            speed_threshold <= speed_threshold - 20'd6_000;
                        end

                        // Animacja koła
                        if (wheel_step == 2'd2) wheel_step <= '0;
                        else                    wheel_step <= wheel_step + 1'b1;
                    end
                end

                DONE: begin
                    // Koniec sekwencji
                end
            endcase
        end
    end

    // --- Przejścia między stanami ---
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (trigger_arrive) next_state = ARRIVING;
            end
            ARRIVING: begin
                if (current_x <= POS_STOP) next_state = PITSTOP_WAIT;
            end
            PITSTOP_WAIT: begin
                if (trigger_depart) next_state = DEPARTING;
            end
            DEPARTING: begin
                if (current_x <= POS_END) next_state = DONE;
            end
            DONE: begin
                // Zostaje w DONE, główna maszyna stanów może to ewentualnie zresetować
            end
        endcase
    end

    // --- Przypisanie wyjść ---
    assign car_x_pos       = current_x[11:0]; 
    assign wheel_anim_step = wheel_step;

    // Bolid widoczny tylko podczas jazdy
    assign car_enable = (state == ARRIVING || state == DEPARTING);

    // Wysyłanie statusu do głównego modułu logicznego gry
    assign arrive_done = (state == PITSTOP_WAIT);
    assign depart_done = (state == DONE);

endmodule