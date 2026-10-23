`timescale 1ns/1ps

module PWM11 (
    input clk,
    input rst_n,
    input [10:0] duty,
    output reg PWM1,
    output reg PWM2,
    output PWM_synch,
    output ovr_I_bank
);

    localparam NONOVERLAP = 11'h040;

    logic [10:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 1'b0;
        else
            cnt <= cnt + 11'd1;
    end

    logic [11:0] dutyaddnonoverlap;
    assign dutyaddnonoverlap = duty + NONOVERLAP;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            PWM2 <= 1'b0;
        else if (cnt >= dutyaddnonoverlap)
            PWM2 <= 1'b1;
        else
            PWM2 <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            PWM1 <= 1'b0;
        else if ((cnt >= NONOVERLAP) && (cnt <= duty))
            PWM1 <= 1'b1;
        else
            PWM1 <= 1'b0;
    end

    assign PWM_synch = ~(|cnt);

    assign ovr_I_bank =
        ((cnt > NONOVERLAP) && (cnt < NONOVERLAP + 11'd128)) ||
        ((cnt > dutyaddnonoverlap) &&
         (cnt < dutyaddnonoverlap + 11'd128));

endmodule
