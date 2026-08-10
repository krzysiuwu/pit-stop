/**
 * Description:
 * Single character renderer from 1-bit font ROM.
 * Converts 1-bit monochrome data to 4-bit VGA palette color.
 */

module char_renderer (
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,

    input  logic [11:0] hcount,
    input  logic [11:0] vcount,

    input  logic [6:0]  char_code,
    input  logic [3:0]  char_color,

    input  logic        rom_data,

    output logic [12:0] rom_addr,
    output logic [3:0]  pixel_out,
    output logic        is_active
);

    localparam int WIDTH  = 8;
    localparam int HEIGHT = 8;

    logic in_hitbox;

    logic [2:0] local_x;
    logic [2:0] local_y;

    assign in_hitbox = enable && (hcount >= x_pos) && (hcount < x_pos + WIDTH) && (vcount >= y_pos) && (vcount < y_pos + HEIGHT);

    assign local_x = hcount[2:0] - x_pos[2:0];
    assign local_y = vcount[2:0] - y_pos[2:0];

    assign rom_addr = in_hitbox ? {char_code, local_y, local_x} : 13'b0;

    logic in_hitbox_d;
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) in_hitbox_d <= 1'b0;
        else      in_hitbox_d <= in_hitbox;
    end

    assign is_active = in_hitbox_d && (rom_data == 1'b1);
    
    assign pixel_out = char_color;

endmodule