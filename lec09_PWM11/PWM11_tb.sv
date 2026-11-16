`timescale 1ns/1ps

module PWM11_tb;
    localparam integer PWM_PERIOD = 1 << 11;
    localparam integer DUTY_COUNT = 9;

    logic clk;
    logic rst_n;
    logic [10:0] duty;
    logic PWM1;
    logic PWM2;
    logic PWM_synch;
    logic ovr_I_blank;

    logic [10:0] duty_values [0:DUTY_COUNT-1];
    integer i;
    integer errors;
    logic expected_pwm1, expected_pwm2, expected_blank;

    PWM11 dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .duty       (duty),
        .PWM1       (PWM1),
        .PWM2       (PWM2),
        .PWM_synch  (PWM_synch),
        .ovr_I_blank(ovr_I_blank)
    );

    always #5 clk = ~clk;

    // Cycle-by-cycle reference model. The #1 delay allows NBA updates in DUT
    // to settle before checking the combinational PWM outputs.
    always @(posedge clk) begin
        #1;
        if (rst_n) begin
            expected_pwm1 = (dut.cnt >= 11'h040) && (dut.cnt < duty);
            expected_pwm2 = ({1'b0, dut.cnt} >= ({1'b0, duty} + 12'h040));
            expected_blank =
                ((dut.cnt > 11'h040) && (dut.cnt < 11'h0c0)) ||
                (({1'b0, dut.cnt} > ({1'b0, duty} + 12'h040)) &&
                 ({1'b0, dut.cnt} < ({1'b0, duty} + 12'h040) + 12'd128));

            if (PWM1 !== expected_pwm1) begin
                $display("ERROR %0t: PWM1=%b expected=%b cnt=%0d duty=%0d", $time, PWM1, expected_pwm1, dut.cnt, duty);
                errors = errors + 1;
            end
            if (PWM2 !== expected_pwm2) begin
                $display("ERROR %0t: PWM2=%b expected=%b cnt=%0d duty=%0d", $time, PWM2, expected_pwm2, dut.cnt, duty);
                errors = errors + 1;
            end
            if (PWM1 && PWM2) begin
                $display("ERROR %0t: PWM outputs overlap", $time);
                errors = errors + 1;
            end
            if (PWM_synch !== (dut.cnt == 11'd0)) begin
                $display("ERROR %0t: PWM_synch mismatch", $time);
                errors = errors + 1;
            end
            if (ovr_I_blank !== expected_blank) begin
                $display("ERROR %0t: blank=%b expected=%b cnt=%0d duty=%0d", $time, ovr_I_blank, expected_blank, dut.cnt, duty);
                errors = errors + 1;
            end
        end
    end

    initial begin
        $dumpfile("PWM11_tb.vcd");
        $dumpvars(0, PWM11_tb);

        errors = 0;

        // Include zero, values below/at/above NONOVERLAP, and maximum duty.
        duty_values[0] = 11'h000;
        duty_values[1] = 11'h001;
        duty_values[2] = 11'h03f;
        duty_values[3] = 11'h040;
        duty_values[4] = 11'h041;
        duty_values[5] = 11'h200;
        duty_values[6] = 11'h400;
        duty_values[7] = 11'h600;
        duty_values[8] = 11'h7ff;

        clk   = 1'b0;
        rst_n = 1'b0;
        duty  = duty_values[0];

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        for (i = 0; i < DUTY_COUNT; i = i + 1) begin
            duty = duty_values[i];
            @(posedge PWM_synch);
            repeat (PWM_PERIOD) @(posedge clk);
        end

        if (errors == 0)
            $display("PASS: all PWM corner-case checks passed");
        else
            $display("FAIL: %0d PWM checks failed", errors);
        $finish;
    end
endmodule
