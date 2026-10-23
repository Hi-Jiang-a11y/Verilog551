module SegwayMath (
    input signed [11:0] PID_cntrl,
    input  [7:0]  ss_tmr,
    input  [11:0] steer_pot,
    input         en_steer,
    input         pwr_up,
    output signed [11:0] lft_spd,
    output signed [11:0] rght_spd,
    output        too_fast
);

    localparam signed [12:0] MIN_DUTY = 13'h0a8;
    localparam signed [6:0] LOW_TORQUE_BAND = 7'h2a;
    localparam signed [3:0] GAIN_MULT = 4'h4;

    logic signed [11:0] PID_ss;
    logic signed [20:0] pid_product;
    always @(*) begin
        pid_product = $signed(PID_cntrl) *
                      $signed({{1'b0}, ss_tmr});
        PID_ss = pid_product >>> 8;
    end

    logic [11:0] steer_pot_limited;
    logic signed [12:0] steer_delta;
    logic signed [15:0] steer_product;
    logic signed [12:0] torque;
    logic signed [12:0] lft_torque, rght_torque;
    always @(*) begin
        if (steer_pot < 12'h200)
            steer_pot_limited = 12'h200;
        else if (steer_pot > 12'he00)
            steer_pot_limited = 12'he00;
        else
            steer_pot_limited = steer_pot;

        steer_delta = $signed({1'b0, steer_pot_limited})
                    - $signed({1'b0, 12'h7ff});
        steer_product = steer_delta * 3'sd3;
        torque = steer_product >>> 4;

        if (en_steer) begin
            lft_torque  = $signed({PID_ss[11], PID_ss}) + torque;
            rght_torque = $signed({PID_ss[11], PID_ss}) - torque;
        end else begin
            lft_torque  = $signed({PID_ss[11], PID_ss});
            rght_torque = $signed({PID_ss[11], PID_ss});
        end
    end

    logic signed [12:0] lft_torque_comp;
    logic signed [12:0] lft_shaped;
    always @(*) begin
        if (lft_torque[12])
            lft_torque_comp = lft_torque - MIN_DUTY;
        else
            lft_torque_comp = lft_torque + MIN_DUTY;

        if (!pwr_up)
            lft_shaped = 13'h0000;
        else if ((lft_torque > 0 ? lft_torque : -lft_torque) > LOW_TORQUE_BAND)
            lft_shaped = lft_torque_comp;
        else
            lft_shaped = GAIN_MULT * lft_torque;
    end

    logic signed [12:0] rght_torque_comp;
    logic signed [12:0] rght_shaped;
    always @(*) begin
        if (rght_torque[12])
            rght_torque_comp = rght_torque - MIN_DUTY;
        else
            rght_torque_comp = rght_torque + MIN_DUTY;

        if (!pwr_up)
            rght_shaped = 13'h0000;
        else if ((rght_torque > 0 ? rght_torque : -rght_torque) > LOW_TORQUE_BAND)
            rght_shaped = rght_torque_comp;
        else
            rght_shaped = GAIN_MULT * rght_torque;
    end

    assign lft_spd = (lft_shaped[12]) ? (
        (& lft_shaped[12:11]) ? lft_shaped[11:0] : {1'b1, {11{1'b0}}}
    ):(
        (| lft_shaped[12:11]) ? {1'b0, {11{1'b1}}} : lft_shaped[11:0]
    );

    assign rght_spd = (rght_shaped[12]) ? (
        (& rght_shaped[12:11]) ? rght_shaped[11:0] : {1'b1, {11{1'b0}}}
    ):(
        (| rght_shaped[12:11]) ? {1'b0, {11{1'b1}}} : rght_shaped[11:0]
    );

    assign too_fast = (lft_spd > $signed(12'd1536)) | (rght_spd > $signed(12'd1536));

endmodule
