/**
 * Module: anim_test
 * Summary: Builds a simulation-only VGA pipeline and scripted car sequence for animation verification.
 * Author: Adam Krupa
 */
module anim_test (
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
    // Internal signals and interfaces
    // -------------------------------------------------------------------------
    logic [11:0] rgb_pipe;

    low_res_if low_res_pipe();

    vga_if vga_timing_if();
    vga_if vga_step1_bg();
    vga_if vga_step2_btn1();
    vga_if vga_step3_btn2();
    vga_if vga_step4_btn3();
    vga_if vga_step5_bolid_def();
    vga_if vga_step6_bolid_nw();
    vga_if vga_step7_wheel();
    vga_if vga_upscale();

    logic [3:0] lut_step1_bg;
    logic [3:0] lut_step2_btn1;
    logic [3:0] lut_step3_btn2;
    logic [3:0] lut_step4_btn3;
    logic [3:0] lut_step5_bolid_def;
    logic [3:0] lut_step6_bolid_nw;
    logic [3:0] lut_step7_wheel;

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign vs = ~vga_upscale.vsync;
    assign hs = ~vga_upscale.hsync;
    
    assign r = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[11:8];
    assign g = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[7:4];
    assign b = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[3:0];

    // -------------------------------------------------------------------------
    // STAGE 0: VGA timing generator
    // -------------------------------------------------------------------------
    vga_timing u_vga_timing (
        .clk(clk),
        .rst(rst),
        .vga_out(vga_timing_if)
    );

    assign low_res_pipe.hcount = vga_timing_if.hcount >> 2;
    assign low_res_pipe.vcount = vga_timing_if.vcount >> 2;

    // -------------------------------------------------------------------------
    // STAGE 1: Background
    // -------------------------------------------------------------------------
    draw_bg u_draw_bg (
        .clk(clk),
        .rst(rst),
        .vga_in(vga_timing_if),
        .lut_out(lut_step1_bg),
        .vga_out(vga_step1_bg)
    );

    // -------------------------------------------------------------------------
    // STAGES 2-4: Buttons retained as static background layers
    // -------------------------------------------------------------------------
    draw_button_with_text #(.STR_LEN(6)) u_btn_normal (
        .clk(clk), .rst(rst), .enable(1'b1), .is_hovered(1'b0), .is_pressed(1'b0),
        .x_pos(12'd5), .y_pos(12'd20), .text_string("NORMAL"),
        .low_res_in(low_res_pipe), .lut_in(lut_step1_bg),
        .vga_in(vga_step1_bg),
        .lut_out(lut_step2_btn1), .vga_out(vga_step2_btn1)
    );

    draw_button_with_text #(.STR_LEN(5)) u_btn_hover (
        .clk(clk), .rst(rst), .enable(1'b1), .is_hovered(1'b1), .is_pressed(1'b0),
        .x_pos(12'd88), .y_pos(12'd20), .text_string("HOVER"),
        .low_res_in(low_res_pipe), .lut_in(lut_step2_btn1),
        .vga_in(vga_step2_btn1),
        .lut_out(lut_step3_btn2), .vga_out(vga_step3_btn2)
    );

    draw_button_with_text #(.STR_LEN(7)) u_btn_pressed (
        .clk(clk), .rst(rst), .enable(1'b1), .is_hovered(1'b1), .is_pressed(1'b1),
        .x_pos(12'd171), .y_pos(12'd20), .text_string("PRESSED"),
        .low_res_in(low_res_pipe), .lut_in(lut_step3_btn2),
        .vga_in(vga_step3_btn2),
        .lut_out(lut_step4_btn3), .vga_out(vga_step4_btn3)
    );

    // =========================================================================
    // CAR ANIMATION CONTROLLER AND SCRIPTED TEST EVENTS
    // =========================================================================
    logic trigger_arrive, trigger_depart;
    logic arrive_done, depart_done;
    logic car_enable;
    logic signed [11:0] car_x_pos;
    logic [1:0]  wheel_anim_step;

    logic vsync_prev;
    logic frame_tick;
    logic animation_started;
    logic [6:0] pitstop_frames;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vsync_prev <= 1'b0;
            frame_tick <= 1'b0;
        end else begin
            vsync_prev <= vga_upscale.vsync;
            frame_tick <= !vga_upscale.vsync && vsync_prev;
        end
    end

    // Script the control pulses used by the animation test.
    always_ff @(posedge clk) begin
        if (!rst) begin
            trigger_arrive <= 1'b0;
            trigger_depart <= 1'b0;
            animation_started <= 1'b0;
            pitstop_frames <= '0;
        end else begin
            trigger_arrive <= 1'b0;
            trigger_depart <= 1'b0;

            if (!animation_started) begin
                trigger_arrive <= 1'b1;
                animation_started <= 1'b1;
            end

            if (arrive_done && frame_tick) begin
                if (pitstop_frames == 7'd60) begin
                    trigger_depart <= 1'b1;
                end else begin
                    pitstop_frames <= pitstop_frames + 1'b1;
                end
            end
        end
    end

    bolid_anim_ctrl u_bolid_anim_ctrl (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .trigger_arrive(trigger_arrive),
        .trigger_depart(trigger_depart),
        .trigger_drive_through(1'b0),
        .arrive_done(arrive_done),
        .depart_done(depart_done),
        .car_enable(car_enable),
        .car_x_pos(car_x_pos),
        .wheel_anim_step(wheel_anim_step)
    );

    // -------------------------------------------------------------------------
    // STAGE 5: Animated complete F1 car
    // -------------------------------------------------------------------------
    // The current car renderer has no y_pos input.
    draw_BolidF1Default u_draw_bolid_def (
        .clk(clk),
        .rst(rst),
        .enable(car_enable),               // Visible only while the car is moving.
        .wheel_anim_step(wheel_anim_step), // Hardware-generated wheel animation phase.
        .x_pos(car_x_pos),                 // Pozycja z kontrolera animacji
        .lut_in(lut_step4_btn3),
        .vga_in(vga_step4_btn3),
        .lut_out(lut_step5_bolid_def),
        .vga_out(vga_step5_bolid_def)
    );

    // -------------------------------------------------------------------------
    // STAGE 6: Wheel-less F1 car during the pit stop
    // -------------------------------------------------------------------------
    draw_BolidF1NoWheels u_draw_bolid_nw (
        .clk(clk),
        .rst(rst),
        .enable(arrive_done), // Visible only while the car is stopped for service.
        .x_pos(12'd60),       // Fixed position matching POS_STOP in the animation controller.
        .y_pos(12'd120),
        .lut_in(lut_step5_bolid_def),
        .vga_in(vga_step5_bolid_def),
        .lut_out(lut_step6_bolid_nw),
        .vga_out(vga_step6_bolid_nw)
    );

    // -------------------------------------------------------------------------
    // STAGE 7: Pit-stop wheel
    // -------------------------------------------------------------------------
    draw_Wheel u_draw_wheel (
        .clk(clk),
        .rst(rst),
        .enable(arrive_done), // Visible only during wheel service.
        .wheel_anim_step(2'b00),
        .x_pos(12'd85),       // Position aligned with the car's wheel hub.
        .y_pos(12'd137),
        .lut_in(lut_step6_bolid_nw),
        .vga_in(vga_step6_bolid_nw),
        .lut_out(lut_step7_wheel),
        .vga_out(vga_step7_wheel)
    );

    // -------------------------------------------------------------------------
    // COLOR CONVERTER (palette index to physical RGB pins)
    // -------------------------------------------------------------------------
    LUT2RGB_converter u_LUT2RGB_converter (
        .clk(clk),
        .rst,
        
        .lut_value(lut_step7_wheel),
        .vga_in(vga_step7_wheel),
        
        .rgb_out(rgb_pipe),
        .vga_out(vga_upscale)
    );

endmodule
