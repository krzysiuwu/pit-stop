module uart_game_link #(
    parameter int CLOCK_HZ = 65_000_000,
    parameter int BAUD = 115_200,
    parameter int TX_INTERVAL_CYCLES = CLOCK_HZ / 50,
    parameter int LINK_TIMEOUT_CYCLES = CLOCK_HZ / 2
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       uart_rx_i,
    output logic       uart_tx_o,

    input  logic       local_session_start,
    input  logic       local_session_reset,
    input  logic       local_multiplayer_selected,
    input  logic       local_debug_mode,
    input  logic       local_game_finished,
    input  logic [1:0] local_game_mode,
    input  logic [7:0] local_target_value,
    input  logic [7:0] local_score,

    output logic       link_connected,
    output logic       remote_multiplayer_selected,
    output logic       remote_debug_mode,
    output logic       remote_start_pulse,
    output logic       remote_game_finished,
    output logic [1:0] remote_game_mode,
    output logic [7:0] remote_target_value,
    output logic [7:0] remote_score,
    output logic       rx_activity,
    output logic       rx_error_sticky
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [7:0] MAGIC_0 = 8'ha5;
    localparam logic [7:0] MAGIC_1 = 8'h5a;
    localparam int PACKET_BYTES = 8;
    localparam int TX_INTERVAL_SAFE =
        (TX_INTERVAL_CYCLES < 1) ? 1 : TX_INTERVAL_CYCLES;
    localparam int LINK_TIMEOUT_SAFE =
        (LINK_TIMEOUT_CYCLES < 1) ? 1 : LINK_TIMEOUT_CYCLES;
    localparam int TX_INTERVAL_WIDTH =
        (TX_INTERVAL_SAFE <= 1) ? 1 : $clog2(TX_INTERVAL_SAFE);
    localparam int LINK_TIMEOUT_WIDTH =
        (LINK_TIMEOUT_SAFE <= 1) ? 1 : $clog2(LINK_TIMEOUT_SAFE);

    logic [7:0] current_session_id;
    logic       local_session_valid;
    logic       accepted_session_valid;

    logic [2:0] tx_byte_index;
    logic       tx_packet_active;
    logic [TX_INTERVAL_WIDTH-1:0] tx_interval_counter;
    logic       tx_byte_ready;
    logic       tx_byte_valid;
    logic [7:0] tx_byte_data;

    logic [7:0] tx_flags;
    logic [7:0] tx_checksum;

    logic [7:0] tx_session_snapshot;
    logic [7:0] tx_flags_snapshot;
    logic [7:0] tx_mode_snapshot;
    logic [7:0] tx_target_snapshot;
    logic [7:0] tx_score_snapshot;
    logic [7:0] tx_checksum_snapshot;

    assign tx_flags = {
        4'b0000,
        local_debug_mode,
        local_game_finished,
        local_session_valid,
        local_multiplayer_selected
    };

    assign tx_checksum = MAGIC_0 ^ MAGIC_1 ^ current_session_id ^
                         tx_flags ^ {6'b0, local_game_mode} ^
                         local_target_value ^ local_score;

    assign tx_byte_valid = tx_packet_active;

    always_comb begin
        case (tx_byte_index)
            3'd0: tx_byte_data = MAGIC_0;
            3'd1: tx_byte_data = MAGIC_1;
            3'd2: tx_byte_data = tx_session_snapshot;
            3'd3: tx_byte_data = tx_flags_snapshot;
            3'd4: tx_byte_data = tx_mode_snapshot;
            3'd5: tx_byte_data = tx_target_snapshot;
            3'd6: tx_byte_data = tx_score_snapshot;
            default: tx_byte_data = tx_checksum_snapshot;
        endcase
    end

    uart_tx #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD(BAUD)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .data_valid(tx_byte_valid),
        .data(tx_byte_data),
        .data_ready(tx_byte_ready),
        .tx(uart_tx_o)
    );

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            tx_byte_index      <= 3'd0;
            tx_packet_active   <= 1'b0;
            tx_interval_counter <= '0;
            tx_session_snapshot <= 8'd0;
            tx_flags_snapshot   <= 8'd0;
            tx_mode_snapshot    <= 8'd0;
            tx_target_snapshot  <= 8'd0;
            tx_score_snapshot   <= 8'd0;
            tx_checksum_snapshot <= 8'd0;
        end else begin
            if (tx_packet_active) begin
                if (tx_byte_ready) begin
                    if (tx_byte_index == 3'(PACKET_BYTES - 1)) begin
                        tx_byte_index    <= 3'd0;
                        tx_packet_active <= 1'b0;
                    end else begin
                        tx_byte_index <= tx_byte_index + 1'b1;
                    end
                end
            end else if (tx_interval_counter == TX_INTERVAL_SAFE - 1) begin
                tx_interval_counter <= '0;
                tx_byte_index       <= 3'd0;
                tx_packet_active    <= 1'b1;
                tx_session_snapshot <= current_session_id;
                tx_flags_snapshot   <= tx_flags;
                tx_mode_snapshot    <= {6'b0, local_game_mode};
                tx_target_snapshot  <= local_target_value;
                tx_score_snapshot   <= local_score;
                tx_checksum_snapshot <= tx_checksum;
            end else begin
                tx_interval_counter <= tx_interval_counter + 1'b1;
            end
        end
    end

    logic [7:0] rx_byte_data;
    logic       rx_byte_valid;
    logic       rx_framing_error;

    uart_rx #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD(BAUD)
    ) u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx_i),
        .data(rx_byte_data),
        .data_valid(rx_byte_valid),
        .framing_error(rx_framing_error)
    );

    logic [7:0] rx_session;
    logic [7:0] rx_flags;
    logic [7:0] rx_mode;
    logic [7:0] rx_target;
    logic [7:0] rx_score_value;
    logic [2:0] rx_byte_count;
    logic [7:0] rx_checksum;
    logic       valid_packet_pulse;
    logic       checksum_error_pulse;

    // Counter-based reception avoiding FSM extraction & pruning
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            rx_byte_count        <= 3'd0;
            rx_checksum          <= 8'd0;
            valid_packet_pulse   <= 1'b0;
            checksum_error_pulse <= 1'b0;
            rx_session           <= 8'd0;
            rx_flags             <= 8'd0;
            rx_mode              <= 8'd0;
            rx_target            <= 8'd0;
            rx_score_value       <= 8'd0;
        end else begin
            valid_packet_pulse   <= 1'b0;
            checksum_error_pulse <= 1'b0;

            if (rx_byte_valid) begin
                if (rx_byte_count == 3'd0) begin
                    if (rx_byte_data == MAGIC_0) begin
                        rx_checksum   <= rx_byte_data;
                        rx_byte_count <= 3'd1;
                    end
                end else if (rx_byte_count == 3'd1) begin
                    if (rx_byte_data == MAGIC_1) begin
                        rx_checksum   <= rx_checksum ^ rx_byte_data;
                        rx_byte_count <= 3'd2;
                    end else if (rx_byte_data == MAGIC_0) begin
                        rx_checksum   <= rx_byte_data;
                        rx_byte_count <= 3'd1;
                    end else begin
                        rx_byte_count <= 3'd0;
                    end
                end else begin
                    rx_checksum <= rx_checksum ^ rx_byte_data;

                    if (rx_byte_count == 3'd2)      rx_session     <= rx_byte_data;
                    else if (rx_byte_count == 3'd3) rx_flags       <= rx_byte_data;
                    else if (rx_byte_count == 3'd4) rx_mode        <= rx_byte_data;
                    else if (rx_byte_count == 3'd5) rx_target      <= rx_byte_data;
                    else if (rx_byte_count == 3'd6) rx_score_value <= rx_byte_data;
                    else if (rx_byte_count == 3'd7) begin
                        if (rx_byte_data == rx_checksum)
                            valid_packet_pulse <= 1'b1;
                        else
                            checksum_error_pulse <= 1'b1;
                    end

                    if (rx_byte_count == 3'd7)
                        rx_byte_count <= 3'd0;
                    else
                        rx_byte_count <= rx_byte_count + 1'b1;
                end
            end
        end
    end

    logic [LINK_TIMEOUT_WIDTH-1:0] link_timeout_counter;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_session_id          <= 8'd0;
            local_session_valid         <= 1'b0;
            accepted_session_valid      <= 1'b0;
            link_connected              <= 1'b0;
            remote_multiplayer_selected <= 1'b0;
            remote_debug_mode           <= 1'b0;
            remote_start_pulse          <= 1'b0;
            remote_game_finished        <= 1'b0;
            remote_game_mode            <= 2'b00;
            remote_target_value         <= 8'd1;
            remote_score                <= 8'd0;
            rx_activity                 <= 1'b0;
            rx_error_sticky             <= 1'b0;
            link_timeout_counter        <= '0;
        end else begin
            remote_start_pulse <= 1'b0;

            if (rx_framing_error || checksum_error_pulse)
                rx_error_sticky <= 1'b1;

            if (valid_packet_pulse) begin
                link_connected       <= 1'b1;
                link_timeout_counter <= '0;
                rx_activity          <= !rx_activity;

                remote_multiplayer_selected <= rx_flags[0];
                remote_debug_mode           <= rx_flags[3];
                remote_game_mode            <= rx_mode[1:0];
                remote_target_value         <= rx_target;
                remote_score                <= rx_score_value;

                if (rx_flags[1]) begin
                    if (!accepted_session_valid ||
                        (rx_session != current_session_id)) begin
                        current_session_id     <= rx_session;
                        local_session_valid    <= 1'b1;
                        accepted_session_valid <= 1'b1;
                        remote_start_pulse     <= 1'b1;
                        remote_game_finished   <= rx_flags[2];
                    end else begin
                        remote_game_finished <= rx_flags[2];
                    end
                end
            end else if (link_connected) begin
                if (link_timeout_counter == LINK_TIMEOUT_SAFE - 1) begin
                    link_timeout_counter <= '0;
                    link_connected       <= 1'b0;
                    remote_multiplayer_selected <= 1'b0;
                end else begin
                    link_timeout_counter <= link_timeout_counter + 1'b1;
                end
            end

            if (local_session_reset) begin
                local_session_valid  <= 1'b0;
                remote_game_finished <= 1'b0;
            end

            if (local_session_start) begin
                current_session_id     <= current_session_id + 1'b1;
                local_session_valid    <= 1'b1;
                accepted_session_valid <= 1'b1;
                remote_game_finished   <= 1'b0;
            end
        end
    end

endmodule
