/**
 * Module: mouse_hitbox
 * Summary: Detects pointer overlap and emits a one-clock click pulse on press or release.
 * Author: Adam Krupa, Krzysztof Jędrzejek
 */
module mouse_hitbox #(
        // UI buttons should trigger on release so their pressed state remains
        // visible for one frame. Game objects such as the wheel rack retain
        // the default press-triggered behavior.
        parameter bit CLICK_ON_RELEASE = 1'b0
    )(
        input  logic clk,
        input  logic rst,

        // Global mouse signals
        input  logic [11:0] mouse_x,
        input  logic [11:0] mouse_y,
        input  logic        mouse_btn,     // Left mouse button.

        // Object bounds; these values may change at runtime
        input  logic [11:0] obj_x,
        input  logic [11:0] obj_y,
        input  logic [11:0] obj_w,
        input  logic [11:0] obj_h,

        // Detection outputs
        output logic is_hovered,
        output logic is_clicked            // One-clock click pulse.
    );

    // Detect whether the cursor is inside the rectangle.
    assign is_hovered =
        (mouse_x >= obj_x) &&
        (mouse_x <  obj_x + obj_w) &&
        (mouse_y >= obj_y) &&
        (mouse_y <  obj_y + obj_h);

    // Generate the click pulse according to the selected trigger mode.
    logic mouse_btn_prev;

    if (CLICK_ON_RELEASE) begin : gen_click_on_release
        logic press_armed;

        always_ff @(posedge clk) begin
            if (!rst) begin
                mouse_btn_prev <= 1'b0;
                press_armed    <= 1'b0;
                is_clicked     <= 1'b0;
            end else begin
                mouse_btn_prev <= mouse_btn;

                // Every click pulse lasts exactly one clock cycle.
                is_clicked <= 1'b0;

                if (mouse_btn && !mouse_btn_prev) begin
                    press_armed <= is_hovered;
                end else if (!mouse_btn && mouse_btn_prev) begin
                    if (press_armed && is_hovered)
                        is_clicked <= 1'b1;
                    press_armed <= 1'b0;
                end else if (mouse_btn && press_armed && !is_hovered) begin
                    press_armed <= 1'b0;
                end
            end
        end
    end else begin : gen_click_on_press
        always_ff @(posedge clk) begin
            if (!rst) begin
                mouse_btn_prev <= 1'b0;
                is_clicked     <= 1'b0;
            end else begin
                mouse_btn_prev <= mouse_btn;
                is_clicked     <= 1'b0;

                if (mouse_btn && !mouse_btn_prev && is_hovered) begin
                    is_clicked <= 1'b1;
                end
            end
        end
    end

endmodule
