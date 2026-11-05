`timescale 1ns/1ps

module piezo_drv_tb;

    logic clk;
    logic rst_n;
    logic en_steer;
    logic too_fast;
    logic batt_low;
    logic piezo;
    logic piezo_n;

    localparam logic [2:0] S_WAIT     = 3'd0;
    localparam logic [2:0] S_G6       = 3'd1;
    localparam logic [2:0] S_C7       = 3'd2;
    localparam logic [2:0] S_E7       = 3'd3;
    localparam logic [2:0] S_G7       = 3'd4;
    localparam logic [2:0] S_E7_SHORT = 3'd5;
    localparam logic [2:0] S_G7_LONG  = 3'd6;

    piezo_drv #(.FAST_SIM(1'b1)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .en_steer (en_steer),
        .too_fast (too_fast),
        .batt_low (batt_low),
        .piezo    (piezo),
        .piezo_n  (piezo_n)
    );

    always #5 clk = ~clk;

    task automatic check_state(input logic [2:0] expected, input integer limit);
        integer count;
        begin
            count = 0;
            while ((dut.cs !== expected) && (count < limit)) begin
                @(posedge clk);
                count = count + 1;
            end
            if (dut.cs !== expected)
                $fatal(1, "Timeout waiting for state %0d; current state=%0d", expected, dut.cs);
        end
    endtask

    task automatic check_silent;
        begin
            if ((piezo !== 1'b0) || (piezo_n !== 1'b0))
                $fatal(1, "Piezo is not silent: piezo=%b piezo_n=%b", piezo, piezo_n);
        end
    endtask

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        en_steer = 1'b0;
        too_fast = 1'b0;
        batt_low = 1'b0;

        repeat (4) @(posedge clk);
        check_silent();
        rst_n = 1'b1;

        // No input: remain idle and silent.
        repeat (20) @(posedge clk);
        check_state(S_WAIT, 1);
        check_silent();

        // too_fast has priority and repeats G6 -> C7 -> E7.
        too_fast = 1'b1;
        batt_low = 1'b1;
        check_state(S_G6, 10);
        if ((piezo === 1'b0) && (piezo_n === 1'b0))
            $fatal(1, "Piezo did not start for too_fast");
        check_state(S_C7, 200_000);
        check_state(S_E7, 200_000);
        check_state(S_G6, 200_000);

        // Reset before checking the next independent input condition.
        too_fast = 1'b0;
        batt_low = 1'b0;
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        check_state(S_WAIT, 1);

        // batt_low plays the three-note reverse sequence E7 -> C7 -> G6.
        batt_low = 1'b1;
        check_state(S_E7, 10);
        check_state(S_C7, 200_000);
        check_state(S_G6, 200_000);
        check_state(S_WAIT, 200_000);
        check_silent();
        batt_low = 1'b0;

        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        check_state(S_WAIT, 1);

        // en_steer starts Charge! after the three-second repeat timer.
        en_steer = 1'b1;
        check_state(S_G6, 2_500_000);
        check_state(S_C7, 200_000);
        check_state(S_E7, 200_000);
        check_state(S_G7, 200_000);
        check_state(S_E7_SHORT, 300_000);
        check_state(S_G7_LONG, 100_000);
        check_state(S_WAIT, 300_000);
        check_silent();

        $display("piezo_drv_tb: PASS");
        $finish;
    end

endmodule
