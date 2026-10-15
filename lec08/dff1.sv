module dff1 (
    input  logic d,
    input  logic rst,
    input  logic clk,
    output logic q
);

    always_ff @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end

endmodule
