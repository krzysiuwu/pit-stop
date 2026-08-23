module wheel_physics #(
        parameter int SCREEN_WIDTH  = 256,
        parameter int SCREEN_HEIGHT = 192,
        parameter int WHEEL_WIDTH   = 26,
        parameter int WHEEL_HEIGHT  = 27,
        parameter int GROUND_LEVEL  = 137
)(
        input  logic clk,
        input  logic rst,
        input  logic frame_tick,

        input  logic [11:0] mouse_x,
        input  logic [11:0] mouse_y,
        input  logic        mouse_btn,
        input  logic        is_hovered,

        input  logic signed [11:0] anchor_x,
        input  logic signed [11:0] anchor_y,
        input  logic               attach_to_anchor,

        input  logic grab_enable,

        output logic signed [11:0] wheel_x,
        output logic signed [11:0] wheel_y,
        output logic               is_detached,
        output logic               is_dragging,
        output logic               is_removed
    );

    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [1:0] {
        MOUNTED,
        DRAGGED,
        AIRBORNE
    } wheel_state_t;

    wheel_state_t state, next_state;

    // Pozycja i predkosc w formacie Q12.4.
    logic signed [15:0] pos_x, pos_y;
    logic signed [15:0] vel_x, vel_y;

    logic signed [12:0] mouse_x_signed;
    logic signed [12:0] mouse_y_signed;
    logic signed [12:0] prev_mouse_x;
    logic signed [12:0] prev_mouse_y;
    logic signed [12:0] drag_offset_x;
    logic signed [12:0] drag_offset_y;

    logic signed [15:0] anchor_x_q;
    logic signed [15:0] anchor_y_q;
    logic signed [15:0] dragged_x_q;
    logic signed [15:0] dragged_y_q;
    logic signed [15:0] next_pos_y;

    localparam logic signed [15:0] GRAVITY          = 16'sd6;
    localparam logic signed [15:0] GROUND_LEVEL_Q   = GROUND_LEVEL * 16;
    localparam logic signed [15:0] MIN_BOUNCE_SPEED = 16'sd32;
    localparam logic signed [15:0] MIN_SLIDE_SPEED  = 16'sd4;

    function automatic logic signed [15:0] pixels_to_q(
            input logic signed [12:0] pixels
        );
        pixels_to_q = $signed({{3{pixels[12]}}, pixels}) <<< 4;
    endfunction

    assign mouse_x_signed = $signed({1'b0, mouse_x});
    assign mouse_y_signed = $signed({1'b0, mouse_y});

    assign anchor_x_q = pixels_to_q($signed({anchor_x[11], anchor_x}));
    assign anchor_y_q = pixels_to_q($signed({anchor_y[11], anchor_y}));
    assign dragged_x_q = pixels_to_q(mouse_x_signed - drag_offset_x);
    assign dragged_y_q = pixels_to_q(mouse_y_signed - drag_offset_y);
    assign next_pos_y  = pos_y + vel_y;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state         <= MOUNTED;
            pos_x         <= '0; // Constant reset value avoids LDC/P latch inference
            pos_y         <= '0; // Constant reset value avoids LDC/P latch inference
            vel_x         <= '0;
            vel_y         <= '0;
            prev_mouse_x  <= '0;
            prev_mouse_y  <= '0;
            drag_offset_x <= '0;
            drag_offset_y <= '0;
        end else begin
            state <= next_state;

            // Miejsce chwycenia jest zachowane, wiec kolo nie przeskakuje
            // srodkiem pod kursor po nacisnieciu przycisku.
            if ((state != DRAGGED) && (next_state == DRAGGED)) begin
                drag_offset_x <= mouse_x_signed - (pos_x >>> 4);
                drag_offset_y <= mouse_y_signed - (pos_y >>> 4);
                prev_mouse_x  <= mouse_x_signed;
                prev_mouse_y  <= mouse_y_signed;
            end

            // Impuls jest uzywany przy pobraniu kola z racka oraz po
            // odlozeniu nowego kola w poblizu piasty.
            if (attach_to_anchor) begin
                state         <= MOUNTED;
                pos_x         <= anchor_x_q;
                pos_y         <= anchor_y_q;
                vel_x         <= '0;
                vel_y         <= '0;
                prev_mouse_x  <= mouse_x_signed;
                prev_mouse_y  <= mouse_y_signed;
                drag_offset_x <= '0;
                drag_offset_y <= '0;
            end else if (frame_tick) begin
                case (state)
                    MOUNTED: begin
                        pos_x <= anchor_x_q;
                        pos_y <= anchor_y_q;
                        vel_x <= '0;
                        vel_y <= '0;

                        prev_mouse_x <= mouse_x_signed;
                        prev_mouse_y <= mouse_y_signed;
                    end

                    DRAGGED: begin
                        pos_x <= dragged_x_q;
                        pos_y <= dragged_y_q;

                        // Polowa przesuniecia kursora na klatke daje wyrazny,
                        // ale nadal kontrolowalny rzut.
                        vel_x <= pixels_to_q(mouse_x_signed - prev_mouse_x) >>> 1;
                        vel_y <= pixels_to_q(mouse_y_signed - prev_mouse_y) >>> 1;

                        prev_mouse_x <= mouse_x_signed;
                        prev_mouse_y <= mouse_y_signed;
                    end

                    AIRBORNE: begin
                        pos_x <= pos_x + vel_x;

                        if ((vel_y > 0) && (next_pos_y >= GROUND_LEVEL_Q)) begin
                            pos_y <= GROUND_LEVEL_Q;

                            if (vel_y <= MIN_BOUNCE_SPEED)
                                vel_y <= '0;
                            else
                                vel_y <= -(vel_y - (vel_y >>> 3));

                            if ((vel_x <= MIN_SLIDE_SPEED) &&
                                    (vel_x >= -MIN_SLIDE_SPEED))
                                vel_x <= '0;
                            else
                                vel_x <= vel_x - (vel_x >>> 3);
                        end else if ((pos_y == GROUND_LEVEL_Q) && (vel_y == 0)) begin
                            pos_y <= GROUND_LEVEL_Q;
                            vel_y <= '0;

                            if ((vel_x <= MIN_SLIDE_SPEED) &&
                                    (vel_x >= -MIN_SLIDE_SPEED))
                                vel_x <= '0;
                            else
                                vel_x <= vel_x - (vel_x >>> 3);
                        end else begin
                            pos_y <= next_pos_y;
                            vel_y <= vel_y + GRAVITY;
                        end
                    end

                    default: begin
                        pos_x <= anchor_x_q;
                        pos_y <= anchor_y_q;
                        vel_x <= '0;
                        vel_y <= '0;
                    end
                endcase
            end
        end
    end

    always_comb begin
        next_state = state;

        case (state)
            MOUNTED: begin
                if (grab_enable && is_hovered && mouse_btn)
                    next_state = DRAGGED;
            end

            DRAGGED: begin
                if (!mouse_btn)
                    next_state = AIRBORNE;
            end

            AIRBORNE: begin
                // Po nieudanym rzucie kolo nadal mozna podniesc.
                if (grab_enable && is_hovered && mouse_btn)
                    next_state = DRAGGED;
            end

            default: begin
                next_state = MOUNTED;
            end
        endcase
    end

    // Direct output assignments
    assign wheel_x = (state == MOUNTED) ? anchor_x : (pos_x >>> 4);
    assign wheel_y = (state == MOUNTED) ? anchor_y : (pos_y >>> 4);
    assign is_detached = (state != MOUNTED);
    assign is_dragging = (state == DRAGGED);

    // Stare kolo jest uznane za wyrzucone dopiero, gdy caly sprite opusci ekran.
    assign is_removed = is_detached &&
        (((wheel_x + WHEEL_WIDTH)  <= 0)          ||
            (wheel_x >= SCREEN_WIDTH)                 ||
            ((wheel_y + WHEEL_HEIGHT) <= 0)          ||
            (wheel_y >= SCREEN_HEIGHT));

endmodule
