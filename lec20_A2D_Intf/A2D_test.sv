module A2D_test(clk,RST_n,SEL,LED,SS_n,SCLK,MOSI,MISO);

input clk,RST_n;	// 50MHz clock and unsynchronized reset from push button
input SEL;			// from 2nd push button, selects next result to view
output [7:0] LED;	// upper 8-bits of selected conversion result
output SS_n;		// SPI interface to A2D on DE0-Nano
output SCLK;
output MOSI;
input MISO;

wire rst_n;
wire [11:0] lft_ld, rght_ld, steer_pot, batt;
wire full;
wire released;
logic [18:0] cnv_cnt;	// 19-bit free running counter, full drives nxt (~95 conversions/sec)
logic [1:0] sel_cnt;	// selects which result is shown on LEDs
logic [11:0] sel_rslt;

  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

  ////// 19-bit free running counter //////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnv_cnt <= 19'h00000;
    else
      cnv_cnt <= cnv_cnt + 19'h00001;

  assign full = &cnv_cnt;

  ////// instantiate A2D_intf //////
  A2D_intf iA2D(.clk(clk),.rst_n(rst_n),.nxt(full),.lft_ld(lft_ld),
                .rght_ld(rght_ld),.steer_pot(steer_pot),.batt(batt),
                .SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));

  ////// SEL push button advances 2-bit select counter //////
  PB_release iPB(.clk(clk),.rst_n(rst_n),.PB(SEL),.released(released));

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      sel_cnt <= 2'b00;
    else if (released)
      sel_cnt <= sel_cnt + 2'b01;

  always_comb
    case (sel_cnt)
      2'b00: sel_rslt = lft_ld;
      2'b01: sel_rslt = rght_ld;
      2'b10: sel_rslt = steer_pot;
      default: sel_rslt = batt;
    endcase

  assign LED = sel_rslt[11:4];

endmodule
