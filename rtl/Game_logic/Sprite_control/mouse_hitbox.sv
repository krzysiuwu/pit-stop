module mouse_hitbox (
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

    // 2. Detektor zbocza narastającego dla kliknięcia
    logic mouse_btn_prev;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            mouse_btn_prev <= 1'b0;
            is_clicked     <= 1'b0;
        end else begin
            mouse_btn_prev <= mouse_btn;
            
            // Reaguj tylko, jeśli mysz jest w hitboxie I przycisk właśnie został wciśnięty
            if (is_hovered && mouse_btn && !mouse_btn_prev) begin
                is_clicked <= 1'b1;
            end else begin
                is_clicked <= 1'b0;
            end
        end
    end

endmodule