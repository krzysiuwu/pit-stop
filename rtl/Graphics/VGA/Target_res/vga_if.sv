/**
 * Interface: vga_if
 * Summary: Groups pixel coordinates, sync pulses, and blanking flags passed between VGA pipeline stages.
 * Author: Adam Krupa
 */
interface vga_if;

    logic [10:0] vcount;
    logic [10:0] hcount;
    logic vsync;
    logic vblnk;
    logic hsync;
    logic hblnk;

    modport in (
        input vcount,
        input vsync,
        input vblnk,
        input hcount,
        input hsync,
        input hblnk
    );

    modport out (
        output vcount,
        output vsync,
        output vblnk,
        output hcount,
        output hblnk,
        output hsync
    );

endinterface