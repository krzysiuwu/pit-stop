module wheel_service_fsm #(
    parameter int SCROLL_STEPS_REQUIRED        = 6,
    parameter bit LOOSEN_WITH_NEGATIVE_SCROLL = 1'b1,
    parameter bit INITIAL_MOUNT_IS_REAR        = 1'b0
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic              wheel_hovered,
    input  logic              rack_take_pulse,
    input  logic              mouse_new_event,
    input  logic signed [3:0] mouse_scroll,
    input  logic              mouse_btn,

    input  logic wheel_detached,
    input  logic wheel_dragging,
    input  logic wheel_removed,
    input  logic wheel_near_front_mount,
    input  logic wheel_near_rear_mount,
    input  logic front_mount_available,
    input  logic rear_mount_available,

    output logic grab_enable,
    output logic attach_to_anchor,
    output logic anchor_at_rack,
    output logic anchor_at_rear,
    output logic mounted_at_rear,
    output logic wheel_visible,
    output logic wheel_locked,
    output logic old_wheel_removed,
    output logic needs_new_wheel,
    output logic new_wheel_active,
    output logic service_done,

    output logic [1:0] wheel_anim_step,
    output logic [3:0] service_progress,
    output logic [3:0] state_debug
);

    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [3:0] {
        OLD_LOCKED,
        OLD_LOOSE,
        DISCARDING_OLD,
        WAITING_FOR_NEW,
        NEW_AT_RACK,
        MOVING_NEW,
        NEW_POSITIONED,
        SERVICE_DONE
    } wheel_service_state_t;

    wheel_service_state_t state;

    logic scroll_positive;
    logic scroll_negative;
    logic loosen_scroll;
    logic tighten_scroll;
    logic target_rear;
    logic snap_to_front;
    logic snap_to_rear;
    logic snap_to_mount;

    assign scroll_positive = mouse_new_event && (mouse_scroll > 0);
    assign scroll_negative = mouse_new_event && (mouse_scroll < 0);

    // Kierunek mozna odwrocic jednym parametrem po tescie myszy PS/2.
    assign loosen_scroll = LOOSEN_WITH_NEGATIVE_SCROLL ?
                           scroll_negative : scroll_positive;
    assign tighten_scroll = LOOSEN_WITH_NEGATIVE_SCROLL ?
                            scroll_positive : scroll_negative;

    // Nowe kola sa wymienne. O miejscu montazu decyduje polozenie kola
    // w chwili puszczenia myszy, a nie instancja FSM, ktora wydala je z racka.
    assign snap_to_front = wheel_dragging && !mouse_btn &&
                           wheel_near_front_mount && front_mount_available;
    assign snap_to_rear  = wheel_dragging && !mouse_btn &&
                           wheel_near_rear_mount && rear_mount_available;
    assign snap_to_mount = snap_to_front || snap_to_rear;

    // Polozenie zamontowanego kola musi zalezec wylacznie od rejestru.
    // anchor_at_rear moze chwilowo wskazywac cel zatrzasniecia w MOVING_NEW,
    // dlatego nie wolno uzywac go do wyznaczania zajetosci piast.
    assign mounted_at_rear = target_rear;

    function automatic logic [1:0] rotate_forward(input logic [1:0] step);
        if (step == 2'd2)
            rotate_forward = 2'd0;
        else
            rotate_forward = step + 1'b1;
    endfunction

    function automatic logic [1:0] rotate_backward(input logic [1:0] step);
        if (step == 2'd0)
            rotate_backward = 2'd2;
        else
            rotate_backward = step - 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst) begin
            state            <= OLD_LOCKED;
            service_progress <= '0;
            wheel_anim_step  <= '0;
            target_rear      <= INITIAL_MOUNT_IS_REAR;
        end else if (!enable) begin
            // Kazdy nowy bolid rozpoczyna pelny cykl z zalozonym starym kolem.
            state            <= OLD_LOCKED;
            service_progress <= '0;
            wheel_anim_step  <= '0;
            target_rear      <= INITIAL_MOUNT_IS_REAR;
        end else begin
            case (state)
                OLD_LOCKED: begin
                    if (wheel_hovered && loosen_scroll) begin
                        wheel_anim_step <= rotate_backward(wheel_anim_step);

                        if (service_progress == SCROLL_STEPS_REQUIRED - 1) begin
                            service_progress <= service_progress + 1'b1;
                            state            <= OLD_LOOSE;
                        end else begin
                            service_progress <= service_progress + 1'b1;
                        end
                    end else if (wheel_hovered && tighten_scroll) begin
                        wheel_anim_step <= rotate_forward(wheel_anim_step);

                        if (service_progress != 0)
                            service_progress <= service_progress - 1'b1;
                    end
                end

                OLD_LOOSE: begin
                    if (wheel_detached)
                        state <= DISCARDING_OLD;
                end

                DISCARDING_OLD: begin
                    if (wheel_removed) begin
                        state            <= WAITING_FOR_NEW;
                        service_progress <= '0;
                        wheel_anim_step  <= '0;
                    end
                end

                WAITING_FOR_NEW: begin
                    if (rack_take_pulse) begin
                        state            <= NEW_AT_RACK;
                        service_progress <= '0;
                        wheel_anim_step  <= '0;
                        target_rear      <= INITIAL_MOUNT_IS_REAR;
                    end
                end

                NEW_AT_RACK: begin
                    if (wheel_detached)
                        state <= MOVING_NEW;
                end

                MOVING_NEW: begin
                    // Upuszczenie kolejnego kola poza ekranem nie blokuje gry.
                    if (wheel_removed) begin
                        state            <= WAITING_FOR_NEW;
                        service_progress <= '0;
                        wheel_anim_step  <= '0;
                        target_rear      <= INITIAL_MOUNT_IS_REAR;
                    end else if (snap_to_mount) begin
                        state            <= NEW_POSITIONED;
                        service_progress <= '0;
                        target_rear      <= snap_to_rear;
                    end
                end

                NEW_POSITIONED: begin
                    if (wheel_hovered && tighten_scroll) begin
                        wheel_anim_step <= rotate_forward(wheel_anim_step);

                        if (service_progress == SCROLL_STEPS_REQUIRED - 1) begin
                            service_progress <= service_progress + 1'b1;
                            state            <= SERVICE_DONE;
                        end else begin
                            service_progress <= service_progress + 1'b1;
                        end
                    end else if (wheel_hovered && loosen_scroll) begin
                        wheel_anim_step <= rotate_backward(wheel_anim_step);

                        if (service_progress != 0)
                            service_progress <= service_progress - 1'b1;
                    end
                end

                SERVICE_DONE: begin
                    state <= SERVICE_DONE;
                end

                default: begin
                    state            <= OLD_LOCKED;
                    service_progress <= '0;
                    wheel_anim_step  <= '0;
                    target_rear      <= INITIAL_MOUNT_IS_REAR;
                end
            endcase
        end
    end

    always_comb begin
        grab_enable      = 1'b0;
        attach_to_anchor = 1'b0;
        anchor_at_rack   = 1'b0;
        anchor_at_rear   = target_rear;
        wheel_visible    = 1'b0;
        wheel_locked     = 1'b0;
        old_wheel_removed = 1'b0;
        needs_new_wheel  = 1'b0;
        new_wheel_active = 1'b0;
        service_done     = 1'b0;

        case (state)
            OLD_LOCKED: begin
                wheel_visible = enable;
                wheel_locked  = 1'b1;
            end

            OLD_LOOSE,
            DISCARDING_OLD: begin
                wheel_visible = enable;
                grab_enable   = enable;
            end

            WAITING_FOR_NEW: begin
                old_wheel_removed = 1'b1;
                needs_new_wheel   = enable;

                if (rack_take_pulse) begin
                    // Przeniesienie fizyki z wyrzuconej pozycji na rack.
                    attach_to_anchor = 1'b1;
                    anchor_at_rack   = 1'b1;
                    anchor_at_rear   = INITIAL_MOUNT_IS_REAR;
                end
            end

            NEW_AT_RACK: begin
                wheel_visible     = enable;
                grab_enable       = enable;
                anchor_at_rack    = 1'b1;
                old_wheel_removed = 1'b1;
                new_wheel_active  = 1'b1;
            end

            MOVING_NEW: begin
                wheel_visible     = enable;
                grab_enable       = enable;
                old_wheel_removed = 1'b1;
                new_wheel_active  = 1'b1;

                // Zwolnienie przycisku blisko piasty powoduje zatrzasniecie
                // kola dokladnie w pozycji montazowej.
                if (snap_to_mount) begin
                    attach_to_anchor = 1'b1;
                    anchor_at_rear   = snap_to_rear;
                end
            end

            NEW_POSITIONED: begin
                wheel_visible     = enable;
                wheel_locked      = 1'b1;
                old_wheel_removed = 1'b1;
                new_wheel_active  = 1'b1;
            end

            SERVICE_DONE: begin
                wheel_visible     = enable;
                wheel_locked      = 1'b1;
                old_wheel_removed = 1'b1;
                new_wheel_active  = 1'b1;
                service_done      = enable;
            end

            default: begin
                wheel_locked = 1'b1;
            end
        endcase
    end

    assign state_debug = state;

endmodule
