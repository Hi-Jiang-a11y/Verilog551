module adder (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       cin,
    output wire       cout,
    output wire [3:0] sum
);

    assign {cout, sum} = { A} + {B} + cin;

endmodule
