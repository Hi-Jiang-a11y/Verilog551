`timescale 1ns/1ps

module mtr_drv_tb;
    logic        clk;
    logic        rst_n;
    logic [11:0] lft_spd, rght_spd;
    logic        OVR_I_lft, OVR_I_rght;
    wire         PWM1_lft, PWM2_lft, PWM1_rght, PWM2_rght;
    wire         OVR_I_shtdwn;

    mtr_drv dut (
        .clk(clk), .rst_n(rst_n),
        .lft_spd(lft_spd), .rght_spd(rght_spd),
        .OVR_I_lft(OVR_I_lft), .OVR_I_rght(OVR_I_rght),
        .PWM1_lft(PWM1_lft), .PWM2_lft(PWM2_lft),
        .PWM1_rght(PWM1_rght), .PWM2_rght(PWM2_rght),
        .OVR_I_shtdwn(OVR_I_shtdwn)
    );

    always #1 clk = ~clk;

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            OVR_I_lft = 1'b0;
            OVR_I_rght = 1'b0;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            // Start at the beginning of a PWM cycle.
            while (dut.iPWM_lft.cnt != 11'd0) @(posedge clk);
        end
    endtask

    // Apply one one-clock over-current pulse at a selected PWM counter value.
    task automatic ovr_pulse(input logic right_side, input integer count_value);
        begin
            while (dut.iPWM_lft.cnt != count_value[10:0]) @(posedge clk);
            if (right_side) OVR_I_rght = 1'b1;
            else            OVR_I_lft  = 1'b1;
            @(posedge clk);
            OVR_I_lft = 1'b0;
            OVR_I_rght = 1'b0;
        end
    endtask

    task automatic run_case(input logic right_side, input integer count_value,
                            input logic expect_shutdown);
        integer n;
        begin
            reset_dut();
            // 40 consecutive PWM cycles, as required by the exercise.
            for (n = 0; n < 40; n = n + 1)
                ovr_pulse(right_side, count_value);
            // Allow the synchronizer and counter logic to settle.
            repeat (6) @(posedge clk);
            if (OVR_I_shtdwn !== expect_shutdown) begin
                $display("FAIL: %s pulse at cnt=%0d: shutdown=%b (expected %b)",
                         right_side ? "right" : "left", count_value,
                         OVR_I_shtdwn, expect_shutdown);
                $fatal(1);
            end
            $display("PASS: %s pulse at cnt=%0d: shutdown=%b",
                     right_side ? "right" : "left", count_value,
                     OVR_I_shtdwn);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        lft_spd = 12'h000;       // converted internally to duty 11'h400
        rght_spd = 12'h000;
        OVR_I_lft = 1'b0;
        OVR_I_rght = 1'b0;

        // cnt=100 is inside the PWM over-current blanking window.
        run_case(1'b0, 100, 1'b0);
        run_case(1'b1, 100, 1'b0);

        // cnt=400 is outside the blanking window and must eventually trip.
        run_case(1'b0, 400, 1'b1);
        run_case(1'b1, 400, 1'b1);

        $display("All mtr_drv tests passed.");
        $finish;
    end
endmodule
