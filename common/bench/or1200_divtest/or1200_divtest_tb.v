// or1200_divtest_tb.v
// 2016, rok.krajnc@gmail.com

`define SOC_SIM

`timescale 1ns/100ps
`define CLK_HPER 10


module or1200_divtest_tb();


//// clock & reset ////
reg clk;
reg rst;

initial begin
  clk = 1'b0;
  rst = 1'b1;
  repeat (10) @ (posedge clk);
  #1;
  rst = 1'b0;
end

always #`CLK_HPER clk = ~clk;


//// bench logic ////
integer fn;
integer j;

// or1200 r3
wire [31:0] r3w;
assign r3w = or1200.or1200.or1200_cpu.or1200_rf.rf_a.mem[3];

initial begin
  $display("SIM START");
  memory.load_hex("../../bench/or1200_divtest/fw/bin/or1200_divtest.hex");
  fn = $fopen("out/hex/sim_out.hex", "w");
end

always @ (posedge clk) begin
  // putc
  if (or1200.or1200.or1200_cpu.or1200_ctrl.wb_insn == 32'h1500_0004) begin
    $fwrite(fn, "%c", or1200.or1200.or1200_cpu.or1200_rf.rf_a.mem[3]);
  end
  // exit
  if (or1200.or1200.or1200_cpu.or1200_ctrl.wb_insn == 32'h1500_0001) begin
    $display("SIM EXIT");
    $finish();
  end
end

final begin
  $fclose(fn);
end


//// modules ////

// or1200
localparam CAW = 24;
localparam CDW = 32;
localparam CSW = 4;

wire            dcpu_cs;
wire            dcpu_we;
wire  [CSW-1:0] dcpu_sel;
wire  [CAW-1:0] dcpu_adr;
wire  [CDW-1:0] dcpu_dat_w;
wire  [CDW-1:0] dcpu_dat_r;
wire            dcpu_ack;
wire            icpu_cs;
wire            icpu_we;
wire  [CSW-1:0] icpu_sel;
wire  [CAW-1:0] icpu_adr;
wire  [CDW-1:0] icpu_dat_w;
wire  [CDW-1:0] icpu_dat_r;
wire            icpu_ack;

or1200_top_wrapper #(
  .AW (CAW)
) or1200 (
  // system
  .clk          (clk        ),
  .rst          (rst        ),
  // data bus
  .dcpu_cs      (dcpu_cs    ),
  .dcpu_we      (dcpu_we    ),
  .dcpu_sel     (dcpu_sel   ),
  .dcpu_adr     (dcpu_adr   ),
  .dcpu_dat_w   (dcpu_dat_w ),
  .dcpu_dat_r   (dcpu_dat_r ),
  .dcpu_ack     (dcpu_ack   ),
  // instruction bus
  .icpu_cs      (icpu_cs    ),
  .icpu_we      (icpu_we    ),
  .icpu_sel     (icpu_sel   ),
  .icpu_adr     (icpu_adr   ),
  .icpu_dat_w   (icpu_dat_w ),
  .icpu_dat_r   (icpu_dat_r ),
  .icpu_ack     (icpu_ack   )
);

// QMEM arbiter
localparam MN = 2;

wire [MN-1:0]          marb_cs;
wire [MN-1:0]          marb_we;
wire [MN-1:0][CSW-1:0] marb_sel;
wire [MN-1:0][CAW-1:0] marb_adr;
wire [MN-1:0][CDW-1:0] marb_dat_w;
wire [MN-1:0][CDW-1:0] marb_dat_r;
wire [MN-1:0]          marb_ack;
wire [MN-1:0]          marb_err;
wire            sarb_cs;
wire            sarb_we;
wire  [CSW-1:0] sarb_sel;
wire  [CAW-1:0] sarb_adr;
wire  [CDW-1:0] sarb_dat_w;
wire  [CDW-1:0] sarb_dat_r;
wire            sarb_ack;
wire            sarb_err;
wire  [MN-1:0]  arb_ms;

qmem_arbiter #(
  .QAW(CAW),
  .QDW(CDW),
  .QSW(CDW/8),
  .MN(MN)
) arbiter (
  // system
  .clk          (clk        ),
  .rst          (rst        ),
  // slave port
  .qm_cs        (marb_cs    ),
  .qm_we        (marb_we    ),
  .qm_sel       (marb_sel   ),
  .qm_adr       (marb_adr   ),
  .qm_dat_w     (marb_dat_w ),
  .qm_dat_r     (marb_dat_r ),
  .qm_ack       (marb_ack   ),
  .qm_err       (marb_err   ),
  // master port
  .qs_cs        (sarb_cs    ),
  .qs_we        (sarb_we    ),
  .qs_sel       (sarb_sel   ),
  .qs_adr       (sarb_adr   ),
  .qs_dat_w     (sarb_dat_w ),
  .qs_dat_r     (sarb_dat_r ),
  .qs_ack       (sarb_ack   ),
  .qs_err       (sarb_err   ),
  // one hot master status (bit MN is always 1'b0)
  .ms           (arb_ms     )
);

// QMEM slave memory
localparam MAW = 11;
localparam MDW = 32;
localparam MIC = "";

qmem_slave #(
  .QAW(MAW),
  .QDW(MDW),
  .QSW(MDW/8),
  .MS(1<<MAW)
) memory (
  .clk          (clk        ),
  .rst          (rst        ),
  .cs           (sarb_cs    ),
  .we           (sarb_we    ),
  .sel          (sarb_sel   ),
  .adr          (sarb_adr[MAW-1:0]),
  .dat_w        (sarb_dat_w ),
  .dat_r        (sarb_dat_r ),
  .ack          (sarb_ack   ),
  .err          (sarb_err   )
);

// assigns
assign marb_cs    [0] = dcpu_cs;
assign marb_we    [0] = dcpu_we;
assign marb_sel   [0] = dcpu_sel;
assign marb_adr   [0] = dcpu_adr;
assign marb_dat_w [0] = dcpu_dat_w;
assign dcpu_dat_r     = marb_dat_r[0];
assign dcpu_ack       = marb_ack[0];
assign marb_cs    [1] = icpu_cs;
assign marb_we    [1] = icpu_we;
assign marb_sel   [1] = icpu_sel;
assign marb_adr   [1] = icpu_adr;
assign marb_dat_w [1] = icpu_dat_w;
assign icpu_dat_r     = marb_dat_r[1];
assign icpu_ack       = marb_ack[1];


//// dump ////
initial begin
  $dumpfile("out/wav/or1200_divtest_dump.fst");
  $dumpvars(0, or1200_divtest_tb);
end


endmodule

