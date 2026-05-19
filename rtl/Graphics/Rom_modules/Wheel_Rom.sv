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

/* Relative path from the simulation or synthesis working directory */
initial $readmemh("../Sprites_and_textures/Wheel_sprite.mem", rom);


/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule