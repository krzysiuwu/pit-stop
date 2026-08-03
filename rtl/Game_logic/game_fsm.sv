module system_fsm (
    input  logic clk,
    input  logic rst,              

    // Interface
    input  logic click_play,
    input  logic click_setup,
    input  logic click_back,
    input  logic click_ready,
    
    // Game logic signals
    input  logic uart_connected,
    input  logic frame_tick,       
    input  logic wheels_attached,  
    
    output logic [2:0] state_out,  
    output logic signed [10:0] bolid_x    
);

    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [2:0] {
        MENU      = 3'b000, // Main Menu
        SETUP     = 3'b001, // Setup Menu
        LOBBY     = 3'b010, // Lobby Menu
        DRIVE_IN  = 3'b011, // Game: Bolid driving in
        PITSTOP   = 3'b100, // Game: Wheels change
        DRIVE_OUT = 3'b101, // Game: Bolid driving out
        DONE      = 3'b110  // End of game
    } state_t;

    state_t state, next_state;

    logic signed [10:0] current_x, next_x;

    localparam int START_POS = 800; 
    localparam int STOP_POS  = 200;  
    localparam int END_POS   = -300;  
    localparam int SPEED     = 5;    

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= MENU;
            current_x <= START_POS;
        end else begin
            state     <= next_state;
            current_x <= next_x;
        end
    end

    always_comb begin
        next_state = state;
        next_x     = current_x;

        case (state)
            MENU: begin
                next_x = START_POS; 
                
                if (click_play) begin
                    next_state = LOBBY;
                end else if (click_setup) begin
                    next_state = SETUP;
                end
            end

            SETUP: begin
                if (click_back) begin
                    next_state = MENU;
                end
            end

            LOBBY: begin
                
                if (click_ready && uart_connected) begin
                    next_state = DRIVE_IN;
                end else if (click_back) begin 
                    next_state = MENU;
                end
            end

            DRIVE_IN: begin
                if (frame_tick) begin
                    if (current_x > STOP_POS) begin
                        next_x = current_x - SPEED;
                    end else begin
                        next_state = PITSTOP;
                    end
                end
            end

            PITSTOP: begin
                if (wheels_attached) begin
                    next_state = DRIVE_OUT;
                end
            end

            DRIVE_OUT: begin
                if (frame_tick) begin
                    if (current_x > END_POS) begin
                        next_x = current_x - SPEED;
                    end else begin
                        next_state = DONE;
                    end
                end
            end

            DONE: begin
                if (click_back || click_play) begin 
                    next_state = MENU;
                end
            end

            default: next_state = MENU;
        endcase
    end

    assign state_out = state;
    assign bolid_x   = current_x;

endmodule