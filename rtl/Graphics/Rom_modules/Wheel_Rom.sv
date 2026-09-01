/**
 * Module: Wheel_Rom
 * Summary: Implements synchronous ROM storage for the wheel sprite.
 * Author: Adam Krupa
 */
module Wheel_Rom (
        input  logic clk ,
        input  logic [9:0] address,  // address = (Y * 26) + X
        output logic [3:0] LUT_value
    );


    /**
     * Local variables and signals
     */

    reg [3:0] rom [0:701] = '{default: 4'b0};


/**
 * Memory initialization from a file
 */

`ifdef VERILATOR
    initial $readmemh("rtl/Graphics/Sprites_and_textures/Wheel_sprite.mem", rom);
`elsif SYNTHESIS
    initial $readmemh("Wheel_sprite.mem", rom);
`else
    initial $readmemh("../../rtl/Graphics/Sprites_and_textures/Wheel_sprite.mem", rom);
`endif

    /**
     * Internal logic
     */

    always_ff @(posedge clk)
        LUT_value <= rom[address];

endmodule
