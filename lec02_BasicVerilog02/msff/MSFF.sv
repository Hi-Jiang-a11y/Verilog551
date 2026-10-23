module MSFF (
    input  d,
    input  clk,
    output q
);

    wire md;
    wire mq;
    wire sd;
    wire clk_in;

    not (clk_in, clk);
    notif1 (md, d, clk_in);
    not (mq, md);
    not (weak1, weak0) (md, mq);
    notif1 (sd, mq, clk);
    not (q, sd);
    not (weak1, weak0) (sd, q);

endmodule
