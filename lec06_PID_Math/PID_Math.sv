module PID_Math (
    input  [15:0] ptch,
    input  [15:0] ptch_rt,
    input  [17:0] integrator,
    output [11:0] PID_cntrl
);

    localparam logic signed [4:0] P_COEFF = 5'h09;

    logic signed [12:0] D_term;
    assign D_term = -($signed(ptch_rt) >>> 6);

    logic signed [14:0] I_term;
    assign I_term = $signed(integrator) >>> 6;

    logic [9:0] ptch_err_sat;
    logic signed [14:0] P_term;
    assign ptch_err_sat =
        ptch[15] ?(
            (&ptch[14:9]) ? {1'b1, ptch[8:0]} : {1'b1, 9'b0}
        ):(
            (|ptch[14:9]) ? {1'b0, 9'b111111111} : {1'b0, ptch[8:0]}
        );

    assign P_term = $signed({{5{ptch_err_sat[9]}}, ptch_err_sat}) * P_COEFF;

    logic signed [15:0] sum_before_sat;
    assign sum_before_sat =
        $signed({{3{D_term[12]}}, D_term}) +
        $signed({{1{I_term[14]}}, I_term}) +
        $signed({P_term[14], P_term});

    assign PID_cntrl =
        sum_before_sat[15] ?(
            (&sum_before_sat[14:11]) ? {1'b1, sum_before_sat[10:0]} : {1'b1, 11'b0}
        ):(
            (|sum_before_sat[14:11]) ? {1'b0, 11'b11111111111} : {1'b0, sum_before_sat[10:0]}
        );

endmodule
