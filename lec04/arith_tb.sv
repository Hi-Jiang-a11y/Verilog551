module arith_tb();

reg [7:0] A, B;
reg SUB;

wire [7:0] SUM;
wire OV;

arith alu(
    .A(A),
    .B(B),
    .SUM(SUM),
    .OV(OV),
    .SUB(SUB)
);

initial begin
    
    A = 8'b0111_1111;
    B = 8'b0000_0001;
    SUB = 0;
    #10;
    
    A = 8'b1000_0000;
    B = 8'b1111_1111;
    SUB = 0;
    #10;
    
    A = 8'b1000_0000;
    B = 8'b0000_0001;
    SUB = 1;
    #10;
    
    A = 8'b0111_1111;
    B = 8'b1111_1111;
    SUB = 1;
    #10;
    $stop;
end

endmodule
