module Font_Rom (
    input  logic clk,
    input  logic [9:0] address,
    output logic [7:0] data_out
);


    logic [7:0] font_array [0:1023]; 

    initial begin
        `ifdef VERILATOR
            $readmemh("rtl/Graphics/Sprites_and_textures/font_zx.mem", font_array);
        `elsif SYNTHESIS
            $readmemh("font_zx.mem", font_array);
        `else
            $readmemh("../../rtl/Graphics/Sprites_and_textures/font_zx.mem", font_array);
        `endif
    end

    always_ff @(posedge clk) begin
        data_out <= font_array[address];
    end

endmodule
