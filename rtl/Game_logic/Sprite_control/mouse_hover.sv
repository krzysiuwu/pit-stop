module mouse_hover (
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic [11:0] obj_x,
    input  logic [11:0] obj_y,
    input  logic [11:0] obj_w,
    input  logic [11:0] obj_h,
    output logic        is_hovered
);

    always_comb begin
        is_hovered = (mouse_x >= obj_x) && (mouse_x < obj_x + obj_w) &&
                     (mouse_y >= obj_y) && (mouse_y < obj_y + obj_h);
    end

endmodule
