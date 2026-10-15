`timescale 1ns/1ps

module PWM11_tb;
    localparam integer PWM_PERIOD = 1 << 11;
    localparam integer DUTY_COUNT = 5;

    logic clk;
    logic rst_n;
    logic [10:0] duty;
    logic PWM1;
    logic PWM2;
    logic PWM_synch;
    logic ovr_I_bank;

    logic [10:0] duty_values [0:DUTY_COUNT-1];
    integer i;

    PWM11 dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .duty       (duty),
        .PWM1       (PWM1),
        .PWM2       (PWM2),
        .PWM_synch  (PWM_synch),
        .ovr_I_bank (ovr_I_bank)
    );

    always #5 clk = ~clk;

    initial begin
        duty_values[0] = 11'h000;
        duty_values[1] = 11'h200;
        duty_values[2] = 11'h400;
        duty_values[3] = 11'h600;
        duty_values[4] = 11'h7ff;

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

        $finish;
    end
endmodule
