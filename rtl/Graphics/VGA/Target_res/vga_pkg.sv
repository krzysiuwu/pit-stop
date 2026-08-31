/**
 * Package: vga_pkg
 * Summary: Defines 1024-by-768 VGA timing and internal 256-by-192 rendering constants.
 * Author: Adam Krupa
 */
package vga_pkg;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 65 MHz clock;
    localparam HOR_PIXELS = 1024;
    localparam VER_PIXELS = 768;

    // Internal scaled resolution downscaled by 4x
    localparam HOR_PIXELS_INT = 256;
    localparam VER_PIXELS_INT = 192;

    // Horizontal Timing Parameters
    localparam HOR_TOTAL_TIME  = 1344;
    localparam HOR_BLANK_START = 1024;
    localparam HOR_BLANK_TIME  = 320;   // HOR_TOTAL_TIME - HOR_PIXELS
    localparam HOR_SYNC_START  = 1048;  // HOR_BLANK_START + Front Porch (24)
    localparam HOR_SYNC_TIME   = 136;   // Sync pulse width

    // Vertical Timing Parameters
    localparam VER_TOTAL_TIME  = 806;
    localparam VER_BLANK_START = 768;
    localparam VER_BLANK_TIME  = 38;    // VER_TOTAL_TIME - VER_PIXELS
    localparam VER_SYNC_START  = 771;   // VER_BLANK_START + Front Porch (3)
    localparam VER_SYNC_TIME   = 6;     // Sync pulse width

endpackage