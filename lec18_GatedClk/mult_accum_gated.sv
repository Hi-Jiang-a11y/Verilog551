module mult_accum_gated(clk,clr,en,A,B,accum);

input clk,clr,en;
input [15:0] A,B;
output reg [63:0] accum;

reg [31:0] prod_reg;
reg en_stg2;

// A clock-enable must be latched while clk is low.  This prevents the
// enable from changing during the active (high) phase of the gated clock.
reg prod_en_lat;
reg accum_en_lat;
wire prod_clk = clk & prod_en_lat;
wire accum_clk = clk & accum_en_lat;

///////////////////////////////////////////
// Generate and flop product if enabled //
/////////////////////////////////////////
always_latch begin
    if (!clk)
      prod_en_lat <= en;
end

always_latch begin
    // clr is synchronous, so keep the clock running while it is asserted.
    if (!clk)
      accum_en_lat <= en_stg2 | clr;
end

always_ff @(posedge prod_clk)
    prod_reg <= A*B;

/////////////////////////////////////////////////////
// Pipeline the enable signal to accumulate stage //
///////////////////////////////////////////////////
always_ff @(posedge clk)
    en_stg2 <= en;

always_ff @(posedge accum_clk)
    if (clr)
      accum <= 64'h0000000000000000;
    else
      accum <= accum + {{32{1'b0}}, prod_reg};

endmodule
