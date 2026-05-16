interface low_res_if; 

    logic [7:0] vcount;
    logic [7:0] hcount;
    logic [3:0] lut_value;

    modport in ( 
        input vcount,
        input hcount,
        input lut_value
    );

    modport out (
        output vcount,
        output hcount,
        output lut_value
    );

endinterface