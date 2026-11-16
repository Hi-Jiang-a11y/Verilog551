module PWM11 (
    input clk,
    input rst_n,
    input [10:0] duty,
    output logic PWM1,
    output logic PWM2,
    output PWM_synch,
    output ovr_I_blank
);

    localparam logic [10:0] NONOVERLAP = 11'h040;   // Dead time

    logic [10:0] cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= '0;
        else
            cnt <= cnt + 11'd1;
    end

    logic [11:0] duty_plus_nonoverlap;
    assign duty_plus_nonoverlap = duty + NONOVERLAP;

    assign PWM1 = rst_n && (cnt >= NONOVERLAP) && (cnt < duty);
    assign PWM2 = rst_n && (cnt >= duty_plus_nonoverlap);

    // Synchronization point
    assign PWM_synch = ~(|cnt);

    assign ovr_I_blank =
        ((cnt > NONOVERLAP) && (cnt < NONOVERLAP + 11'd128)) ||
        ((cnt > duty_plus_nonoverlap) &&
         (cnt < duty_plus_nonoverlap + 12'd128));

endmodule
