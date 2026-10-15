module DUT_tb ();

logic [15:0] unsigned_err;
logic [9:0]  unsigned_err_sat;
logic [15:0] signed_err;
logic [9:0]  signed_err_sat;
logic [9:0]  signed_D_diff;
logic [6:0]  signed_D_diff_sat;

DUT dut(
    .unsigned_err(unsigned_err),
    .unsigned_err_sat(unsigned_err_sat),
    .signed_err(signed_err),
    .signed_err_sat(signed_err_sat),
    .signed_D_diff(signed_D_diff),
    .signed_D_diff_sat(signed_D_diff_sat)
);

initial begin

    unsigned_err = 16'd100;
    #5;
    if (unsigned_err_sat !== 10'd100) begin
        $display("unsigned_err=%d, expected=%d but got=%d\n",
                unsigned_err, 10'd100, unsigned_err_sat);
        $stop();
    end

    unsigned_err = 16'd1023;
    #5;
    if (unsigned_err_sat !== 10'd1023) begin
        $display("unsigned_err=%d, expected=%d but got=%d\n",
                unsigned_err, 10'd1023, unsigned_err_sat);
        $stop();
    end

    unsigned_err = 16'd1024;
    #5;
    if (unsigned_err_sat !== 10'd1023) begin
        $display("unsigned_err=%d, expected=%d but got=%d\n",
                unsigned_err, 10'd1023, unsigned_err_sat);
        $stop();
    end

    unsigned_err = 16'd65535;
    #5;
    if (unsigned_err_sat !== 10'd1023) begin
        $display("unsigned_err=%d, expected=%d but got=%d\n",
                     unsigned_err, 10'd1023, unsigned_err_sat);
        $stop();
    end


    signed_err = 16'sd100;
    #5;
    if (signed_err_sat !== 10'sd100) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                     signed_err, 10'sd100, signed_err_sat);
        $stop();
    end

    signed_err = 16'sd511;
    #5;
    if (signed_err_sat !== 10'sd511) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                    signed_err, 10'sd511, signed_err_sat);
        $stop();
    end

    signed_err = 16'sd512;
    #5;
    if (signed_err_sat !== 10'sd511) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                     signed_err, 10'sd511, signed_err_sat);
        $stop();
    end

    signed_err = -16'sd100;
    #5;
    if (signed_err_sat !== -10'sd100) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                     signed_err, -10'sd100, signed_err_sat);
        $stop();
    end

    signed_err = -16'sd512;
    #5;
    if (signed_err_sat !== -10'sd512) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                     signed_err, -10'sd512, signed_err_sat);
        $stop();
    end

    signed_err = -16'sd513;
    #5;
    if (signed_err_sat !== -10'sd512) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                     signed_err, -10'sd512, signed_err_sat);
        $stop();
    end

    signed_err = -16'sd32768;
    #5;
    if (signed_err_sat !== -10'sd512) begin
        $display("signed_err=%d, expected=%d but got=%d\n",
                 signed_err, -10'sd512, signed_err_sat);
        $stop();
    end


    signed_D_diff = 10'sd30;
    #5;
    if (signed_D_diff_sat !== 7'sd30) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, 7'sd30, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = 10'sd63;
    #5;
    if (signed_D_diff_sat !== 7'sd63) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, 7'sd63, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = 10'sd64;
    #5;
    if (signed_D_diff_sat !== 7'sd63) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, 7'sd63, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = -10'sd30;
    #5;
    if (signed_D_diff_sat !== -7'sd30) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, -7'sd30, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = -10'sd64;
    #5;
    if (signed_D_diff_sat !== -7'sd64) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, -7'sd64, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = -10'sd65;
    #5;
    if (signed_D_diff_sat !== -7'sd64) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, -7'sd64, signed_D_diff_sat);
        $stop();
    end

    signed_D_diff = -10'sd512;
    #5;
    if (signed_D_diff_sat !== -7'sd64) begin
        $display("signed_D_diff=%d, expected=%d but got=%d\n",
                     signed_D_diff, -7'sd64, signed_D_diff_sat);
        $stop();
    end

    $display("All tests passed!\n");
    $stop();

    end

endmodule
