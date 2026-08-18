module reset_sync (
    input  logic clk,
    input  logic async_rst_n,
    output logic rst_n
);

    timeunit 1ns;
    timeprecision 1ps;

    // Reset is asserted asynchronously, but released only on clock edges.
    // ASYNC_REG keeps the two flip-flops together during implementation.
    (* ASYNC_REG = "TRUE" *) logic [1:0] release_sync;

    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            release_sync <= 2'b00;
        else
            release_sync <= {release_sync[0], 1'b1};
    end

    assign rst_n = release_sync[1];

endmodule
