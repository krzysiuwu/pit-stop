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
    // This final stage is deliberately separate from the metastability chain.
    // Vivado may replicate it to keep the global reset distribution local.
    (* MAX_FANOUT = 64 *) logic reset_distribution;

    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            release_sync <= 2'b00;
            reset_distribution <= 1'b0;
        end else begin
            release_sync <= {release_sync[0], 1'b1};
            reset_distribution <= release_sync[1];
        end
    end

    assign rst_n = reset_distribution;

endmodule
