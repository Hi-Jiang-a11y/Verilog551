module up_dwn_cnt4 (
    input clk,
    input en,
    input rst_n,
    input dwn,
    output reg [3:0] cnt
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'b0;
        else if (en)
            if (dwn)
                cnt <= cnt - 4'b1;
            else
                cnt <= cnt + 4'b1;
    end

endmodule
