module synch_detect (
    input  asynch_sig_in,
    input  clk,
    input  rst_n,
    output rise_edge
);

    wire Sig_FF1;
    wire Sig_FF2;
    wire Sig_FF2_d;
    wire not_Sig_FF2_d;

    dff dff1 (
        .D(asynch_sig_in),
        .clk(clk),
        .PRN(rst_n),
        .Q(Sig_FF1)
    );

    dff dff2 (
        .D(Sig_FF1),
        .clk(clk),
        .PRN(rst_n),
        .Q(Sig_FF2)
    );

    dff dff3 (
        .D(Sig_FF2),
        .clk(clk),
        .PRN(rst_n),
        .Q(Sig_FF2_d)
    );

    not u_not (
        not_Sig_FF2_d,
        Sig_FF2_d
    );

    and u_and (
        rise_edge,
        Sig_FF2,
        not_Sig_FF2_d
    );

endmodule
