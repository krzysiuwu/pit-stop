import vga_pkg::*;
import low_res_pkg::*;

module draw_BolidF1NoWheels (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);
     
    localparam int SPRITE_WIDTH  = 165;
    localparam int SPRITE_HEIGHT = 44;

    logic in_hitbox;
    logic [11:0] local_x;
    logic [11:0] local_y;

    assign in_hitbox = enable && 
                       (low_res_in.hcount >= x_pos) && (low_res_in.hcount < x_pos + SPRITE_WIDTH) && 
                       (low_res_in.vcount >= y_pos) && (low_res_in.vcount < y_pos + SPRITE_HEIGHT);

    assign local_x = low_res_in.hcount - x_pos;
    assign local_y = low_res_in.vcount - y_pos;

    logic [$clog2(SPRITE_WIDTH * SPRITE_HEIGHT)-1:0] rom_addr;
    assign rom_addr = in_hitbox ? ((local_y * SPRITE_WIDTH) + local_x) : '0;

    logic [3:0] rom_data;

    BolidF1NoWheels_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    logic       in_hitbox_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            
            in_hitbox_d    <= 1'b0;
            lut_in_d       <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            
            in_hitbox_d    <= in_hitbox;
            lut_in_d       <= lut_in;
        end
    end

    always_comb begin
        if (in_hitbox_d && rom_data != 4'hF) begin
            lut_out = rom_data;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule