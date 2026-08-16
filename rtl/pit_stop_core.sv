module pit_stop_core (
    input  logic clk,
    input  logic rst,

    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_btn_left,
    input  logic signed [3:0] mouse_scroll,
    input  logic              mouse_new_event,
    input  logic [15:0]       switches,

    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    output logic hs,
    output logic vs,

    output logic       option_multiplayer,
    output logic [1:0] option_game_mode,
    output logic [7:0] option_target_value,

    output logic [11:0] vga_x,
    output logic [11:0] vga_y
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [11:0] BTN_PLAY_X = 12'd108;
    localparam logic [11:0] BTN_PLAY_Y = 12'd60;
    localparam logic [11:0] BTN_OPTS_X = 12'd108;
    localparam logic [11:0] BTN_OPTS_Y = 12'd90;
    localparam logic [11:0] BTN_BACK_X = 12'd140;
    localparam logic [11:0] BTN_BACK_Y = 12'd5;
    localparam logic [11:0] BTN_WIDTH  = 12'd78;
    localparam logic [11:0] BTN_HEIGHT = 12'd28;

    localparam logic [11:0] RACK_X = 12'd2;
    localparam logic [11:0] RACK_Y = 12'd112;
    localparam logic [11:0] RACK_WIDTH  = 12'd52;
    localparam logic [11:0] RACK_HEIGHT = 12'd45;

    // Pozycje sa zgodne ze sprite'em BolidF1Default (samochod: x=60, y=120).
    localparam logic signed [11:0] FRONT_MOUNT_X = 12'sd84;
    localparam logic signed [11:0] REAR_MOUNT_X  = 12'sd192;
    localparam logic signed [11:0] MOUNT_Y       = 12'sd137;
    localparam logic signed [11:0] RACK_PICK_X   = 12'sd16;
    localparam logic signed [11:0] RACK_PICK_Y   = 12'sd121;
    localparam logic signed [11:0] MOUNT_MARGIN  = 12'sd12;

    // -------------------------------------------------------------------------
    // Potok wideo
    // -------------------------------------------------------------------------
    low_res_if low_res_pipe();
    vga_if vga_timing_if();
    vga_if vga_bg();
    vga_if vga_bolid_default();
    vga_if vga_bolid_no_wheels();
    vga_if vga_rack();
    vga_if vga_options_panel();
    vga_if vga_btn_play();
    vga_if vga_btn_opts();
    vga_if vga_btn_back();
    vga_if vga_front_wheel();
    vga_if vga_rear_wheel();
    vga_if vga_cursor();
    vga_if vga_upscale();

    logic [3:0] lut_bg;
    logic [3:0] lut_bolid_default;
    logic [3:0] lut_bolid_no_wheels;
    logic [3:0] lut_rack;
    logic [3:0] lut_options_panel;
    logic [3:0] lut_btn_play;
    logic [3:0] lut_btn_opts;
    logic [3:0] lut_btn_back;
    logic [3:0] lut_front_wheel;
    logic [3:0] lut_rear_wheel;
    logic [3:0] lut_cursor;
    logic [11:0] rgb_pipe;

    assign vs = ~vga_upscale.vsync;
    assign hs = ~vga_upscale.hsync;
    assign r  = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[11:8];
    assign g  = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[7:4];
    assign b  = (vga_upscale.hblnk || vga_upscale.vblnk) ? 4'h0 : rgb_pipe[3:0];
    assign vga_x = {1'b0, vga_upscale.hcount};
    assign vga_y = {1'b0, vga_upscale.vcount};

    vga_timing u_vga_timing (
        .clk(clk),
        .rst(rst),
        .vga_out(vga_timing_if),
        .low_res_out(low_res_pipe)
    );

    // Jedyny zegar logiki animacji jest wyprowadzony ze zbocza synchronizacji
    // pionowej. Pozycje obiektow nie zmieniaja sie podczas rysowania klatki.
    logic vsync_prev;
    logic frame_tick;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vsync_prev <= 1'b0;
            frame_tick <= 1'b0;
        end else begin
            vsync_prev <= vga_upscale.vsync;
            frame_tick <= !vga_upscale.vsync && vsync_prev;
        end
    end

    // -------------------------------------------------------------------------
    // Systemowa maszyna stanow i animacja bolidu
    // -------------------------------------------------------------------------
    logic [2:0] system_screen;
    logic [3:0] sequence_debug;
    logic enable_bolid_default;
    logic enable_bolid_no_wheels;
    logic enable_button_play;
    logic enable_button_options;
    logic enable_button_back;
    logic enable_wheel_rack;
    logic enable_wheel_service;
    logic signed [11:0] bolid_x;
    logic [1:0] bolid_wheel_anim_step;

    game_options u_game_options (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .multiplayer(option_multiplayer),
        .game_mode(option_game_mode),
        .target_value(option_target_value)
    );

    logic play_clicked;
    logic options_clicked;
    logic back_clicked;
    logic front_service_done;
    logic rear_service_done;

    system_fsm u_system_fsm (
        .clk(clk),
        .rst(rst),
        .click_play(play_clicked),
        .click_setup(options_clicked),
        .click_back(back_clicked),
        .frame_tick(frame_tick),
        .front_wheel_done(front_service_done),
        .rear_wheel_done(rear_service_done),
        .state_out(system_screen),
        .enable_bolid_default(enable_bolid_default),
        .enable_bolid_no_wheels(enable_bolid_no_wheels),
        .enable_button_play(enable_button_play),
        .enable_button_options(enable_button_options),
        .enable_button_back(enable_button_back),
        .enable_wheel_rack(enable_wheel_rack),
        .enable_wheel_service(enable_wheel_service),
        .bolid_x(bolid_x),
        .bolid_wheel_anim_step(bolid_wheel_anim_step),
        .sequence_debug(sequence_debug)
    );

    // -------------------------------------------------------------------------
    // Przyciski i rack
    // -------------------------------------------------------------------------
    logic play_hover;
    logic options_hover;
    logic back_hover;
    logic rack_hover;
    logic rack_clicked;

    mouse_hitbox #(
        .CLICK_ON_RELEASE(1'b1)
    ) u_hitbox_play (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(enable_button_play ? BTN_PLAY_X : 12'hfff),
        .obj_y(BTN_PLAY_Y), .obj_w(BTN_WIDTH), .obj_h(BTN_HEIGHT),
        .is_hovered(play_hover), .is_clicked(play_clicked)
    );

    mouse_hitbox #(
        .CLICK_ON_RELEASE(1'b1)
    ) u_hitbox_options (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(enable_button_options ? BTN_OPTS_X : 12'hfff),
        .obj_y(BTN_OPTS_Y), .obj_w(BTN_WIDTH), .obj_h(BTN_HEIGHT),
        .is_hovered(options_hover), .is_clicked(options_clicked)
    );

    mouse_hitbox #(
        .CLICK_ON_RELEASE(1'b1)
    ) u_hitbox_back (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(enable_button_back ? BTN_BACK_X : 12'hfff),
        .obj_y(BTN_BACK_Y), .obj_w(BTN_WIDTH), .obj_h(BTN_HEIGHT),
        .is_hovered(back_hover), .is_clicked(back_clicked)
    );

    mouse_hitbox u_hitbox_rack (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(enable_wheel_rack ? RACK_X : 12'hfff),
        .obj_y(RACK_Y), .obj_w(RACK_WIDTH), .obj_h(RACK_HEIGHT),
        .is_hovered(rack_hover), .is_clicked(rack_clicked)
    );

    // -------------------------------------------------------------------------
    // Dwa niezalezne stanowiska wymiany kol
    // -------------------------------------------------------------------------
    logic signed [11:0] front_wheel_x;
    logic signed [11:0] front_wheel_y;
    logic signed [11:0] rear_wheel_x;
    logic signed [11:0] rear_wheel_y;

    logic front_hover;
    logic rear_hover;
    logic front_clicked;
    logic rear_clicked;
    logic front_grab_enable;
    logic rear_grab_enable;
    logic front_attach;
    logic rear_attach;
    logic front_anchor_at_rack;
    logic rear_anchor_at_rack;
    logic front_anchor_at_rear;
    logic rear_anchor_at_rear;
    logic front_visible;
    logic rear_visible;
    logic front_locked;
    logic rear_locked;
    logic front_old_removed;
    logic rear_old_removed;
    logic front_needs_new;
    logic rear_needs_new;
    logic front_new_active;
    logic rear_new_active;
    logic front_detached;
    logic rear_detached;
    logic front_dragging;
    logic rear_dragging;
    logic front_removed;
    logic rear_removed;
    logic front_wheel_near_front_mount;
    logic front_wheel_near_rear_mount;
    logic rear_wheel_near_front_mount;
    logic rear_wheel_near_rear_mount;
    logic front_mount_occupied;
    logic rear_mount_occupied;
    logic front_mount_available;
    logic rear_mount_available;
    logic front_new_mounted;
    logic rear_new_mounted;
    logic front_grab_to_physics;
    logic rear_grab_to_physics;
    logic front_rack_take;
    logic rear_rack_take;
    logic rack_select_rear;
    logic [1:0] front_wheel_anim_step;
    logic [1:0] rear_wheel_anim_step;
    logic [3:0] front_progress;
    logic [3:0] rear_progress;
    logic [3:0] front_state_debug;
    logic [3:0] rear_state_debug;
    logic wheel_rst;

    logic signed [11:0] front_anchor_x;
    logic signed [11:0] front_anchor_y;
    logic signed [11:0] rear_anchor_x;
    logic signed [11:0] rear_anchor_y;

    assign wheel_rst = rst & enable_wheel_service;

    assign front_anchor_x = front_anchor_at_rack ? RACK_PICK_X :
                            front_anchor_at_rear ? REAR_MOUNT_X : FRONT_MOUNT_X;
    assign front_anchor_y = front_anchor_at_rack ? RACK_PICK_Y : MOUNT_Y;
    assign rear_anchor_x  = rear_anchor_at_rack ? RACK_PICK_X :
                            rear_anchor_at_rear ? REAR_MOUNT_X : FRONT_MOUNT_X;
    assign rear_anchor_y  = rear_anchor_at_rack ? RACK_PICK_Y : MOUNT_Y;

    assign front_wheel_near_front_mount =
        (front_wheel_x >= FRONT_MOUNT_X - MOUNT_MARGIN) &&
        (front_wheel_x <= FRONT_MOUNT_X + MOUNT_MARGIN) &&
        (front_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
        (front_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

    assign front_wheel_near_rear_mount =
        (front_wheel_x >= REAR_MOUNT_X - MOUNT_MARGIN) &&
        (front_wheel_x <= REAR_MOUNT_X + MOUNT_MARGIN) &&
        (front_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
        (front_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

    assign rear_wheel_near_front_mount =
        (rear_wheel_x >= FRONT_MOUNT_X - MOUNT_MARGIN) &&
        (rear_wheel_x <= FRONT_MOUNT_X + MOUNT_MARGIN) &&
        (rear_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
        (rear_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

    assign rear_wheel_near_rear_mount =
        (rear_wheel_x >= REAR_MOUNT_X - MOUNT_MARGIN) &&
        (rear_wheel_x <= REAR_MOUNT_X + MOUNT_MARGIN) &&
        (rear_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
        (rear_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

    // Piasty naleza do samochodu, nie do konkretnej instancji kola. Po
    // wyrzuceniu starych kol kazda nowa opona moze zajac dowolna wolna piaste.
    assign front_new_mounted = front_new_active && front_locked;
    assign rear_new_mounted  = rear_new_active && rear_locked;

    assign front_mount_occupied =
        (!front_old_removed && !front_detached) ||
        (front_new_mounted && !front_anchor_at_rear) ||
        (rear_new_mounted  && !rear_anchor_at_rear);

    assign rear_mount_occupied =
        (!rear_old_removed && !rear_detached) ||
        (front_new_mounted && front_anchor_at_rear) ||
        (rear_new_mounted  && rear_anchor_at_rear);

    assign front_mount_available = !front_mount_occupied;
    assign rear_mount_available  = !rear_mount_occupied;

    // Przy nakladajacych sie hitboxach tylko gorne (pozniej renderowane) kolo
    // moze przejac mysz. Zapobiega to jednoczesnemu przeciaganiu obu kol.
    assign front_grab_to_physics = front_grab_enable && !rear_dragging &&
                                   !(rear_grab_enable && rear_hover);
    assign rear_grab_to_physics  = rear_grab_enable && !front_dragging;

    // Rack zapamietuje, ktore stanowisko zaczelo czekac jako pierwsze. Dzieki
    // temu kola mozna zdejmowac w dowolnej kolejnosci.
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            rack_select_rear <= 1'b0;
        end else if (!enable_wheel_service) begin
            rack_select_rear <= 1'b0;
        end else if (front_needs_new && !rear_needs_new) begin
            rack_select_rear <= 1'b0;
        end else if (rear_needs_new && !front_needs_new) begin
            rack_select_rear <= 1'b1;
        end else if (front_rack_take) begin
            rack_select_rear <= 1'b1;
        end else if (rear_rack_take) begin
            rack_select_rear <= 1'b0;
        end
    end

    assign front_rack_take = rack_clicked && front_needs_new &&
                             (!rear_needs_new || !rack_select_rear);
    assign rear_rack_take  = rack_clicked && rear_needs_new &&
                             (!front_needs_new || rack_select_rear);

    mouse_hitbox u_hitbox_front_wheel (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(front_visible ? $unsigned(front_wheel_x) : 12'hfff),
        .obj_y($unsigned(front_wheel_y)), .obj_w(12'd26), .obj_h(12'd27),
        .is_hovered(front_hover), .is_clicked(front_clicked)
    );

    mouse_hitbox u_hitbox_rear_wheel (
        .clk(clk), .rst(rst),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_btn(mouse_btn_left),
        .obj_x(rear_visible ? $unsigned(rear_wheel_x) : 12'hfff),
        .obj_y($unsigned(rear_wheel_y)), .obj_w(12'd26), .obj_h(12'd27),
        .is_hovered(rear_hover), .is_clicked(rear_clicked)
    );

    wheel_physics u_front_wheel_physics (
        .clk(clk), .rst(wheel_rst), .frame_tick(frame_tick),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_btn(mouse_btn_left), .is_hovered(front_hover),
        .anchor_x(front_anchor_x), .anchor_y(front_anchor_y),
        .attach_to_anchor(front_attach), .grab_enable(front_grab_to_physics),
        .wheel_x(front_wheel_x), .wheel_y(front_wheel_y),
        .is_detached(front_detached), .is_dragging(front_dragging),
        .is_removed(front_removed)
    );

    wheel_physics u_rear_wheel_physics (
        .clk(clk), .rst(wheel_rst), .frame_tick(frame_tick),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_btn(mouse_btn_left), .is_hovered(rear_hover),
        .anchor_x(rear_anchor_x), .anchor_y(rear_anchor_y),
        .attach_to_anchor(rear_attach), .grab_enable(rear_grab_to_physics),
        .wheel_x(rear_wheel_x), .wheel_y(rear_wheel_y),
        .is_detached(rear_detached), .is_dragging(rear_dragging),
        .is_removed(rear_removed)
    );

    wheel_service_fsm #(
        .INITIAL_MOUNT_IS_REAR(1'b0)
    ) u_front_wheel_service (
        .clk(clk), .rst(rst), .enable(enable_wheel_service),
        .wheel_hovered(front_hover), .rack_take_pulse(front_rack_take),
        .mouse_new_event(mouse_new_event), .mouse_scroll(mouse_scroll),
        .mouse_btn(mouse_btn_left),
        .wheel_detached(front_detached), .wheel_dragging(front_dragging),
        .wheel_removed(front_removed),
        .wheel_near_front_mount(front_wheel_near_front_mount),
        .wheel_near_rear_mount(front_wheel_near_rear_mount),
        .front_mount_available(front_mount_available),
        .rear_mount_available(rear_mount_available),
        .grab_enable(front_grab_enable), .attach_to_anchor(front_attach),
        .anchor_at_rack(front_anchor_at_rack),
        .anchor_at_rear(front_anchor_at_rear), .wheel_visible(front_visible),
        .wheel_locked(front_locked), .old_wheel_removed(front_old_removed),
        .needs_new_wheel(front_needs_new), .new_wheel_active(front_new_active),
        .service_done(front_service_done), .wheel_anim_step(front_wheel_anim_step),
        .service_progress(front_progress), .state_debug(front_state_debug)
    );

    wheel_service_fsm #(
        .INITIAL_MOUNT_IS_REAR(1'b1)
    ) u_rear_wheel_service (
        .clk(clk), .rst(rst), .enable(enable_wheel_service),
        .wheel_hovered(rear_hover), .rack_take_pulse(rear_rack_take),
        .mouse_new_event(mouse_new_event), .mouse_scroll(mouse_scroll),
        .mouse_btn(mouse_btn_left),
        .wheel_detached(rear_detached), .wheel_dragging(rear_dragging),
        .wheel_removed(rear_removed),
        .wheel_near_front_mount(rear_wheel_near_front_mount),
        .wheel_near_rear_mount(rear_wheel_near_rear_mount),
        .front_mount_available(front_mount_available),
        .rear_mount_available(rear_mount_available),
        .grab_enable(rear_grab_enable), .attach_to_anchor(rear_attach),
        .anchor_at_rack(rear_anchor_at_rack),
        .anchor_at_rear(rear_anchor_at_rear), .wheel_visible(rear_visible),
        .wheel_locked(rear_locked), .old_wheel_removed(rear_old_removed),
        .needs_new_wheel(rear_needs_new), .new_wheel_active(rear_new_active),
        .service_done(rear_service_done), .wheel_anim_step(rear_wheel_anim_step),
        .service_progress(rear_progress), .state_debug(rear_state_debug)
    );

    // -------------------------------------------------------------------------
    // Renderowanie warstw
    // -------------------------------------------------------------------------
    draw_bg u_draw_bg (
        .clk(clk), .rst(rst), .low_res_in(low_res_pipe),
        .vga_in(vga_timing_if), .lut_out(lut_bg), .vga_out(vga_bg)
    );

    draw_BolidF1Default u_draw_bolid_default (
        .clk(clk), .rst(rst), .enable(enable_bolid_default),
        .wheel_anim_step(bolid_wheel_anim_step), .x_pos(bolid_x),
        .low_res_in(low_res_pipe), .lut_in(lut_bg), .vga_in(vga_bg),
        .lut_out(lut_bolid_default), .vga_out(vga_bolid_default)
    );

    draw_BolidF1NoWheels u_draw_bolid_no_wheels (
        .clk(clk), .rst(rst), .enable(enable_bolid_no_wheels),
        .x_pos(12'd60), .y_pos(12'd120),
        .low_res_in(low_res_pipe), .lut_in(lut_bolid_default),
        .vga_in(vga_bolid_default), .lut_out(lut_bolid_no_wheels),
        .vga_out(vga_bolid_no_wheels)
    );

    draw_WheelRack u_draw_wheel_rack (
        .clk(clk), .rst(rst), .enable(enable_wheel_rack),
        .x_pos(RACK_X), .y_pos(RACK_Y),
        .low_res_in(low_res_pipe), .lut_in(lut_bolid_no_wheels),
        .vga_in(vga_bolid_no_wheels), .lut_out(lut_rack),
        .vga_out(vga_rack)
    );

    draw_options_panel u_draw_options_panel (
        .clk(clk), .rst(rst),
        .enable(system_screen == 3'b001),
        .multiplayer(option_multiplayer),
        .game_mode(option_game_mode),
        .target_value(option_target_value),
        .low_res_in(low_res_pipe), .lut_in(lut_rack),
        .vga_in(vga_rack), .lut_out(lut_options_panel),
        .vga_out(vga_options_panel)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_play (
        .clk(clk), .rst(rst), .enable(enable_button_play),
        .is_hovered(play_hover), .is_pressed(play_hover && mouse_btn_left),
        .x_pos(BTN_PLAY_X), .y_pos(BTN_PLAY_Y), .text_string("PLAY"),
        .low_res_in(low_res_pipe), .lut_in(lut_options_panel),
        .vga_in(vga_options_panel), .lut_out(lut_btn_play),
        .vga_out(vga_btn_play)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_options (
        .clk(clk), .rst(rst), .enable(enable_button_options),
        .is_hovered(options_hover), .is_pressed(options_hover && mouse_btn_left),
        .x_pos(BTN_OPTS_X), .y_pos(BTN_OPTS_Y), .text_string("OPTS"),
        .low_res_in(low_res_pipe), .lut_in(lut_btn_play),
        .vga_in(vga_btn_play), .lut_out(lut_btn_opts),
        .vga_out(vga_btn_opts)
    );

    draw_button_with_text #(.STR_LEN(4)) u_draw_btn_back (
        .clk(clk), .rst(rst), .enable(enable_button_back),
        .is_hovered(back_hover), .is_pressed(back_hover && mouse_btn_left),
        .x_pos(BTN_BACK_X), .y_pos(BTN_BACK_Y), .text_string("BACK"),
        .low_res_in(low_res_pipe), .lut_in(lut_btn_opts),
        .vga_in(vga_btn_opts), .lut_out(lut_btn_back),
        .vga_out(vga_btn_back)
    );

    logic signed [12:0] front_wheel_x_draw;
    logic signed [12:0] front_wheel_y_draw;
    logic signed [12:0] rear_wheel_x_draw;
    logic signed [12:0] rear_wheel_y_draw;

    assign front_wheel_x_draw = front_wheel_x;
    assign front_wheel_y_draw = front_wheel_y;
    assign rear_wheel_x_draw  = rear_wheel_x;
    assign rear_wheel_y_draw  = rear_wheel_y;

    draw_Wheel u_draw_front_wheel (
        .clk(clk), .rst(rst), .enable(front_visible),
        .wheel_anim_step(front_wheel_anim_step),
        .x_pos(front_wheel_x_draw), .y_pos(front_wheel_y_draw),
        .low_res_in(low_res_pipe), .lut_in(lut_btn_back),
        .vga_in(vga_btn_back), .lut_out(lut_front_wheel),
        .vga_out(vga_front_wheel)
    );

    draw_Wheel u_draw_rear_wheel (
        .clk(clk), .rst(rst), .enable(rear_visible),
        .wheel_anim_step(rear_wheel_anim_step),
        .x_pos(rear_wheel_x_draw), .y_pos(rear_wheel_y_draw),
        .low_res_in(low_res_pipe), .lut_in(lut_front_wheel),
        .vga_in(vga_front_wheel), .lut_out(lut_rear_wheel),
        .vga_out(vga_rear_wheel)
    );

    logic [1:0] current_cursor;

    always_comb begin
        if ((front_hover && front_locked && !front_service_done) ||
            (rear_hover && rear_locked && !rear_service_done))
            current_cursor = 2'b10;
        else if ((front_hover && front_grab_enable) ||
                 (rear_hover && rear_grab_enable) ||
                 (rack_hover && (front_needs_new || rear_needs_new)) ||
                 play_hover || options_hover || back_hover)
            current_cursor = 2'b01;
        else
            current_cursor = 2'b00;
    end

    draw_mouse_cursor u_draw_cursor (
        .clk(clk), .rst(rst), .enable(1'b1),
        .cursor_type(current_cursor), .mouse_x(mouse_x), .mouse_y(mouse_y),
        .low_res_in(low_res_pipe), .lut_in(lut_rear_wheel),
        .vga_in(vga_rear_wheel), .lut_out(lut_cursor),
        .vga_out(vga_cursor)
    );

    LUT2RGB_converter u_lut_to_rgb (
        .clk(clk), .rst_n(rst), .lut_value(lut_cursor),
        .vga_in(vga_cursor), .rgb_out(rgb_pipe), .vga_out(vga_upscale)
    );

endmodule
