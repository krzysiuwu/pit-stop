/**
 * Module: bin_to_bcd3
 * Summary: Converts a ten-bit unsigned binary value into three BCD digits using double dabble.
 * Author: Adam Krupa
 */
module bin_to_bcd3 (
    input  logic [9:0] binary,
    output logic [3:0] hundreds,
    output logic [3:0] tens,
    output logic [3:0] ones
);

    logic [9:0]  capped_binary;
    logic [21:0] shift;
    integer i;

    always_comb begin
        capped_binary = (binary > 10'd999) ? 10'd999 : binary;
        shift = '0;
        shift[9:0] = capped_binary;

        // Double dabble: one shared, constant-size binary-to-BCD converter.
        for (i = 0; i < 10; i = i + 1) begin
            if (shift[13:10] >= 4'd5)
                shift[13:10] = shift[13:10] + 4'd3;
            if (shift[17:14] >= 4'd5)
                shift[17:14] = shift[17:14] + 4'd3;
            if (shift[21:18] >= 4'd5)
                shift[21:18] = shift[21:18] + 4'd3;
            shift = shift << 1;
        end

        hundreds = shift[21:18];
        tens     = shift[17:14];
        ones     = shift[13:10];
    end

endmodule
