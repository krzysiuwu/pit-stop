module mouse_hitbox #(
    // Przyciski interfejsu powinny aktywowac akcje dopiero po puszczeniu
    // myszy, aby stan wcisniety zdazyl zostac narysowany. Obiekty gry
    // (np. wheelrack) zachowuja domyslna reakcje na wcisniecie.
    parameter bit CLICK_ON_RELEASE = 1'b0
)(
    input  logic clk,
    input  logic rst,
    
    // Sygnały globalne myszy
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_btn,     // Lewy przycisk myszy
    
    // Właściwości przypisanego obiektu (Mogą być dynamiczne!)
    input  logic [11:0] obj_x,
    input  logic [11:0] obj_y,
    input  logic [11:0] obj_w,
    input  logic [11:0] obj_h,
    
    // Wyniki detekcji
    output logic is_hovered,
    output logic is_clicked            // Impuls trwający 1 takt zegara
);

    // 1. Sprawdzenie, czy kursor jest wewnątrz prostokąta
    assign is_hovered =
        (mouse_x >= obj_x) &&
        (mouse_x <  obj_x + obj_w) &&
        (mouse_y >= obj_y) &&
        (mouse_y <  obj_y + obj_h);

    // 2. Detektor klikniecia
    logic mouse_btn_prev;
    logic press_armed;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            mouse_btn_prev <= 1'b0;
            press_armed     <= 1'b0;
            is_clicked     <= 1'b0;
        end else begin
            mouse_btn_prev <= mouse_btn;

            // Kazdy impuls klikniecia trwa dokladnie jeden takt.
            is_clicked <= 1'b0;

            if (mouse_btn && !mouse_btn_prev) begin
                press_armed <= is_hovered;

                if (!CLICK_ON_RELEASE && is_hovered)
                    is_clicked <= 1'b1;
            end else if (!mouse_btn && mouse_btn_prev) begin
                if (CLICK_ON_RELEASE && press_armed && is_hovered)
                    is_clicked <= 1'b1;

                press_armed <= 1'b0;
            end else if (mouse_btn && press_armed && !is_hovered) begin
                // Wyjazd kursorem poza przycisk anuluje klikniecie.
                press_armed <= 1'b0;
            end
        end
    end

endmodule
