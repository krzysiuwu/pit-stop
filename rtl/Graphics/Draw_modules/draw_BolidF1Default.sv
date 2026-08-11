import vga_pkg::*;
import low_res_pkg::*;

module draw_BolidF1Default (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    // --- Sygnał sterujący animacją ---
    input  logic [1:0]  wheel_anim_step, // Stan animacji (od 0 do 2)
    
    input  logic [11:0] x_pos,
    // Usunięto port wejściowy y_pos, wartość jest teraz stała
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);
     
    localparam int SPRITE_WIDTH  = 165;
    localparam int SPRITE_HEIGHT = 44;
    
    // --- Sztywno ustalona pozycja Y na ekranie ---
    localparam logic [11:0] Y_POS = 12'd120;

    logic in_hitbox;
    logic [11:0] local_x;
    logic [11:0] local_y;

    // Zamiana y_pos na stałą Y_POS w warunkach brzegowych
    assign in_hitbox = enable && 
                       (low_res_in.hcount >= x_pos) && (low_res_in.hcount < x_pos + SPRITE_WIDTH) && 
                       (low_res_in.vcount >= Y_POS) && (low_res_in.vcount < Y_POS + SPRITE_HEIGHT);

    // Wyliczanie lokalnej współrzędnej również ze stałej
    assign local_x = low_res_in.hcount - x_pos;
    assign local_y = low_res_in.vcount - Y_POS;

    logic [$clog2(SPRITE_WIDTH * SPRITE_HEIGHT)-1:0] rom_addr;
    assign rom_addr = in_hitbox ? ((local_y * SPRITE_WIDTH) + local_x) : '0;

    logic [3:0] rom_data;

    BolidF1Default_Rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .LUT_value(rom_data)
    );

    // --- Rejestry opóźniające potoku ---
    logic       in_hitbox_d;
    logic [3:0] lut_in_d;
    logic [1:0] anim_step_d;

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

    // --- Logika rotacji kolorów na kołach ---
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

    // --- Nakładanie warstw (Z-Buffer) ---
    always_comb begin
        if (in_hitbox_d && rom_data != 4'hF) begin
            lut_out = mapped_color;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule