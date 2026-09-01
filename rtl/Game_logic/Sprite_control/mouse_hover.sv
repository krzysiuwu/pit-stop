/**
 * Module: mouse_hover
 * Summary: Detects pointer overlap with signed object bounds, including sprites clipped by a screen edge.
 * Author: Adam Krupa
 */
module mouse_hover (
    input  logic        enable,
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic signed [11:0] obj_x,
    input  logic signed [11:0] obj_y,
    input  logic [11:0] obj_w,
    input  logic [11:0] obj_h,
    output logic        is_hovered
);

    logic signed [12:0] mouse_x_signed;
    logic signed [12:0] mouse_y_signed;
    logic signed [12:0] obj_x_signed;
    logic signed [12:0] obj_y_signed;
    logic signed [12:0] obj_right;
    logic signed [12:0] obj_bottom;

    always_comb begin
        // Extend both operands before comparison. Casting a negative object
        // coordinate to unsigned would move its hitbox to the far end of the
        // numeric range and make a partially visible wheel impossible to grab.
        mouse_x_signed = $signed({1'b0, mouse_x});
        mouse_y_signed = $signed({1'b0, mouse_y});
        obj_x_signed   = $signed({obj_x[11], obj_x});
        obj_y_signed   = $signed({obj_y[11], obj_y});
        obj_right      = obj_x_signed + $signed({1'b0, obj_w});
        obj_bottom     = obj_y_signed + $signed({1'b0, obj_h});

        is_hovered = enable &&
                     (mouse_x_signed >= obj_x_signed) &&
                     (mouse_x_signed <  obj_right) &&
                     (mouse_y_signed >= obj_y_signed) &&
                     (mouse_y_signed <  obj_bottom);
    end

endmodule
