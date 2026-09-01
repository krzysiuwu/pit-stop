/**
 * Module: WheelRack_Rom
 * Summary: Implements synchronous ROM storage for the wheel-rack sprite.
 * Author: Adam Krupa
 */
module WheelRack_Rom (
        input  logic clk ,
        input  logic [11:0] address,  // address = (Y * 52) + X
        output logic [3:0] LUT_value
    );


    /**
     * Local variables and signals
     */

    reg [3:0] rom [0:2339] = '{default: 4'b0};


/**
 * Memory initialization from a file
 */

`ifdef VERILATOR
    initial $readmemh("rtl/Graphics/Sprites_and_textures/WheelRack_sprite.mem", rom);
`elsif SYNTHESIS
    initial $readmemh("WheelRack_sprite.mem", rom);
`else
    initial $readmemh("../../rtl/Graphics/Sprites_and_textures/WheelRack_sprite.mem", rom);
`endif

    /**
     * Internal logic
     */

    always_ff @(posedge clk)
        LUT_value <= rom[address];

endmodule
