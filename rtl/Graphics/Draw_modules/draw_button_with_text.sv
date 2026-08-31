/**
 * Module: draw_button_with_text
 * Summary: Legacy parameterized renderer that combines a button sprite with centered font-ROM text.
 * Author: Adam Krupa
 */
import vga_pkg::*;
import low_res_pkg::*;

module draw_button_with_text #(
    parameter int STR_LEN = 8 // Number of characters in the rendered label.
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    
    input  logic is_hovered,
    input  logic is_pressed,
    
    input  logic [11:0] x_pos,
    input  logic [11:0] y_pos,
    
    input  logic [(STR_LEN*8)-1:0] text_string, // Packed ASCII string with STR_LEN characters.
    
    input  logic [3:0] lut_in,
    vga_if.in          vga_in,
    low_res_if.in      low_res_in,
    
    output logic [3:0] lut_out,
    vga_if.out         vga_out
);

    localparam int BTN_WIDTH  = 78;
    localparam int BTN_HEIGHT = 28;
    
    localparam int TEXT_WIDTH  = STR_LEN * 8;
    localparam int TEXT_HEIGHT = 8;
    
    // Center text at pixel precision for any supported word length.
    localparam int TEXT_OFFSET_X = (BTN_WIDTH - TEXT_WIDTH) / 2;
    localparam int TEXT_OFFSET_Y = 6; // Vertical offset that optically centers the glyphs.

    logic [11:0] cur_x, cur_y;
    
    assign cur_x = {1'b0, vga_in.hcount} >> 2;
    assign cur_y = {1'b0, vga_in.vcount} >> 2;

    logic [11:0] dyn_y_pos;
    assign dyn_y_pos = is_pressed ? (y_pos + 12'd2) : y_pos;

    // =========================================================================
    // BUTTON BACKGROUND
    // =========================================================================
    logic in_btn;
    logic [11:0] local_btn_x, local_btn_y;
    
    assign in_btn = enable && 
                    (cur_x >= x_pos) && (cur_x < x_pos + BTN_WIDTH) && 
                    (cur_y >= dyn_y_pos) && (cur_y < dyn_y_pos + BTN_HEIGHT);
                    
    assign local_btn_x = cur_x - x_pos;
    assign local_btn_y = cur_y - dyn_y_pos;

    logic [11:0] btn_rom_addr;
    assign btn_rom_addr = in_btn ? ((local_btn_y * BTN_WIDTH) + local_btn_x) : 12'd0;

    logic [3:0] btn_rom_data;
    BasicButton8chars_Rom u_btn_rom (
        .clk(clk),
        .address(btn_rom_addr),
        .LUT_value(btn_rom_data)
    );

    // =========================================================================
    // TEXT RENDERING
    // =========================================================================
    logic in_txt;
    logic [11:0] txt_start_x, txt_start_y;
    logic [7:0]  local_txt_x;
    logic [2:0]  local_txt_y;
    
    assign txt_start_x = x_pos + TEXT_OFFSET_X;
    assign txt_start_y = dyn_y_pos + TEXT_OFFSET_Y; 

    assign in_txt = enable && 
                    (cur_x >= txt_start_x) && (cur_x < txt_start_x + TEXT_WIDTH) && 
                    (cur_y >= txt_start_y) && (cur_y < txt_start_y + TEXT_HEIGHT);

    assign local_txt_x = cur_x[7:0] - txt_start_x[7:0];
    assign local_txt_y = cur_y[2:0] - txt_start_y[2:0];

    logic [4:0] char_index; 
    assign char_index = local_txt_x[7:3];

    logic [7:0] char_array [0:STR_LEN-1];
    genvar i;
    generate
        for (i = 0; i < STR_LEN; i++) begin : gen_char_array
            assign char_array[i] = text_string[((STR_LEN - 1 - i) * 8) +: 8];
        end
    endgenerate

    logic [7:0] current_char_code;
    always_comb begin
        current_char_code = 8'h20;
        if (in_txt && (char_index < STR_LEN))
            current_char_code = char_array[char_index];
    end

    logic [9:0] txt_rom_addr;
    assign txt_rom_addr = in_txt ? {current_char_code[6:0], local_txt_y[2:0]} : 10'b0;

    logic [7:0] txt_rom_data;
    Font_Rom u_font_rom (
        .clk(clk),
        .address(txt_rom_addr),
        .data_out(txt_rom_data)
    );

    // =========================================================================
    // PIPELINE DELAY
    // =========================================================================
    logic       in_btn_d;
    logic       in_txt_d;
    logic [2:0] txt_pixel_x_d;
    logic       is_hovered_d;
    logic [3:0] lut_in_d;

    always_ff @(posedge clk) begin
        if (!rst) begin
            in_btn_d       <= 1'b0;
            in_txt_d       <= 1'b0;
            txt_pixel_x_d  <= '0;
            is_hovered_d   <= 1'b0;
            lut_in_d       <= '0;
            
            vga_out.vcount <= '0;
            vga_out.vsync  <= '0;
            vga_out.hcount <= '0;
            vga_out.hsync  <= '0;
            vga_out.vblnk  <= '0;
            vga_out.hblnk  <= '0;
        end else begin
            in_btn_d       <= in_btn;
            in_txt_d       <= in_txt;
            txt_pixel_x_d  <= local_txt_x[2:0];
            is_hovered_d   <= is_hovered; 
            
            vga_out.vcount <= vga_in.vcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hcount <= vga_in.hcount;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;
            
            lut_in_d       <= lut_in;
        end
    end

    // =========================================================================
    // LAYER COMPOSITION
    // =========================================================================
    logic       txt_pixel_bit;
    logic       txt_active;
    logic [3:0] txt_color;
    
    logic       btn_active;
    logic [3:0] btn_color;

    assign txt_pixel_bit = txt_rom_data[7 - txt_pixel_x_d];
    assign txt_active    = in_txt_d && (txt_pixel_bit == 1'b1);
    assign txt_color     = is_hovered_d ? 4'h3 : 4'h0;

    assign btn_active = in_btn_d && (btn_rom_data != 4'hF);
    
    always_comb begin
        if (is_hovered_d && btn_rom_data == 4'h0) begin
            btn_color = 4'h3;
        end else begin
            btn_color = btn_rom_data;
        end
    end

    always_comb begin
        if (txt_active) begin
            lut_out = txt_color;
        end else if (btn_active) begin
            lut_out = btn_color;
        end else begin
            lut_out = lut_in_d;
        end
    end

endmodule
