module seven_segment_display (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] value,

    output logic [6:0] seg,
    output logic [3:0] an,
    output logic       dp
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [15:0] refresh_counter;
    logic [1:0]  digit_select;
    logic [3:0]  digit;
    logic [3:0]  hundreds;
    logic [3:0]  tens;
    logic [3:0]  ones;
    logic [7:0]  hundreds_value;
    logic [7:0]  tens_value;
    logic [7:0]  ones_value;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            refresh_counter <= 16'b0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    assign digit_select = refresh_counter[15:14];
    assign hundreds_value = value / 8'd100;
    assign tens_value = (value % 8'd100) / 8'd10;
    assign ones_value = value % 8'd10;

    always_comb begin
        hundreds = hundreds_value[3:0];
        tens     = tens_value[3:0];
        ones     = ones_value[3:0];

        an = 4'b1111;
        digit = 4'hf;

        case (digit_select)
            2'd0: begin
                an = 4'b1110;
                digit = ones;
            end
            2'd1: begin
                an = 4'b1101;
                digit = (value >= 8'd10) ? tens : 4'hf;
            end
            2'd2: begin
                an = 4'b1011;
                digit = (value >= 8'd100) ? hundreds : 4'hf;
            end
            default: begin
                an = 4'b0111;
                digit = 4'hf;
            end
        endcase
    end

    // Basys 3 segments and anodes are active low. seg[0] is segment A and
    // seg[6] is segment G, hence the conventional GFEDCBA bit patterns below.
    always_comb begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

    assign dp = 1'b1;

endmodule
