/**
 * Description:
 * Universal sprite rendering module with ROM latency compensation.
 * Transparency is handled assuming 4'hF (Magenta) is the transparent color.
 */

module sprite_renderer #(
    parameter int WIDTH  = 32,
    parameter int HEIGHT = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,


    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,

    input  logic [11:0] hcount,
    input  logic [11:0] vcount,

    input  logic [3:0]  rom_data,

    output logic [$clog2(WIDTH * HEIGHT)-1:0] rom_addr,
    output logic [3:0]  pixel_out,
    output logic        is_active
);

    logic in_hitbox;
    logic [11:0] local_x;
    logic [11:0] local_y;

    assign in_hitbox = enable && (hcount >= x_pos) && (hcount < x_pos + WIDTH) && (vcount >= y_pos) && (vcount < y_pos + HEIGHT);

    assign local_x = hcount - x_pos;
    assign local_y = vcount - y_pos;

    assign rom_addr = in_hitbox ? (local_y * WIDTH + local_x) : 16'b0;

    logic in_hitbox_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_hitbox_d <= 1'b0;
        end else begin
            in_hitbox_d <= in_hitbox;
        end
    end
    
    assign is_active = in_hitbox_d && (rom_data != 4'hF);
    assign pixel_out = rom_data;

endmodule