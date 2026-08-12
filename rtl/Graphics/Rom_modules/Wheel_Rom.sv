module Wheel_Rom (
    input  logic clk ,
    input  logic [9:0] address,  // address = (Y * 26) + X
    output logic [3:0] LUT_value
);


/**
 * Local variables and signals
 */

reg [3:0] rom [0:701];


/**
 * Memory initialization from a file
 */

`ifndef SYNTHESIS
    initial $readmemh("../../rtl/Graphics/Sprites_and_textures/Wheel_sprite.mem", rom);
`else
    initial $readmemh("Wheel_sprite.mem", rom);
`endif  

/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule