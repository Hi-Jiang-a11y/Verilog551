`timescale 1ns/1ps

// Directed testbench for inertial_integrator.
// The stimulus is arranged in the same five intervals as the lab handout.
module inertial_integrator_tb;

    localparam logic signed [15:0] PTCH_RT_OFFSET = 16'sh0050;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic vld = 1'b0;
    logic signed [15:0] ptch_rt = '0;
    logic signed [15:0] AZ = '0;
    logic signed [15:0] ptch;

    inertial_integrator dut (.*);

    always #5 clk = ~clk;

    // Keep inputs stable for the complete clock interval.  The values are
    // changed on a falling edge, and are consumed on the following rising edge.
    task automatic run_clocks(input int unsigned count);
        repeat (count) @(posedge clk);
    endtask

    task automatic report_interval(input string name,
                                   input logic signed [15:0] first_ptch);
        $display("%-28s: ptch %0d -> %0d", name, first_ptch, $signed(ptch));
    endtask

    logic signed [15:0] p0;
    initial begin
        $dumpfile("inertial_integrator_tb.vcd");
        $dumpvars(0, inertial_integrator_tb);

        // Hold reset active for a few clocks, then deassert it synchronously
        // between edges.  vld remains asserted for the entire experiment.
        vld = 1'b0;
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        vld   = 1'b1;

        // 1) Positive pitch-rate input: integration of -ptch_rt drives ptch down.
        ptch_rt = PTCH_RT_OFFSET + 16'sh1000;
        AZ      = 16'sh0000;
        @(negedge clk); p0 = ptch; run_clocks(500);
        report_interval("rate +0x1000 (500 clocks)", p0);

        // 2) Zero pitch rate: accelerometer fusion slowly brings ptch to zero.
        ptch_rt = PTCH_RT_OFFSET;
        @(negedge clk); p0 = ptch;
        run_clocks(1000);
        report_interval("zero rate (1000 clocks)", p0);

        // 3) Negative pitch-rate input: ptch now moves steeply positive.
        ptch_rt = PTCH_RT_OFFSET - 16'sh1000;
        @(negedge clk); p0 = ptch; run_clocks(500);
        report_interval("rate -0x1000 (500 clocks)", p0);

        // 4) Zero rate again; fusion slowly returns the result toward zero.
        ptch_rt = PTCH_RT_OFFSET;
        @(negedge clk); p0 = ptch;
        run_clocks(1000);
        report_interval("zero rate (1000 clocks)", p0);

        // 5) Apply AZ = 0x0800.  Leave this running long enough to observe
        // convergence near 100 and the +/-1024 fusion correction toggling.
        AZ = 16'sh0800;
        run_clocks(2500);
        $display("AZ=0x0800 convergence: final ptch = %0d", $signed(ptch));

        $finish;
    end

endmodule
