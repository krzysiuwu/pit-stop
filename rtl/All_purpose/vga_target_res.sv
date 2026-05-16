package vga_target_res_pkg;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 65 MHz clock
    localparam HOR_PIXELS = 1024;
    localparam VER_PIXELS = 768;

    // Horizontal timing parameters
    localparam HOR_TOTAL_TIME  = 1344;
    localparam HOR_BLANK_START = 1024;
    localparam HOR_BLANK_TIME  = 320;   // 24 (Front Porch) + 136 (Sync) + 160 (Back Porch)
    localparam HOR_SYNC_START  = 1048;  // 1024 (Active) + 24 (Front Porch)
    localparam HOR_SYNC_TIME   = 136;

    // Vertical timing parameters
    localparam VER_TOTAL_TIME  = 806;
    localparam VER_BLANK_START = 768;
    localparam VER_BLANK_TIME  = 38;    // 3 (Front Porch) + 6 (Sync) + 29 (Back Porch)
    localparam VER_SYNC_START  = 771;   // 768 (Active) + 3 (Front Porch)
    localparam VER_SYNC_TIME   = 6;

endpackage