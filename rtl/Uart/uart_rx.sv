module uart_rx #(
    parameter int CLOCK_HZ = 65_000_000,
    parameter int BAUD     = 115_200
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,

    output logic [7:0] data,
    output logic       data_valid,
    output logic       framing_error
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CLKS_PER_BIT_RAW = CLOCK_HZ / BAUD;
    localparam int CLKS_PER_BIT = (CLKS_PER_BIT_RAW < 1) ? 1 : CLKS_PER_BIT_RAW;
    localparam int HALF_BIT = (CLKS_PER_BIT < 2) ? 1 : CLKS_PER_BIT / 2;
    localparam int COUNTER_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    (* ASYNC_REG = "TRUE" *) logic rx_meta;
    (* ASYNC_REG = "TRUE" *) logic rx_sync;
    rx_state_t state;
    logic [COUNTER_WIDTH-1:0] clock_counter;
    logic [2:0] bit_index;
    logic [7:0] data_shift;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state         <= RX_IDLE;
            clock_counter <= '0;
            bit_index     <= 3'd0;
            data_shift    <= 8'd0;
            data          <= 8'd0;
            data_valid    <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            data_valid    <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                RX_IDLE: begin
                    clock_counter <= '0;
                    bit_index     <= 3'd0;
                    if (!rx_sync)
                        state <= RX_START;
                end

                RX_START: begin
                    if (clock_counter == HALF_BIT - 1) begin
                        clock_counter <= '0;
                        if (!rx_sync)
                            state <= RX_DATA;
                        else
                            state <= RX_IDLE;
                    end else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end

                RX_DATA: begin
                    if (clock_counter == CLKS_PER_BIT - 1) begin
                        clock_counter         <= '0;
                        data_shift[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= RX_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end

                RX_STOP: begin
                    if (clock_counter == CLKS_PER_BIT - 1) begin
                        clock_counter <= '0;
                        state         <= RX_IDLE;

                        if (rx_sync) begin
                            data       <= data_shift;
                            data_valid <= 1'b1;
                        end else begin
                            framing_error <= 1'b1;
                        end
                    end else begin
                        clock_counter <= clock_counter + 1'b1;
                    end
                end

                default: state <= RX_IDLE;
            endcase
        end
    end

endmodule
