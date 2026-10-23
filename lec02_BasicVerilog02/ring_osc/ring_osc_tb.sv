module ring_osc_tb();

    logic EN;
    logic OUT;

    ring_osc iDUT(
        .EN(EN),
        .OUT(OUT)
    );

    initial begin
        EN = 0;
        #15;
        EN = 1;
        #200;
        $stop();
    end

endmodule
