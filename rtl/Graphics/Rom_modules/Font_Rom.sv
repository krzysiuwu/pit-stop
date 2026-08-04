module Font_Rom (
    input  logic clk,
    input  logic [10:0] address,
    output logic [7:0] data_out
);


    logic [7:0] font_array [0:1023]; 

    initial begin
        $readmemh("font_zx.mem", font_array);
    end

    always_ff @(posedge clk) begin
        data_out <= font_array[address];
    end

endmodule