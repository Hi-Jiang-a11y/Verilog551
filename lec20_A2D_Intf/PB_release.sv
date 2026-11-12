module PB_release(clk, rst_n, PB, released);

    input logic clk, rst_n, PB;
    output logic released;

    logic q1, q2, q3;

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            q1 <= 1'b1;
            q2 <= 1'b1;
            q3 <= 1'b1;
        end
        else begin
            q1 <= PB;
            q2 <= q1;
            q3 <= q2;
        end

    assign released = q2 & ~q3;

endmodule
