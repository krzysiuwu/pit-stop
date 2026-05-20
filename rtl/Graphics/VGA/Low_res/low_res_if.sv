interface low_res_if;

    logic [7:0] vcount;
    logic [7:0] hcount;

    modport in (
        input vcount,
        input hcount
    );

    modport out (
        output vcount,
        output hcount
    );

endinterface