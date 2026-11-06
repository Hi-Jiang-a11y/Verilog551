module rst_synch (
    input  logic clk,
    input  logic RST_n,
    output logic rst_n
);

    logic q1;

    // Assert reset asynchronously; release it synchronously on negedge clk.
    always_ff @(negedge clk or negedge RST_n) begin
        if (!RST_n) begin
            q1   <= 1'b0;
            rst_n <= 1'b0;
        end else begin
            q1   <= 1'b1;
            rst_n <= q1;
        end
    end

endmodule
