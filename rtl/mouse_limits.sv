/**
 * Module: mouse_limits
 * Description:
 * Module configures the maximum X and Y limits for the MouseCtl module
 * to HOR_PIXELS and VER_PIXELS parameters from vga_pkg.
 */

module mouse_limits (
        input  logic clk,
        input  logic rst,

        output logic [11:0] value,
        output logic setmax_x,
        output logic setmax_y
    );

    //import screen resolution
    import vga_pkg::*;

    typedef enum logic [1:0] {
        INIT  = 2'b00,
        SET_X = 2'b01,
        SET_Y = 2'b10,
        DONE  = 2'b11
    } conf_state;

    conf_state state, next_state;

    // State Register
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= INIT;
        end else begin
            state <= next_state;
        end
    end

    // Next State & Output Logic
    always_comb begin
        // Default assignments
        next_state = state;
        value      = '0;
        setmax_x   = 1'b0;
        setmax_y   = 1'b0;

        case (state)
            INIT: begin
                // Wait one cycle after reset before doing anything
                next_state = SET_X;
            end

            SET_X: begin
                // Send the MAX_X value and pulse setmax_x
                value      = HOR_PIXELS[11:0];
                setmax_x   = 1'b1;
                next_state = SET_Y;
            end

            SET_Y: begin
                // Send the MAX_Y value and pulse setmax_y
                value      = VER_PIXELS[11:0];
                setmax_y   = 1'b1;
                next_state = DONE;
            end

            DONE: begin
                // Configuration finished. Keep all signals at 0 and stay here.
                next_state = DONE;
            end
        endcase
    end

endmodule