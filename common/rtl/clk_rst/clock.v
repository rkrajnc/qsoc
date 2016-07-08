// clock.v
// 2016, rok.krajnc@gmail.com


module clock (
  input  wire           pll_rst,    // asynhronous reset input
  input  wire           clk_in,     // input clock        ( 27.000000MHz)
  output wire           clk_sdram,  // SDRAM clock (100 MHz, -146.25deg)
  output wire           clk_100,    // 100MHz clock
  output wire           clk_50,     // 50MHz clock
  output wire           clk_25,     // 25MHz clock
  output wire           locked,     // PLL locked output
  output wire           clk_25_en   // 25 MHz clock enable on 50MHz clock domain
);



`ifdef SOC_SIM

//// simulation clocks ////
reg            clk_sdram_r;
reg            clk_100_r;
reg            clk_50_r;
reg            clk_25_r;
reg            pll_locked_r;
initial begin
  pll_locked_r  = 1'b0;
  wait (!pll_rst);
  #50;
  pll_locked_r  = 1'b1;
end
initial begin
  clk_sdram_r   = 1'b1;
  #1;
  wait (pll_locked_r);
  #1;
  forever #5 clk_sdram_r = ~clk_sdram_r;
end
initial begin
  clk_100_r     = 1'b1;
  #1;
  wait (pll_locked_r);
  #1;
  forever #5 clk_100_r = ~clk_100_r;
end
initial begin
  clk_50_r      = 1'b1;
  #1;
  wait (pll_locked_r);
  #1;
  forever #10 clk_50_r  = ~clk_50_r;
end
initial begin
  clk_25_r      = 1'b1;
  #1;
  wait (pll_locked_r);
  #1;
  forever #20 clk_25_r  = ~clk_25_r;
end
assign clk_sdram  = clk_sdram_r;
assign locked     = pll_locked_r;
assign clk_100    = clk_100_r;
assign clk_50     = clk_50_r;
assign clk_25     = clk_25_r;


`else // !SOC_SIM


//// FPGA PLL ////

// device-specific PLL/DCM
`ifdef QSOC_CYCLONE3
clock_cyclone3 fpga_clock_i (
  .areset   (pll_rst  ),
  .inclk0   (clk_in   ),
  .c0       (clk_sdram),
  .c1       (clk_100  ),
  .c2       (clk_50   ),
  .c3       (clk_25   ),
  .locked   (locked   )
);
`endif // QSOC_CYCLONE3

`ifdef QSOC_XILINX
clock_xilinx fpga_clock_i (
  .areset   (pll_rst  ),
  .inclk0   (clk_in   ),
  .c0       (clk_sdram),
  .c1       (clk_100  ),
  .c2       (clk_50   ),
  .c2       (clk_25   ),
  .locked   (locked   )
);
`endif // QSOC_XILINX

`endif // SOC_SIM



//// generated clocks ////

reg clk_25_en_reg = 1'b1;
always @ (posedge clk_50, negedge locked) begin
  if (!locked) begin
    clk_25_en_reg <= #1 1'b1;
  end else begin
    clk_25_en_reg <= #1 ~clk_25_en_reg;
  end
end

assign clk_25_en = clk_25_en_reg;



endmodule
