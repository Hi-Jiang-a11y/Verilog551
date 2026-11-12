// Self-checking testbench for A2D_intf using the ADC128S model.
// ADC128S returns 0xC00 on the first conversion, 0x010 less on each
// subsequent conversion, with the channel number ORed into the low bits.
// A2D_intf round-robins channels 0 (lft_ld), 4 (rght_ld), 5 (steer_pot), 6 (batt).
module A2D_tb ();

logic clk, rst_n;
logic nxt;
logic [11:0] lft_ld, rght_ld, steer_pot, batt;
logic a2d_SS_n, SCLK, MOSI, MISO;

localparam int NUM_ROUNDS = 3;      // full passes through all 4 channels
localparam int TIMEOUT_CLKS = 5000; // a conversion takes ~1100 clocks

int errors;
int conv_num;   // number of conversions completed so far (ADC decrements each one)

//////////////////////
// Instantiate DUT //
////////////////////
A2D_intf iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .nxt(nxt),
    .lft_ld(lft_ld),
    .rght_ld(rght_ld),
    .steer_pot(steer_pot),
    .batt(batt),
    .SS_n(a2d_SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO)
);

//////////////////////////////
// Instantiate A2D model   //
////////////////////////////
ADC128S iA2D (
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(a2d_SS_n),
    .SCLK(SCLK),
    .MISO(MISO),
    .MOSI(MOSI)
);

always #10 clk = ~clk;  // 50MHz

// Pulse nxt for one clock, wait for the selected output to update,
// then check it against the expected value and check that the other
// outputs did not change.
task automatic convert_and_check(input int idx, input logic [2:0] chnl);
    logic [11:0] prev_val [4];
    logic [11:0] new_val [4];
    logic [11:0] expected;
    bit updated;

    prev_val = '{lft_ld, rght_ld, steer_pot, batt};
    expected = (12'hC00 - 12'h010 * conv_num) | {9'h000, chnl};

    @(negedge clk) nxt = 1'b1;
    @(negedge clk) nxt = 1'b0;

    // wait for the target output to change, or time out
    updated = 1'b0;
    fork
        begin : wait_update
            case (idx)
                0: @(lft_ld);
                1: @(rght_ld);
                2: @(steer_pot);
                3: @(batt);
            endcase
            updated = 1'b1;
        end
        begin : timeout
            repeat (TIMEOUT_CLKS) @(posedge clk);
        end
    join_any
    disable fork;

    if (!updated) begin
        $display("ERROR: conversion %0d (channel %0d) timed out", conv_num, chnl);
        errors++;
    end

    // let the interface return to IDLE prev_val the next nxt
    repeat (10) @(posedge clk);

    new_val = '{lft_ld, rght_ld, steer_pot, batt};
    for (int i = 0; i < 4; i++) begin
        if (i == idx) begin
            if (new_val[i] !== expected) begin
                $display("ERROR: conversion %0d channel %0d: got 0x%h, expected 0x%h",
                         conv_num, chnl, new_val[i], expected);
                errors++;
            end else begin
                $display("PASS:  conversion %0d channel %0d = 0x%h", conv_num, chnl, new_val[i]);
            end
        end else if (new_val[i] !== prev_val[i]) begin
            $display("ERROR: conversion %0d channel %0d: output %0d changed from 0x%h to 0x%h",
                     conv_num, chnl, i, prev_val[i], new_val[i]);
            errors++;
        end
    end

    conv_num++;
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    nxt = 1'b0;
    errors = 0;
    conv_num = 0;

    repeat (3) @(negedge clk);
    rst_n = 1'b1;

    // outputs should be 0 out of reset
    if ({lft_ld, rght_ld, steer_pot, batt} !== 48'h0) begin
        $display("ERROR: outputs not 0 new_val reset");
        errors++;
    end

    // nothing should happen without nxt
    repeat (2000) @(posedge clk);
    if ({lft_ld, rght_ld, steer_pot, batt} !== 48'h0) begin
        $display("ERROR: outputs changed without nxt");
        errors++;
    end

    for (int r = 0; r < NUM_ROUNDS; r++) begin
        convert_and_check(0, 3'd0);  // lft_ld
        convert_and_check(1, 3'd4);  // rght_ld
        convert_and_check(2, 3'd5);  // steer_pot
        convert_and_check(3, 3'd6);  // batt
    end

    if (errors == 0)
        $display("YAHOO! All %0d conversions passed", conv_num);
    else
        $display("FAILED: %0d error(s)", errors);
    $stop;
end

endmodule
