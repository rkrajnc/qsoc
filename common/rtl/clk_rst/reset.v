// reset.v
// 2016, rok.krajnc@gmail.com


module reset #(
  parameter NCK = 1,          // number of input clocks and reset outputs
  parameter RCW = 16,         // size of reset counter
  parameter RCV = {RCW{1'b1}} // counter max value
)(
  // clock
  input  wire [NCK-1:0] clk,
  // asynchronous reset input
  input  wire           rst_in,
  // reset signal output
  output wire [NCK-1:0] rst_out
);


//// internal signals ////
genvar i;
reg   [RCW-1:0] rst_cnt         = RCV;
wire            rst_cnt0;
reg             rst_in_sync_0   = 1'b1;
reg             rst_in_sync_1   = 1'b1;
reg   [NCK-1:0] rst_out_sync_0  = {NCK{1'b1}};
reg   [NCK-1:0] rst_out_sync_1  = {NCK{1'b1}};


//// reset input sync ////
always @ (posedge clk[0]) rst_in_sync_0 <= rst_in;
always @ (posedge clk[0]) rst_in_sync_1 <= rst_in_sync_0;


//// reset counter (only on clock 0!) ////
always @ (posedge clk[0]) begin
  if (rst_in_sync_1)
    rst_cnt <= #1 RCV;
  else if (rst_cnt0)
    rst_cnt <= #1 rst_cnt - 1'd1;
end

assign rst_cnt0 = |rst_cnt;


//// reset output sync ////
generate for (i=0; i<NCK; i=i+1) begin : RST_OUT_SYNC_BLOCK
always @ (posedge clk[i]) rst_out_sync_0[i] <= rst_cnt0;
always @ (posedge clk[i]) rst_out_sync_1[i] <= rst_out_sync_0[i];
end endgenerate


//// reset output ////

assign rst_out = rst_out_sync_1;


endmodule
