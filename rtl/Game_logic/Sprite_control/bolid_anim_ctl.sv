/**
 * Module: bolid_anim_ctrl
 * Summary: Controls the F1 car entry, braking, pit-stop hold, departure, and wheel animation phase.
 * Author: Adam Krupa
 */
module bolid_anim_ctrl (
        input  logic clk,
        input  logic rst,
        input  logic frame_tick,

        input  logic trigger_arrive,
        input  logic trigger_depart,
        input  logic trigger_drive_through,

        output logic arrive_done,
        output logic depart_done,

        output logic               car_enable,
        output logic signed [11:0] car_x_pos,
        output logic [1:0]         wheel_anim_step
    );

    timeunit 1ns;
    timeprecision 1ps;

    // Position and velocity use Q12.8 fixed-point representation.
    localparam int FP_SHIFT     = 8;
    localparam int POS_FP_WIDTH = 20;

    localparam logic signed [POS_FP_WIDTH-1:0] POS_START_FP = 20'sd260 <<< FP_SHIFT;
    localparam logic signed [POS_FP_WIDTH-1:0] POS_STOP_FP  = 20'sd60  <<< FP_SHIFT;
    localparam logic signed [POS_FP_WIDTH-1:0] POS_END_FP   = -20'sd170 <<< FP_SHIFT;

    // The profile targets approximately 60 frames per second: the car enters
    // quickly, brakes smoothly, then accelerates steadily after service.
    localparam logic [15:0] MAX_SPEED_FP           = 16'd896; // 3.50 px/klatke
    localparam logic [15:0] DEPART_START_SPEED_FP  = 16'd64;  // 0.25 px/klatke
    localparam logic [15:0] MIN_APPROACH_SPEED_FP  = 16'd64;
    localparam logic [15:0] ACCELERATION_FP        = 16'd8;   // 0.03125 px/klatke^2
    localparam logic [15:0] BRAKING_FP             = 16'd8;
    localparam logic [15:0] DRIVE_THROUGH_SPEED_FP = 16'd768; // 3.00 px/klatke

    // Advance the wheel color phase every four pixels of travel.
    localparam logic [15:0] WHEEL_STEP_DISTANCE_FP = 16'd1024;

    typedef enum logic [2:0] {
        IDLE,
        ARRIVING,
        PITSTOP_WAIT,
        DEPARTING,
        DRIVING_THROUGH,
        DONE
    } anim_state_t;

    anim_state_t state;

    logic signed [POS_FP_WIDTH-1:0] position_fp;
    logic signed [POS_FP_WIDTH-1:0] speed_fp_signed;
    logic signed [POS_FP_WIDTH-1:0] position_after_step;
    logic [15:0] speed_fp;
    logic [15:0] wheel_distance_fp;
    logic [1:0]  wheel_step;

    assign speed_fp_signed     = $signed({1'b0, speed_fp});
    assign position_after_step = position_fp - speed_fp_signed;

    function automatic logic [1:0] next_wheel_step(input logic [1:0] step);
        if (step == 2'd2)
            next_wheel_step = 2'd0;
        else
            next_wheel_step = step + 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst) begin
            state             <= IDLE;
            position_fp       <= POS_START_FP;
            speed_fp          <= '0;
            wheel_distance_fp <= '0;
            wheel_step        <= '0;
        end else if (trigger_arrive) begin
            // An arrival command may interrupt the menu animation, ensuring that
            // a new car always starts beyond the right edge after PLAY is selected.
            state             <= ARRIVING;
            position_fp       <= POS_START_FP;
            speed_fp          <= MAX_SPEED_FP;
            wheel_distance_fp <= '0;
            wheel_step        <= '0;
        end else if (trigger_drive_through) begin
            // Retriggering DONE loops the car pass on the menu screen.
            state             <= DRIVING_THROUGH;
            position_fp       <= POS_START_FP;
            speed_fp          <= DRIVE_THROUGH_SPEED_FP;
            wheel_distance_fp <= '0;
            wheel_step        <= '0;
        end else begin
            case (state)
                IDLE: begin
                    position_fp       <= POS_START_FP;
                    speed_fp          <= '0;
                    wheel_distance_fp <= '0;
                    wheel_step        <= '0;
                end

                ARRIVING: begin
                    if (frame_tick) begin
                        if (position_after_step <= POS_STOP_FP) begin
                            position_fp       <= POS_STOP_FP;
                            speed_fp          <= '0;
                            wheel_distance_fp <= '0;
                            state             <= PITSTOP_WAIT;
                        end else begin
                            position_fp <= position_after_step;

                            if (speed_fp > MIN_APPROACH_SPEED_FP + BRAKING_FP)
                                speed_fp <= speed_fp - BRAKING_FP;
                            else
                                speed_fp <= MIN_APPROACH_SPEED_FP;

                            if (wheel_distance_fp + speed_fp >= WHEEL_STEP_DISTANCE_FP) begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp
                                    - WHEEL_STEP_DISTANCE_FP;
                                wheel_step <= next_wheel_step(wheel_step);
                            end else begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp;
                            end
                        end
                    end
                end

                PITSTOP_WAIT: begin
                    position_fp       <= POS_STOP_FP;
                    speed_fp          <= '0;
                    wheel_distance_fp <= '0;

                    if (trigger_depart) begin
                        state    <= DEPARTING;
                        speed_fp <= DEPART_START_SPEED_FP;
                    end
                end

                DEPARTING: begin
                    if (frame_tick) begin
                        if (position_after_step <= POS_END_FP) begin
                            position_fp       <= POS_END_FP;
                            speed_fp          <= '0;
                            wheel_distance_fp <= '0;
                            state             <= DONE;
                        end else begin
                            position_fp <= position_after_step;

                            if (speed_fp < MAX_SPEED_FP - ACCELERATION_FP)
                                speed_fp <= speed_fp + ACCELERATION_FP;
                            else
                                speed_fp <= MAX_SPEED_FP;

                            if (wheel_distance_fp + speed_fp >= WHEEL_STEP_DISTANCE_FP) begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp
                                    - WHEEL_STEP_DISTANCE_FP;
                                wheel_step <= next_wheel_step(wheel_step);
                            end else begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp;
                            end
                        end
                    end
                end

                DRIVING_THROUGH: begin
                    if (frame_tick) begin
                        if (position_after_step <= POS_END_FP) begin
                            position_fp       <= POS_END_FP;
                            speed_fp          <= '0;
                            wheel_distance_fp <= '0;
                            state             <= DONE;
                        end else begin
                            position_fp <= position_after_step;
                            speed_fp    <= DRIVE_THROUGH_SPEED_FP;

                            if (wheel_distance_fp + speed_fp >= WHEEL_STEP_DISTANCE_FP) begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp
                                    - WHEEL_STEP_DISTANCE_FP;
                                wheel_step <= next_wheel_step(wheel_step);
                            end else begin
                                wheel_distance_fp <= wheel_distance_fp + speed_fp;
                            end
                        end
                    end
                end

                DONE: begin
                    speed_fp          <= '0;
                    wheel_distance_fp <= '0;
                end

                default: begin
                    state             <= IDLE;
                    position_fp       <= POS_START_FP;
                    speed_fp          <= '0;
                    wheel_distance_fp <= '0;
                    wheel_step        <= '0;
                end
            endcase
        end
    end

    assign car_x_pos       = position_fp >>> FP_SHIFT;
    assign wheel_anim_step = wheel_step;

    // A separate wheel-less car sprite is rendered during service.
    assign car_enable = (state == ARRIVING) ||
        (state == DEPARTING) ||
        (state == DRIVING_THROUGH);

    assign arrive_done = (state == PITSTOP_WAIT);
    assign depart_done = (state == DONE);

endmodule
