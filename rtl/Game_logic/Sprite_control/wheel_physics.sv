module wheel_physics (
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,      
    
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_btn, 
    input  logic        is_hovered,
    
    input  logic [11:0] car_mount_x,
    input  logic [11:0] car_mount_y,
    
    output logic [11:0] wheel_x,
    output logic [11:0] wheel_y,
    output logic        is_removed 
);

    localparam int GROUND_LEVEL = 135;

    typedef enum logic [1:0] {
        MOUNTED,
        DRAGGED,
        AIRBORNE
    } wheel_state_t;

    wheel_state_t state, next_state;

    // Pozycje w formacie Fixed-Point Q12.4
    logic signed [15:0] pos_x, pos_y;
    logic signed [15:0] vel_x, vel_y;
    
    logic signed [11:0] prev_mouse_x, prev_mouse_y;

    localparam logic signed [15:0] GRAVITY          = 16'sd6;
    localparam logic signed [15:0] GROUND_LEVEL_Q   = GROUND_LEVEL * 16;
    localparam logic signed [15:0] MIN_BOUNCE_SPEED = 16'sd32;

    logic signed [15:0] next_pos_y;
    assign next_pos_y = pos_y + vel_y;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state        <= MOUNTED;
            pos_x        <= '0;
            pos_y        <= '0;
            vel_x        <= '0;
            vel_y        <= '0;
            prev_mouse_x <= '0;
            prev_mouse_y <= '0;
            is_removed   <= 1'b0;
        end else begin
            state <= next_state;

            if (frame_tick) begin
                prev_mouse_x <= mouse_x;
                prev_mouse_y <= mouse_y;

                case (state)
                    MOUNTED: begin
                        pos_x <= {1'b0, car_mount_x, 4'b0000}; 
                        pos_y <= {1'b0, car_mount_y, 4'b0000};
                        vel_x <= '0;
                        vel_y <= '0;
                        is_removed <= 1'b0;
                    end

                    DRAGGED: begin
                        pos_x <= {1'b0, mouse_x, 4'b0000};
                        pos_y <= {1'b0, mouse_y, 4'b0000};
                        is_removed <= 1'b1; 

                        // ZMIANA 1: <<< 3 zamiast <<< 4. 
                        // Mnożymy x8 zamiast x16, co ucina siłę wymachu myszą o połowę.
                        vel_x <= (signed'({1'b0, mouse_x}) - signed'({1'b0, prev_mouse_x})) <<< 3;
                        vel_y <= (signed'({1'b0, mouse_y}) - signed'({1'b0, prev_mouse_y})) <<< 3;
                    end

                    AIRBORNE: begin
                        pos_x <= pos_x + vel_x;

                        // Kolizję sprawdzamy dla pozycji z następnej klatki i
                        // tylko podczas ruchu w dół. Po odbiciu vel_y jest
                        // ujemne, więc koło może faktycznie odlecieć od ziemi.
                        if ((vel_y > 0) && (next_pos_y >= GROUND_LEVEL_Q)) begin
                            pos_y <= GROUND_LEVEL_Q;

                            // Bardzo małe odbicia wygaszamy, aby koło nie
                            // drgało bez końca na poziomie podłoża.
                            if (vel_y <= MIN_BOUNCE_SPEED)
                                vel_y <= '0;
                            else
                                vel_y <= -(vel_y - (vel_y >>> 3));

                            // Tarcie w poziomie działa podczas kontaktu z ziemią.
                            vel_x <= vel_x - (vel_x >>> 3);
                        end else if ((pos_y == GROUND_LEVEL_Q) && (vel_y == 0)) begin
                            // Koło pozostaje w spoczynku po wygaśnięciu odbić.
                            pos_y <= GROUND_LEVEL_Q;
                            vel_y <= '0;
                            vel_x <= vel_x - (vel_x >>> 3);
                        end else begin
                            pos_y <= next_pos_y;
                            vel_y <= vel_y + GRAVITY;
                        end
                    end
                endcase
            end
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            MOUNTED: if (is_hovered && mouse_btn) next_state = DRAGGED;
            DRAGGED: if (!mouse_btn) next_state = AIRBORNE;
            AIRBORNE: ; 
        endcase
    end

    assign wheel_x = pos_x[15:4];
    assign wheel_y = pos_y[15:4];

endmodule
