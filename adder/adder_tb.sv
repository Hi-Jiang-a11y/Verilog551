module adder_tb;
    logic [3:0] A;
    logic [3:0] B;
    logic [3:0] sum;
    logic cin;
    logic cout;
    logic [4:0] expected;
    integer i;
    integer j;
    integer k;
    integer errors;

    adder dut (.A(A), .B(B), .cin(cin), .cout(cout), .sum(sum));

    initial begin
        errors = 0;

        for (i = 0; i <= 15; i = i + 1) begin
            for (j = 0; j <= 15; j = j + 1) begin
                for (k = 0; k <= 1; k = k + 1) begin
                    A = i;
                    B = j;
                    cin = k;
                    #1;

                    expected = i + j + k;
                    if ({cout, sum} !== expected) begin
                        $error("Mismatch: A=%0d B=%0d cin=%0d expected=%b actual=%b",
                               i, j, k, expected, {cout, sum});
                        errors = errors + 1;
                    end
                end
            end
        end

        if (errors == 0)
            $display("PASS: all cases passed.");
        else
            $display("FAIL: %0d cases failed.", errors);

        $stop;
    end

endmodule
