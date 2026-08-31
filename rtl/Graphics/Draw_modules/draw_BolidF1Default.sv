/**
 * Module: draw_BolidF1Default
 * Summary: Renders the complete F1 car and rotates wheel palette colors to show motion.
 * Author: Adam Krupa
 */
import vga_pkg::*;

module draw_BolidF1Default (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    // Animation control
    input  logic [1:0]  wheel_anim_step, // Stan animacji (od 0 do 2)
    
    input  logic signed [11:0] x_pos,
    // The car uses a fixed vertical position; only X is animated.
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);
     
    localparam int SPRITE_WIDTH  = 165;
    localparam int SPRITE_HEIGHT = 44;
    
    // Fixed vertical screen position
    localparam logic [11:0] Y_POS = 12'd120;

    logic in_hitbox;

    logic [11:0] cur_x;
    logic [11:0] cur_y;

    logic signed [12:0] cur_x_signed;
    logic signed [12:0] sprite_left;
    logic signed [12:0] sprite_right;

    logic [11:0] local_x;
    logic [11:0] local_y;

    // Use coordinates from the matching VGA pipeline stage.
    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    // Signed extension is required while the car moves beyond the left edge.
    assign cur_x_signed = $signed({1'b0, cur_x});
    assign sprite_left  = x_pos;
    assign sprite_right = sprite_left + 13'sd165;

    assign in_hitbox =
        enable &&
        (cur_x_signed >= sprite_left) &&
        (cur_x_signed <  sprite_right) &&
        (cur_y >= Y_POS) &&
        (cur_y <  Y_POS + SPRITE_HEIGHT);

    assign local_x = cur_x_signed - sprite_left;
    assign local_y = cur_y - Y_POS;

    logic [$clog2(SPRITE_WIDTH * SPRITE_HEIGHT)-1:0] rom_addr;
    assign rom_addr = in_hitbox ? ((local_y * SPRITE_WIDTH) + local_x) : '0;

    logic [3:0] rom_data;

    BolidF1Default_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    // Pipeline delay registers
    logic       in_hitbox_d;
    logic [3:0] lut_in_d;
    logic [1:0] anim_step_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
            
            in_hitbox_d    <= 1'b0;
            lut_in_d       <= '0;
            anim_step_d    <= '0;
        end else begin
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            
            in_hitbox_d    <= in_hitbox;
            lut_in_d       <= lut_in;
            anim_step_d    <= wheel_anim_step;
        end
    end

    // Wheel color rotation
    logic [3:0] mapped_color;
    
    always_comb begin
        mapped_color = rom_data;
        
        case (rom_data)
            4'hA: begin
                if      (anim_step_d == 2'd1) mapped_color = 4'h9;
                else if (anim_step_d == 2'd2) mapped_color = 4'hE;
            end
            4'h9: begin
                if      (anim_step_d == 2'd1) mapped_color = 4'hE;
                else if (anim_step_d == 2'd2) mapped_color = 4'hA;
            end
            4'hE: begin
                if      (anim_step_d == 2'd1) mapped_color = 4'hA;
                else if (anim_step_d == 2'd2) mapped_color = 4'h9;
            end
            default: mapped_color = rom_data;
        endcase
    end

    // Layer composition
    always_comb begin
        if (in_hitbox_d && rom_data != 4'hF) begin
            lut_out = mapped_color;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
