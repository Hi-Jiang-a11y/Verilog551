module inertial_integrator (
    input   clk,
    input   rst_n,
    input   vld,
    input   logic signed [15:0] ptch_rt,
    input   logic signed [15:0] AZ,
    output  logic signed [15:0] ptch
);

    localparam logic signed [15:0] PTCH_RT_OFFSET = 16'sh0050;
    localparam logic signed [15:0] AZ_OFFSET      = 16'sh00A0;

    logic signed [26:0] ptch_int;
    logic signed [15:0] ptch_rt_comp;
    logic signed [15:0] AZ_comp;
    logic signed [25:0] ptch_acc_product;
    logic signed [15:0] ptch_acc;
    logic signed [26:0] ptch_rt_comp_ext;
    logic signed [26:0] fusion_ptch_offset;

    assign ptch_rt_comp = $signed(ptch_rt) - PTCH_RT_OFFSET;
    assign AZ_comp      = $signed(AZ) - AZ_OFFSET;

    assign ptch_acc_product = AZ_comp * $signed(10'sd327);
    assign ptch_acc         = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

    assign ptch_rt_comp_ext = {{11{ptch_rt_comp[15]}}, ptch_rt_comp};

    assign fusion_ptch_offset = (ptch_acc > ptch) ? 27'sd1024 : - 27'sd1024;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            ptch_int <= 27'sd0;
        else if (vld)
            ptch_int <= ptch_int - ptch_rt_comp_ext + fusion_ptch_offset;
    end
    assign ptch = ptch_int[26:11];

endmodule
