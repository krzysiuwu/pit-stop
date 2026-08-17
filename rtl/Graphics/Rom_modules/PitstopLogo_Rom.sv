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

`ifdef VERILATOR
    initial $readmemh("rtl/Graphics/Sprites_and_textures/PitstopLogo.mem", rom);
`elsif SYNTHESIS
    initial $readmemh("PitstopLogo.mem", rom);
`else
    initial $readmemh("../../rtl/Graphics/Sprites_and_textures/PitstopLogo.mem", rom);
`endif

/**
 * Internal logic
 */

always_ff @(posedge clk)
    LUT_value <= rom[address];

endmodule
