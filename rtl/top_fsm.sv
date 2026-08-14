module top_fsm (
    input  logic clk,
    input  logic rst,       // Active Low (przychodzi jako 1 z top_vga_basys3)
    
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    output logic hs,
    output logic vs,
    
    inout  logic ps2_data,
    inout  logic ps2_clk
);

    timeunit 1ns;
    timeprecision 1ps;

    // =========================================================================
    // 1. SPRZĘTOWA MYSZKA PS/2 (Moduł VHDL)
    // =========================================================================
    logic [11:0] mouse_x, mouse_y;
    logic mouse_btn_left;

    // Moduł VHDL MouseCtl korzysta z resetu aktywnego stanem WYSOKIM
    MouseCtl u_mouse_ctl (
        .clk(clk),
        .rst(~rst), 
        .xpos(mouse_x),
        .ypos(mouse_y),
        .left(mouse_btn_left),
        .value(12'b0),
        .setx(1'b0),
        .sety(1'b0),
        .setmax_x(1'b0),
        .setmax_y(1'b0),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data)
    );

    // Konwersja z 1024x768 do 256x192
    logic [11:0] low_res_mouse_x, low_res_mouse_y;
    assign low_res_mouse_x = mouse_x >> 2;
    assign low_res_mouse_y = mouse_y >> 2;

    // =========================================================================
    // 2. KANAŁY WIDEO (PIPELINE)
    // =========================================================================
    low_res_if low_res_pipe();
    vga_if vga_timing_if();
    vga_if vga_bg();
    vga_if vga_bolid();
    vga_if vga_btn_play();
    vga_if vga_btn_opts();
    vga_if vga_btn_back();
    vga_if vga_wheel();
    vga_if vga_cursor();
    vga_if vga_upscale();

    logic [3:0] lut_bg, lut_bolid, lut_btn_play, lut_btn_opts, lut_btn_back, lut_wheel, lut_cursor;
    logic [11:0] rgb_pipe;

    assign vs = ~vga_upscale.vsync;
    assign hs = ~vga_upscale.hsync;
    assign r = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[11:8];
    assign g = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[7:4];
    assign b = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[3:0];

    vga_timing u_vga_timing (.clk(clk), .rst(rst), .vga_out(vga_timing_if), .low_res_out(low_res_pipe));

    // =========================================================================
    // 3. GENERATOR FRAME TICK (60 Hz dla fizyki)
    // =========================================================================
    logic vsync_prev;
    logic frame_tick;
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vsync_prev <= 1'b0;
            frame_tick <= 1'b0;
        end else begin
            vsync_prev <= vga_upscale.vsync;
            if (!vga_upscale.vsync && vsync_prev) frame_tick <= 1'b1;
            else                                  frame_tick <= 1'b0;
        end
    end

    // =========================================================================
    // 4. MASZYNA STANÓW GRY (FSM)
    // =========================================================================
    logic [2:0] sys_state;
    logic signed [11:0] bolid_bg_x;
    logic play_clicked, opts_clicked, back_clicked;

    system_fsm u_sys_fsm (
        .clk(clk), .rst(rst),
        .click_play(play_clicked),
        .click_setup(opts_clicked),
        .click_back(back_clicked),
        .frame_tick(frame_tick),
        .state_out(sys_state),
        .bolid_x(bolid_bg_x)
    );

    localparam logic [2:0] ST_MAIN_MENU = 3'b000;
    localparam logic [2:0] ST_OPTIONS   = 3'b001;
    localparam logic [2:0] ST_GAMEPLAY  = 3'b010;
    localparam logic [2:0] ST_SUMMARY   = 3'b011;

    // =========================================================================
    // 5. ENABLE OBIEKTÓW I POZYCJE UI
    // =========================================================================
    logic en_bolid, en_btn_play, en_btn_opts, en_btn_back, en_wheel;
    
    assign en_bolid    = (sys_state == ST_MAIN_MENU || sys_state == ST_OPTIONS);
    assign en_btn_play = (sys_state == ST_MAIN_MENU);
    assign en_btn_opts = (sys_state == ST_MAIN_MENU);
    assign en_btn_back = (sys_state != ST_MAIN_MENU);
    assign en_wheel    = (sys_state == ST_GAMEPLAY);

    localparam int BTN_PLAY_X = 108, BTN_PLAY_Y = 60, BTN_W = 40, BTN_H = 15;
    localparam int BTN_OPTS_X = 108, BTN_OPTS_Y = 90;
    localparam int BTN_BACK_X = 210, BTN_BACK_Y = 5;

    // =========================================================================
    // 6. HITBOXY Z PRZYCISKÓW I MYSZY
    // =========================================================================
    logic play_hover, opts_hover, back_hover, wheel_hover;
    logic wheel_click;

    mouse_hitbox u_hitbox_play (
        .clk(clk), .rst(rst), .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(en_btn_play ? 12'(BTN_PLAY_X) : -12'sd100), .obj_y(12'(BTN_PLAY_Y)), .obj_w(12'(BTN_W)), .obj_h(12'(BTN_H)),
        .is_hovered(play_hover), .is_clicked(play_clicked)
    );

    mouse_hitbox u_hitbox_opts (
        .clk(clk), .rst(rst), .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(en_btn_opts ? 12'(BTN_OPTS_X) : -12'sd100), .obj_y(12'(BTN_OPTS_Y)), .obj_w(12'(BTN_W)), .obj_h(12'(BTN_H)),
        .is_hovered(opts_hover), .is_clicked(opts_clicked)
    );

    mouse_hitbox u_hitbox_back (
        .clk(clk), .rst(rst), .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(en_btn_back ? 12'(BTN_BACK_X) : -12'sd100), .obj_y(12'(BTN_BACK_Y)), .obj_w(12'(BTN_W)), .obj_h(12'(BTN_H)),
        .is_hovered(back_hover), .is_clicked(back_clicked)
    );

    // =========================================================================
    // 7. FIZYKA KOŁA I RESPAWN
    // =========================================================================
    logic [11:0] dyn_wheel_x, dyn_wheel_y;
    logic wheel_is_removed, do_respawn, wheel_rst_n;
    logic [7:0] respawn_timer;

    mouse_hitbox u_hitbox_wheel (
        .clk(clk), .rst(rst), .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(en_wheel ? dyn_wheel_x : -12'sd100), .obj_y(dyn_wheel_y), .obj_w(12'd24), .obj_h(12'd24),
        .is_hovered(wheel_hover), .is_clicked(wheel_click)
    );

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            respawn_timer <= '0;
            do_respawn    <= 1'b0;
        end else begin
            do_respawn <= 1'b0; 
            if (frame_tick && en_wheel) begin
                if (wheel_is_removed) begin
                    if (respawn_timer < 8'd120) respawn_timer <= respawn_timer + 1'b1;
                    else begin do_respawn <= 1'b1; respawn_timer <= '0; end
                end else respawn_timer <= '0;
            end
        end
    end

    assign wheel_rst_n = rst & ~do_respawn & en_wheel; 

    wheel_physics u_wheel_physics (
        .clk(clk), .rst(wheel_rst_n), .frame_tick(frame_tick),
        .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y), .mouse_btn(mouse_btn_left), .is_hovered(wheel_hover), 
        .car_mount_x(12'd100), .car_mount_y(12'd130),
        .wheel_x(dyn_wheel_x), .wheel_y(dyn_wheel_y),
        .is_removed(wheel_is_removed)
    );

    // =========================================================================
    // 8. RYSOWANIE POTOKU GRAFICZNEGO
    // =========================================================================
    draw_bg u_draw_bg (
        .clk(clk), .rst(rst), .low_res_in(low_res_pipe), 
        .vga_in(vga_timing_if), .lut_out(lut_bg), .vga_out(vga_bg)
    );

    draw_BolidF1Default u_draw_bolid_bg (
        .clk(clk), .rst(rst), .enable(en_bolid), 
        .wheel_anim_step(2'b00), 
        .x_pos(bolid_bg_x), 
        .low_res_in(low_res_pipe), .lut_in(lut_bg), .vga_in(vga_bg), 
        .lut_out(lut_bolid), .vga_out(vga_bolid)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_play (
        .clk(clk), .rst(rst), .enable(en_btn_play),
        .is_hovered(play_hover), .is_pressed(play_hover && mouse_btn_left),
        .x_pos(12'(BTN_PLAY_X)), .y_pos(12'(BTN_PLAY_Y)), .text_string("PLAY"),
        .low_res_in(low_res_pipe), .lut_in(lut_bolid), .vga_in(vga_bolid),
        .lut_out(lut_btn_play), .vga_out(vga_btn_play)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_opts (
        .clk(clk), .rst(rst), .enable(en_btn_opts),
        .is_hovered(opts_hover), .is_pressed(opts_hover && mouse_btn_left),
        .x_pos(12'(BTN_OPTS_X)), .y_pos(12'(BTN_OPTS_Y)), .text_string("OPTS"),
        .low_res_in(low_res_pipe), .lut_in(lut_btn_play), .vga_in(vga_btn_play),
        .lut_out(lut_btn_opts), .vga_out(vga_btn_opts)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_back (
        .clk(clk), .rst(rst), .enable(en_btn_back),
        .is_hovered(back_hover), .is_pressed(back_hover && mouse_btn_left),
        .x_pos(12'(BTN_BACK_X)), .y_pos(12'(BTN_BACK_Y)), .text_string("BACK"),
        .low_res_in(low_res_pipe), .lut_in(lut_btn_opts), .vga_in(vga_btn_opts),
        .lut_out(lut_btn_back), .vga_out(vga_btn_back)
    );

    draw_Wheel u_draw_wheel (
        .clk(clk), .rst(rst), .enable(en_wheel), 
        .x_pos(dyn_wheel_x), .y_pos(dyn_wheel_y), 
        .low_res_in(low_res_pipe), .lut_in(lut_btn_back), .vga_in(vga_btn_back), 
        .lut_out(lut_wheel), .vga_out(vga_wheel)
    );

    // --- SYSTEM ZMIANY KURSORA ---
    logic [1:0] current_cursor;
    always_comb begin
        if (en_wheel && wheel_hover && !wheel_is_removed) current_cursor = 2'b10;
        else if (play_hover || opts_hover || back_hover)  current_cursor = 2'b01; 
        else if (en_wheel && wheel_hover && wheel_is_removed) current_cursor = 2'b01;
        else current_cursor = 2'b00; 
    end

    draw_mouse_cursor u_draw_cursor (
        .clk(clk), .rst(rst), .enable(1'b1),
        .cursor_type(current_cursor),
        .mouse_x(low_res_mouse_x), .mouse_y(low_res_mouse_y),
        .low_res_in(low_res_pipe), .lut_in(lut_wheel), .vga_in(vga_wheel),
        .lut_out(lut_cursor), .vga_out(vga_cursor)
    );

    LUT2RGB_converter u_LUT2RGB_converter (
        .clk(clk), .rst_n(rst), .lut_value(lut_cursor), .vga_in(vga_cursor),
        .rgb_out(rgb_pipe), .vga_out(vga_upscale)
    );

endmodule