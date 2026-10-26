module balance_cntrl #(parameter bit fast_sim = 1'b1) (
    input clk, rst_n, vld, rider_off,
    input [15:0] ptch,
    input [15:0] ptch_rt,
    input [17:0] integrator,
    input pwr_up,
    input en_steer,
    input [11:0] steer_pot,
    output signed [11:0] lft_spd,
    output signed [11:0] rght_spd,
    output too_fast
);

    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;

    PID #(.fast_sim(fast_sim)) u_pid (
        .clk        (clk),
        .rst_n      (rst_n),
        .vld        (vld),
        .rider_off  (rider_off),
        .ptch       (ptch),
        .ptch_rt    (ptch_rt),
        .integrator (integrator),
        .pwr_up     (pwr_up),
        .PID_cntrl  (PID_cntrl),
        .ss_tmr     (ss_tmr)
    );

    SegwayMath u_segway_math (
        .PID_cntrl (PID_cntrl),
        .ss_tmr    (ss_tmr),
        .steer_pot (steer_pot),
        .en_steer  (en_steer),
        .pwr_up    (pwr_up),
        .lft_spd   (lft_spd),
        .rght_spd  (rght_spd),
        .too_fast  (too_fast)
    );

endmodule
