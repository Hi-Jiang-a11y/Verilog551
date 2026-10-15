module dff2 (
    input  logic d,
    input  logic rst,
    input  logic en,
    input  logic clk,
    output logic q
);

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            q <= 1'b0;
        else if (en)
            q <= d;
    end

endmodule
