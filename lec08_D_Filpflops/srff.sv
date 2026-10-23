module srff (
    input  logic d,
    input  logic r,
    input  logic s,
    input  logic rst,
    input  logic clk,
    output logic q
);

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            q <= 1'b0;
        else if (r)
            q <= 1'b0;
        else if (s)
            q <= 1'b1;
        else
            q <= d;
    end

endmodule
