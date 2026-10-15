module PID (
    input  clk, rst_n, vld, rider_off,
    input  [15:0] ptch,
    input  [15:0] ptch_rt,
    input  [17:0] integrator,
    input pwr_up,
    output [11:0] PID_cntrl,
    output [7:0]  ss_tmr
);

    localparam logic signed [4:0] P_COEFF = 5'h09;




// {{{ D&P term
    logic signed [12:0] D_term;
    assign D_term = -($signed(ptch_rt) >>> 6);

    logic [9:0] ptch_err_sat;
    logic signed [14:0] P_term;
    assign ptch_err_sat =
        ptch[15] ?(
            (&ptch[14:9]) ? {1'b1, ptch[8:0]} : {1'b1, 9'b0}
        ):(
            (|ptch[14:9]) ? {1'b0, 9'b111111111} : {1'b0, ptch[8:0]}
        );

    assign P_term = $signed({{5{ptch_err_sat[9]}}, ptch_err_sat}) * P_COEFF;
// }}}

    logic signed [14:0] I_term;
    logic signed [17:0] ptch_err_sat_signext;
    logic overflow;
    logic signed [17:0] I_term_d;
    logic signed [17:0] I_term_q;
    logic signed [17:0] accumulate;

    assign ptch_err_sat_signext = {{8{ptch_err_sat[9]}}, ptch_err_sat};
    assign accumulate = ptch_err_sat_signext + I_term_q;
    assign overflow = (ptch_err_sat_signext[17] == I_term_q[17]) && (accumulate[17] != ptch_err_sat_signext[17]);

    always @(*) begin
        if (~overflow & vld)
            I_term_d = rider_off ? 18'h00000 : accumulate;
        else
            I_term_d = rider_off ? 18'h00000 : I_term_q;
    end
    always @(posedge clk) begin
        if (!rst_n)
            I_term_q <= 18'd0;
        else
            I_term_q <= I_term_d;
    end
    assign I_term = $signed(I_term_q[17:6]);

    logic [26:0] long_tmr;
    logic [26:0] long_tmr_d;
    always @(*) begin
        if (&long_tmr[26:19])
            long_tmr_d = pwr_up ? long_tmr : 27'h0000000 ;
        else
            long_tmr_d = pwr_up ? (long_tmr + 1) : 27'h0000000;
    end
    always @(posedge clk) begin
        if (!rst_n)
            long_tmr <= 27'h0000000;
        else
            long_tmr <= long_tmr_d;
    end

    assign ss_tmr = long_tmr[26:19];


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
