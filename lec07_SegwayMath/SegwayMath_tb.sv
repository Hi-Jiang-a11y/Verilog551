module SegwayMath_tb_1;
    logic signed [11:0] PID_cntrl;
    logic  [7:0]  ss_tmr;
    logic [11:0] steer_pot;
    logic         en_steer;
    logic         pwr_up;
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic        too_fast;

    wire signed [11:0] PID_ss = dut1.PID_ss;
    wire signed [12:0] lft_torque = dut1.lft_torque;
    wire signed [12:0] lft_shaped = dut1.lft_shaped;

    SegwayMath dut1 (.*);

    initial begin
        en_steer = 1'b0;
        pwr_up = 1'b1;
        PID_cntrl = 1535;
    end

    integer i, j;

    initial begin
        for (i = 0; i <= 255; i = i + 1) begin
            ss_tmr = i;
            #1;
        end
        for (j = 1535; j >= -512; j = j - 1) begin
            PID_cntrl = j;
            #1;
        end
        $stop;
    end
endmodule

module SegwayMath_tb_2;
    logic signed [11:0] PID_cntrl;
    logic  [7:0]  ss_tmr;
    logic [11:0] steer_pot;
    logic         en_steer;
    logic         pwr_up;
    logic signed [11:0] lft_spd;
    logic signed [11:0] rght_spd;
    logic        too_fast;

    wire signed [11:0] steer_pot_limited = dut2.steer_pot_limited;
    wire signed [11:0] PID_ss = dut2.PID_ss;
    wire signed [12:0] lft_shaped = dut2.lft_shaped;
    wire signed [12:0] rght_shaped = dut2.rght_shaped;

    SegwayMath dut2 (.*);

    initial begin
        en_steer = 1'b1;
        pwr_up = 1'b1;
        PID_cntrl = 1535;
        ss_tmr = 8'hff;
    end

    integer i, j;
    initial begin
        for (i = 1023; i >= -1024; i = i - 1) begin
            PID_cntrl = i;
            #2;
        end
    end
    initial begin
        for (j = 0; j <= 4094; j = j + 1) begin
            steer_pot = j;
            #1;
        end
        #100;
        pwr_up = 1'b0;
        #200;
        $stop;
    end
endmodule
