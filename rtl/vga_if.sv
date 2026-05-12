interface vga_if; 

    logic [10:0] vcount;
    logic [10:0] hcount;
    logic vsync;
    logic vblnk;
    logic hsync;
    logic hblnk;
    logic [11:0] rgb;

    modport in ( 
        input vcount,
        input vsync,
        input vblnk,
        input hcount,
        input hsync,
        input hblnk,
        input rgb
    );

    modport out (
        output vcount,
        output vsync,
        output vblnk,
        output hcount,
        output hblnk,
        output hsync,
        output rgb
    );

endinterface