module saturate (
    input  [15:0] unsigned_err,
    output reg [9:0]  unsigned_err_sat,
    input  [15:0] signed_err,
    output reg [9:0]  signed_err_sat,
    input  [9:0]  signed_D_diff,
    output reg [6:0]  signed_D_diff_sat
);

always_comb begin
    if (| unsigned_err[15:10])
        unsigned_err_sat = {10{1'b1}};
    else
        unsigned_err_sat = unsigned_err[9:0];
end

always_comb begin
    if (signed_err[15]==1'b0) begin
        if (| signed_err[14:9])
            signed_err_sat = {1'b0, {9{1'b1}}};
        else
            signed_err_sat = {1'b0, signed_err[8:0]};
    end else begin
        if (& signed_err[14:9])
            signed_err_sat = {1'b1, signed_err[8:0]};
        else
            signed_err_sat = {1'b1, {9{1'b0}}};
    end
end

always_comb begin
    if (signed_D_diff[9]==1'b0) begin
        if (| signed_D_diff[8:6])
            signed_D_diff_sat = {1'b0, {6{1'b1}}};
        else
            signed_D_diff_sat = {1'b0, signed_D_diff[5:0]};
    end else begin
        if (& signed_D_diff[8:6])
            signed_D_diff_sat = {1'b1, signed_D_diff[5:0]};
        else
            signed_D_diff_sat = {1'b1, {6{1'b0}}};
    end
end

endmodule
