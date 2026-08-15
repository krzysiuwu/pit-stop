module system_fsm (
    input  logic clk,
    input  logic rst,

    input  logic click_play,
    input  logic click_setup,
    input  logic click_back,
    input  logic frame_tick,

    input  logic front_wheel_done,
    input  logic rear_wheel_done,

    output logic [2:0] state_out,

    output logic enable_bolid_default,
    output logic enable_bolid_no_wheels,
    output logic enable_button_play,
    output logic enable_button_options,
    output logic enable_button_back,
    output logic enable_wheel_rack,
    output logic enable_wheel_service,

    output logic signed [11:0] bolid_x,
    output logic [1:0]         bolid_wheel_anim_step,
    output logic [3:0]         sequence_debug
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [2:0] SCREEN_MAIN_MENU = 3'b000;
    localparam logic [2:0] SCREEN_OPTIONS   = 3'b001;
    localparam logic [2:0] SCREEN_GAMEPLAY  = 3'b010;
    localparam logic [2:0] SCREEN_SUMMARY   = 3'b011;

    // Stany sekwencji sa oddzielone od numeru ekranu. Pozwala to zachowac
    // prosty interfejs renderera, a jednoczesnie trzymac caly przebieg rundy
    // poza modulem top.
    typedef enum logic [3:0] {
        MENU_BOOT,
        MAIN_MENU,
        OPTIONS,
        GAME_ARRIVE_START,
        GAME_ARRIVING,
        GAME_SERVICE,
        GAME_DEPART_START,
        GAME_DEPARTING,
        SUMMARY
    } system_state_t;

    system_state_t state, next_state;

    logic trigger_arrive;
    logic trigger_depart;
    logic trigger_drive_through;
    logic arrive_done;
    logic depart_done;
    logic anim_car_enable;

    bolid_anim_ctrl u_bolid_anim_ctrl (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .trigger_arrive(trigger_arrive),
        .trigger_depart(trigger_depart),
        .trigger_drive_through(trigger_drive_through),
        .arrive_done(arrive_done),
        .depart_done(depart_done),
        .car_enable(anim_car_enable),
        .car_x_pos(bolid_x),
        .wheel_anim_step(bolid_wheel_anim_step)
    );

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            state <= MENU_BOOT;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            MENU_BOOT: begin
                next_state = MAIN_MENU;
            end

            MAIN_MENU: begin
                if (click_play)
                    next_state = GAME_ARRIVE_START;
                else if (click_setup)
                    next_state = OPTIONS;
            end

            OPTIONS: begin
                if (click_back)
                    next_state = MAIN_MENU;
            end

            GAME_ARRIVE_START: begin
                next_state = GAME_ARRIVING;
            end

            GAME_ARRIVING: begin
                if (click_back)
                    next_state = SUMMARY;
                else if (arrive_done)
                    next_state = GAME_SERVICE;
            end

            GAME_SERVICE: begin
                if (click_back)
                    next_state = SUMMARY;
                else if (front_wheel_done && rear_wheel_done)
                    next_state = GAME_DEPART_START;
            end

            GAME_DEPART_START: begin
                next_state = GAME_DEPARTING;
            end

            GAME_DEPARTING: begin
                if (click_back)
                    next_state = SUMMARY;
                else if (depart_done)
                    next_state = GAME_ARRIVE_START;
            end

            SUMMARY: begin
                if (click_back)
                    next_state = MENU_BOOT;
            end

            default: begin
                next_state = MENU_BOOT;
            end
        endcase
    end

    always_comb begin
        trigger_arrive       = 1'b0;
        trigger_depart       = 1'b0;
        trigger_drive_through = 1'b0;

        state_out               = SCREEN_MAIN_MENU;
        enable_bolid_default    = 1'b0;
        enable_bolid_no_wheels  = 1'b0;
        enable_button_play      = 1'b0;
        enable_button_options   = 1'b0;
        enable_button_back      = 1'b0;
        enable_wheel_rack       = 1'b0;
        enable_wheel_service    = 1'b0;

        case (state)
            MENU_BOOT: begin
                state_out             = SCREEN_MAIN_MENU;
                enable_button_play    = 1'b1;
                enable_button_options = 1'b1;
                trigger_drive_through = 1'b1;
            end

            MAIN_MENU: begin
                state_out             = SCREEN_MAIN_MENU;
                enable_bolid_default  = anim_car_enable;
                enable_button_play    = 1'b1;
                enable_button_options = 1'b1;

                // depart_done jest aktywny do chwili przyjecia nowego rozkazu,
                // wiec pojedynczy warunek wystarcza do bezszwowego zapetlenia.
                if (depart_done)
                    trigger_drive_through = 1'b1;
            end

            OPTIONS: begin
                state_out            = SCREEN_OPTIONS;
                enable_bolid_default = anim_car_enable;
                enable_button_back   = 1'b1;

                if (depart_done)
                    trigger_drive_through = 1'b1;
            end

            GAME_ARRIVE_START: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_button_back   = 1'b1;
                trigger_arrive       = 1'b1;
            end

            GAME_ARRIVING: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_bolid_default = anim_car_enable;
                enable_button_back   = 1'b1;
            end

            GAME_SERVICE: begin
                state_out              = SCREEN_GAMEPLAY;
                enable_bolid_no_wheels = 1'b1;
                enable_button_back     = 1'b1;
                enable_wheel_rack      = 1'b1;
                enable_wheel_service   = 1'b1;
            end

            GAME_DEPART_START: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_button_back   = 1'b1;
                trigger_depart       = 1'b1;
            end

            GAME_DEPARTING: begin
                state_out            = SCREEN_GAMEPLAY;
                enable_bolid_default = anim_car_enable;
                enable_button_back   = 1'b1;
            end

            SUMMARY: begin
                state_out          = SCREEN_SUMMARY;
                enable_button_back = 1'b1;
            end

            default: begin
                state_out = SCREEN_MAIN_MENU;
            end
        endcase
    end

    assign sequence_debug = state;

endmodule
