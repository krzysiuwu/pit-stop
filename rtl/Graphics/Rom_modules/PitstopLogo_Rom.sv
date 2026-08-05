module PitstopLogo_Rom (
    input  logic clk,
    input  logic [13:0] address,  // address = (Frame * 4096) + (Y * 128) + X
    output logic [3:0] LUT_value
);


/**
 * Local variables and signals
 */

reg [3:0] rom [0:16383];


/**
 * Memory initialization from a file
 */

/* Relative path from the simulation or synthesis working directory */
initial $readmemh("../../rtl/Graphics/Sprites_and_textures/PitstopLogo.mem", rom);


/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule