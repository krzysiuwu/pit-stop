/**
 * Module: Cloud_Rom
 * Summary: Implements synchronous ROM storage for the cloud sprite.
 * Author: Adam Krupa
 */
module Cloud_Rom (
    input  logic clk ,
    input  logic [9:0] address,  // address = (Y * 26) + X
    output logic [3:0] LUT_value
);


/**
 * Local variables and signals
 */

reg [3:0] rom [0:519];


/**
 * Memory initialization from a file
 */

`ifdef VERILATOR
    initial $readmemh("rtl/Graphics/Sprites_and_textures/Cloud_sprite.mem", rom);
`elsif SYNTHESIS
    initial $readmemh("Cloud_sprite.mem", rom);
`else
    initial $readmemh("../../rtl/Graphics/Sprites_and_textures/Cloud_sprite.mem", rom);
`endif
    
/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule
