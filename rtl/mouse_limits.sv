/**
 * Module: mouse_limits
 * Description:
 * Configures the maximum X and Y limits for the MouseCtl module
 * on reset using a 2-bit sequence counter.
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

    logic [1:0] step;

    always_ff @(posedge clk) begin
        if (!rst) begin
            step <= 2'd0;
        end else if (step != 2'd3) begin
            step <= step + 1'b1;
        end
    end

    always_comb begin
        value    = 12'd0;
        setmax_x = 1'b0;
        setmax_y = 1'b0;

        case (step)
            2'd1: begin
                value    = HOR_PIXELS - 1;
                setmax_x = 1'b1;
            end
            2'd2: begin
                value    = VER_PIXELS - 1;
                setmax_y = 1'b1;
            end
            default: begin
                value    = 12'd0;
                setmax_x = 1'b0;
                setmax_y = 1'b0;
            end
        endcase
    end

endmodule