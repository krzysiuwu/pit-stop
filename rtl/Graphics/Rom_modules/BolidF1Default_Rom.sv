module BolidF1Default_Rom (
    input  logic clk ,
    input  logic [12:0] address,  // address = (Y * 165) + X
    output logic [3:0] LUT_value
);


/**
 * Local variables and signals
 */

reg [3:0] rom [0:7259];


/**
 * Memory initialization from a file
 */

/* Relative path from the simulation or synthesis working directory */
initial $readmemh("../../rtl/Graphics/Sprites_and_textures/BolidF1Default_sprite.mem", rom);


/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule