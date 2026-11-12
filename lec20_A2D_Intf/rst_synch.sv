module rst_synch(clk, rst_n, RST_n);

    input logic clk, RST_n;
    output logic rst_n;
    logic q;

    always_ff @(negedge clk, negedge RST_n)
        if (!RST_n) begin
            q <= 1'b0;
            rst_n <= 1'b0;
        end
        else begin
            q <= 1'b1;
            rst_n <= q;
        end

endmodule


