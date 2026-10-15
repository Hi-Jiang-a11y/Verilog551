module ring_osc (
    input EN,
    output OUT
);

    wire n1;
    wire n2;

    nand #(5) g1(n1, EN, OUT);
    not  #(5) g2(n2, n1);
    not  #(5) g3(OUT, n2);

endmodule
