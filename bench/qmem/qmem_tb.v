// qmem_tb.v
// 2016, rok.krajnc@gmail.com

`define SOC_SIM

`timescale 1ns/100ps
`define CLK_HPER 10


module qmem_tb();


//// signals ////

// system signals
reg clk;
reg rst;

// QMEM parameters
localparam MAW = 10;    // masters address width
localparam AD = 10;     // masters allowed delay
localparam SAW = 9;     // slave address width
localparam MS = 1<<SAW; // slave memory size
localparam DW = 32;     // data width
localparam SW = DW/8;   // select width
localparam MN = 2;      // number of masters
localparam SN = 2;      // number of slaves

// QMEM bus signals
wire                   m0_cs;
wire                   m0_we;
wire         [ SW-1:0] m0_sel;
wire         [MAW-1:0] m0_adr;
wire         [ DW-1:0] m0_dat_w;
wire         [ DW-1:0] m0_dat_r;
wire                   m0_ack;
wire                   m0_err;
wire                   m0_error;
wire                   m1_cs;
wire                   m1_we;
wire         [ SW-1:0] m1_sel;
wire         [MAW-1:0] m1_adr;
wire         [ DW-1:0] m1_dat_w;
wire         [ DW-1:0] m1_dat_r;
wire                   m1_ack;
wire                   m1_err;
wire                   m1_error;
wire [MN-1:0]          marb_cs;
wire [MN-1:0]          marb_we;
wire [MN-1:0][ SW-1:0] marb_sel;
wire [MN-1:0][MAW-1:0] marb_adr;
wire [MN-1:0][ DW-1:0] marb_dat_w;
wire [MN-1:0][ DW-1:0] marb_dat_r;
wire [MN-1:0]          marb_ack;
wire [MN-1:0]          marb_err;
wire [MN-1:0]          ms;
wire                   bus_cs;
wire                   bus_we;
wire         [ SW-1:0] bus_sel;
wire         [MAW-1:0] bus_adr;
wire         [ DW-1:0] bus_dat_w;
wire         [ DW-1:0] bus_dat_r;
wire                   bus_ack;
wire                   bus_err;
wire [SN-1:0]          sdec_cs;
wire [SN-1:0]          sdec_we;
wire [SN-1:0][ SW-1:0] sdec_sel;
wire [SN-1:0][SAW-1:0] sdec_adr;
wire [SN-1:0][ DW-1:0] sdec_dat_w;
wire [SN-1:0][ DW-1:0] sdec_dat_r;
wire [SN-1:0]          sdec_ack;
wire [SN-1:0]          sdec_err;
wire [SN-1:0]          ss;
wire                   s0_cs;
wire                   s0_we;
wire         [ SW-1:0] s0_sel;
wire         [SAW-1:0] s0_adr;
wire         [ DW-1:0] s0_dat_w;
wire         [ DW-1:0] s0_dat_r;
wire                   s0_ack;
wire                   s0_err;
wire                   s1_cs;
wire                   s1_we;
wire         [ SW-1:0] s1_sel;
wire         [SAW-1:0] s1_adr;
wire         [ DW-1:0] s1_dat_w;
wire         [ DW-1:0] s1_dat_r;
wire                   s1_ack;
wire                   s1_err;


//// clock & reset ////
initial begin
  clk = 1'b0;
  rst = 1'b1;
  repeat (4) @ (posedge clk);
  #1;
  rst = 1'b0;
end

always #`CLK_HPER clk = ~clk;


//// error tracking ////
reg err = 0;

always @ (*) begin
  if (!rst) begin
    if (m0_err)   err = 1'b1;
    if (m1_err)   err = 1'b1;
    if (s0_err)   err = 1'b1;
    if (s1_err)   err = 1'b1;
    if (m0_error) err = 1'b1;
    if (m0_error) err = 1'b1;
  end
end

always @ (*) begin
  if (err) begin
    $display("QMEM_TB : %08dns : FAILED : error raised (m0_err=%01d m0_error=%01d m1_err=%01d m1_error=%01d s0_err=%01d s1_err=%01d", $time, m0_err, m0_error, m1_err, m1_error, s0_err, s1_err);
    //repeat(10) @ (posedge clk); #1;
    $finish(-1);
  end
end


//// sim guard ////
initial begin
#1ms $display("QMEM_TB : %08dns : FAILED : sim time guard passed", $time);
$finish(-1);
end


//// testbench ////
integer m0_cnt, m1_cnt;
reg [DW-1:0] m0_dat, m1_dat;

initial begin
  $display("QMEM_TB : START");

  // fill slaves with zeros
  s0.fill_zeros();
  s1.fill_zeros();

  // wait for un-reset
  wait(!rst);
  @ (posedge clk); #1;

  // run masters

  // m0 only, write, s0
  for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
    m0.write(4*m0_cnt, 'hf, 32'h01000000+m0_cnt);
    if (s0.mem[m0_cnt] !== 32'h01000000+m0_cnt) begin force m0_err = 1'b1; force s0_err = 1'b1; end
  end
  // m0 only, write, s1
  for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
    m0.write((1<<SAW)+4*m0_cnt, 'hf, 32'h02000000+m0_cnt);
    if (s1.mem[m0_cnt] !== 32'h02000000+m0_cnt) begin force m0_err = 1'b1; force s1_err = 1'b1; end
  end
  // m1 only, write, s0
  for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
    m1.write(4*(64+m1_cnt), 'hf, 32'h03000000+m1_cnt);
    if (s0.mem[64+m1_cnt] !== 32'h03000000+m1_cnt) begin force m1_err = 1'b1; force s0_err = 1'b1; end
  end
  // m1 only, write, s1
  for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
    m1.write((1<<SAW)+4*(64+m1_cnt), 'hf, 32'h04000000+m1_cnt);
    if (s1.mem[64+m1_cnt] !== 32'h04000000+m1_cnt) begin force m1_err = 1'b1; force s1_err = 1'b1; end
  end
  @ (posedge clk); #1;

  // m0, rwr
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h10, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h10, 32'hdead0001, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h10, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h10, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h14, 32'hdead0001, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h18, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h18, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h14, 32'hdead0001, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h10, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b0, 1'bx, 4'hx, 10'hxx, 32'hxxxxxxxx, 1'b0);
  @ (posedge clk); #1;
  if (s0.mem['h10>>2] !== 32'hdead0001) begin $display("s0.mem['h10>>2] = %08x", s0.mem['h10>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h14>>2] !== 32'hdead0001) begin $display("s0.mem['h14>>2] = %08x", s0.mem['h14>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h18>>2] !== 32'h00000000) begin $display("s0.mem['h18>>2] = %08x", s0.mem['h18>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end

  // m0, wrw
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h20, 32'hdead0002, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h20, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h20, 32'hdead0002, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h20, 32'hdead0002, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h24, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h28, 32'hdead0002, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h28, 32'hdead0002, 1'b0);
  m0.cycle(1'b1, 1'b0, 4'hf, 10'h24, 32'hxxxxxxxx, 1'b0);
  m0.cycle(1'b1, 1'b1, 4'hf, 10'h20, 32'hdead0002, 1'b0);
  m0.cycle(1'b0, 1'bx, 4'hx, 10'hxx, 32'hxxxxxxxx, 1'b0);
  @ (posedge clk); #1;
  if (s0.mem['h20>>2] !== 32'hdead0002) begin $display("s0.mem['h20>>2] = %08x", s0.mem['h20>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h24>>2] !== 32'h00000000) begin $display("s0.mem['h24>>2] = %08x", s0.mem['h24>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h28>>2] !== 32'hdead0002) begin $display("s0.mem['h28>>2] = %08x", s0.mem['h28>>2]); force m0_err = 1'b1; force s0_err = 1'b1; end

  // m1, rwr
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h30, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h30, 32'hdead0003, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h30, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h30, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h34, 32'hdead0003, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h38, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h38, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h34, 32'hdead0003, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h30, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b0, 1'bx, 4'hx, 10'hxx, 32'hxxxxxxxx, 1'b0);
  @ (posedge clk); #1;
  if (s0.mem['h30>>2] !== 32'hdead0003) begin $display("s0.mem['h30>>2] = %08x", s0.mem['h30>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h34>>2] !== 32'hdead0003) begin $display("s0.mem['h34>>2] = %08x", s0.mem['h34>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h38>>2] !== 32'h00000000) begin $display("s0.mem['h38>>2] = %08x", s0.mem['h38>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end

  // m1, wrw
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h40, 32'hdead0004, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h40, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h40, 32'hdead0004, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h40, 32'hdead0004, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h44, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h48, 32'hdead0004, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h48, 32'hdead0004, 1'b0);
  m1.cycle(1'b1, 1'b0, 4'hf, 10'h44, 32'hxxxxxxxx, 1'b0);
  m1.cycle(1'b1, 1'b1, 4'hf, 10'h40, 32'hdead0004, 1'b0);
  m1.cycle(1'b0, 1'bx, 4'hx, 10'hxx, 32'hxxxxxxxx, 1'b0);
  @ (posedge clk); #1;
  if (s0.mem['h40>>2] !== 32'hdead0004) begin $display("s0.mem['h40>>2] = %08x", s0.mem['h40>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h44>>2] !== 32'h00000000) begin $display("s0.mem['h44>>2] = %08x", s0.mem['h44>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end
  if (s0.mem['h48>>2] !== 32'hdead0004) begin $display("s0.mem['h48>>2] = %08x", s0.mem['h48>>2]); force m1_err = 1'b1; force s0_err = 1'b1; end

  // both masters write, same slave
  fork
  begin : m0_fork0
    for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
      m0.write(10'h50+4*m0_cnt, 'hf, m0_cnt);
      if (s0.mem[('h50>>2)+m0_cnt] !== m0_cnt) begin $display("s0.mem['h50>>2+m0_cnt] = %08x", s0.mem['h50>>2+m0_cnt]); force m0_err = 1'b1; force s0_err = 1'b1; end
    end
    for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
      m0.write(10'h70+4*m0_cnt, 'hf, m0_cnt);
      if (s0.mem[('h70>>2)+m0_cnt] !== m0_cnt) begin $display("s0.mem['h70>>2+m0_cnt] = %08x", s0.mem['h70>>2+m0_cnt]); force m0_err = 1'b1; force s0_err = 1'b1; end
    end
  end
  begin : m1_fork0
    for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
      m1.write(10'h60+4*m1_cnt, 'hf, m1_cnt);
      if (s0.mem[('h60>>2)+m1_cnt] !== m1_cnt) begin $display("s0.mem['h60>>2+m1_cnt] = %08x", s0.mem['h60>>2+m1_cnt]); force m1_err = 1'b1; force s0_err = 1'b1; end
    end
    for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
      m1.write(10'h80+4*m1_cnt, 'hf, m1_cnt);
      if (s0.mem[('h80>>2)+m1_cnt] !== m1_cnt) begin $display("s0.mem['h80>>2+m1_cnt] = %08x", s0.mem['h80>>2+m1_cnt]); force m1_err = 1'b1; force s0_err = 1'b1; end
    end
  end
  join
  @ (posedge clk); #1;

  // both masters write, different slaves
  fork
  begin : m0_fork1
    for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
      m0.write(10'h90+4*m0_cnt, 'hf, m0_cnt);
      if (s0.mem[('h90>>2)+m0_cnt] !== m0_cnt) begin $display("s0.mem['h90>>2+m0_cnt] = %08x", s0.mem['h90>>2+m0_cnt]); force m0_err = 1'b1; force s0_err = 1'b1; end
    end
  end
  begin : m1_fork1
    for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
      m1.write((1<<SAW)+10'h90+4*m1_cnt, 'hf, m1_cnt);
      if (s1.mem[('h90>>2)+m1_cnt] !== m1_cnt) begin $display("s1.mem['h90>>2+m1_cnt] = %08x", s1.mem['h90>>2+m1_cnt]); force m1_err = 1'b1; force s1_err = 1'b1; end
    end
  end
  join
  @ (posedge clk); #1;

  // m0 writes, m1 reads
  fork
  begin : m0_fork2
    for (m0_cnt=0; m0_cnt<4; m0_cnt=m0_cnt+1) begin
      m0.write(10'hb0+4*m0_cnt, 'hf, m0_cnt);
      if (s0.mem[('hb0>>2)+m0_cnt] !== m0_cnt) begin $display("s0.mem['hb0>>2+m0_cnt] = %08x", s0.mem['hb0>>2+m0_cnt]); force m0_err = 1'b1; force s0_err = 1'b1; end
    end
  end
  begin : m1_fork2
    for (m1_cnt=0; m1_cnt<4; m1_cnt=m1_cnt+1) begin
      m1.read((1<<SAW)+10'h90+4*m1_cnt, 'hf, m1_dat);
      if (m1_dat !== m1_cnt) begin $display("m1_dat = %08x", m1_dat); force m1_err = 1'b1; force s1_err = 1'b1; end
    end
  end
  join
  @ (posedge clk); #1;

  // end
  repeat(4) @ (posedge clk); #1;
  $display("QMEM_TB : PASSED");
  $finish(0);
end


//// assigns ////
assign marb_cs    [0] = m0_cs;
assign marb_we    [0] = m0_we;
assign marb_sel   [0] = m0_sel;
assign marb_adr   [0] = m0_adr;
assign marb_dat_w [0] = m0_dat_w;
assign m0_dat_r       = marb_dat_r  [0];
assign m0_ack         = marb_ack    [0];
assign m0_err         = marb_err    [0];
assign marb_cs    [1] = m1_cs;
assign marb_we    [1] = m1_we;
assign marb_sel   [1] = m1_sel;
assign marb_adr   [1] = m1_adr;
assign marb_dat_w [1] = m1_dat_w;
assign m1_dat_r       = marb_dat_r  [1];
assign m1_ack         = marb_ack    [1];
assign m1_err         = marb_err    [1];
assign ss[0]          = !bus_adr[MAW-1];
assign ss[1]          =  bus_adr[MAW-1];
assign s0_cs          = sdec_cs     [0];
assign s0_we          = sdec_we     [0];
assign s0_sel         = sdec_sel    [0];
assign s0_adr         = sdec_adr    [0];
assign s0_dat_w       = sdec_dat_w  [0];
assign sdec_dat_r [0] = s0_dat_r;
assign sdec_ack   [0] = s0_ack;
assign sdec_err   [0] = s0_err;
assign s1_cs          = sdec_cs     [1];
assign s1_we          = sdec_we     [1];
assign s1_sel         = sdec_sel    [1];
assign s1_adr         = sdec_adr    [1];
assign s1_dat_w       = sdec_dat_w  [1];
assign sdec_dat_r [1] = s1_dat_r;
assign sdec_ack   [1] = s1_ack;
assign sdec_err   [1] = s1_err;


//// modules ////

// QMEM masters
qmem_master #(
  .QAW(MAW),
  .QDW(DW),
  .QSW(SW),
  .AD(AD)
) m0 (
  // system signals
  .clk          (clk        ),  // clock
  .rst          (rst        ),  // reset
  // qmem interface
  .cs           (m0_cs      ),  // chip-select
  .we           (m0_we      ),  // write enable
  .sel          (m0_sel     ),  // byte select
  .adr          (m0_adr     ),  // address
  .dat_w        (m0_dat_w   ),  // write data
  .dat_r        (m0_dat_r   ),  // read data
  .ack          (m0_ack     ),  // acknowledge
  .err          (m0_err     ),  // error
  // error
  .error        (m0_error   )   // error on bus detected
);

qmem_master #(
  .QAW(MAW),
  .QDW(DW),
  .QSW(SW),
  .AD(AD)
) m1 (
  // system signals
  .clk          (clk        ),  // clock
  .rst          (rst        ),  // reset
  // qmem interface
  .cs           (m1_cs      ),  // chip-select
  .we           (m1_we      ),  // write enable
  .sel          (m1_sel     ),  // byte select
  .adr          (m1_adr     ),  // address
  .dat_w        (m1_dat_w   ),  // write data
  .dat_r        (m1_dat_r   ),  // read data
  .ack          (m1_ack     ),  // acknowledge
  .err          (m1_err     ),  // error
  // error
  .error        (m1_error   )   // error on bus detected
);

// QMEM arbiter
qmem_arbiter #(
  .QAW(MAW),
  .QDW(DW),
  .QSW(SW),
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
  .qs_cs        (bus_cs     ),
  .qs_we        (bus_we     ),
  .qs_sel       (bus_sel    ),
  .qs_adr       (bus_adr    ),
  .qs_dat_w     (bus_dat_w  ),
  .qs_dat_r     (bus_dat_r  ),
  .qs_ack       (bus_ack    ),
  .qs_err       (bus_err    ),
  // one hot master status (bit MN is always 1'b0)
  .ms           (ms         )
);


// QMEM decoder
qmem_decoder #(
  .QAW(SAW),
  .QDW(DW),
  .QSW(SW),
  .SN(SN)
) decoder (
  // system
  .clk          (clk        ),
  .rst          (rst        ),
  // slave port
  .qm_cs        (bus_cs     ),
  .qm_we        (bus_we     ),
  .qm_sel       (bus_sel    ),
  .qm_adr       (bus_adr[SAW-1:0]),
  .qm_dat_w     (bus_dat_w  ),
  .qm_dat_r     (bus_dat_r  ),
  .qm_ack       (bus_ack    ),
  .qm_err       (bus_err    ),
  // master port
  .qs_cs        (sdec_cs    ),
  .qs_we        (sdec_we    ),
  .qs_sel       (sdec_sel   ),
  .qs_adr       (sdec_adr   ),
  .qs_dat_w     (sdec_dat_w ),
  .qs_dat_r     (sdec_dat_r ),
  .qs_ack       (sdec_ack   ),
  .qs_err       (sdec_err   ),
  // one hot slave select signal
  .ss           (ss         )
);

// QMEM slaves
qmem_slave #(
  .QAW(SAW),
  .QDW(DW),
  .QSW(SW),
  .MS(MS)
) s0 (
  .clk          (clk        ),
  .rst          (rst        ),
  .cs           (s0_cs      ),
  .we           (s0_we      ),
  .sel          (s0_sel     ),
  .adr          (s0_adr     ),
  .dat_w        (s0_dat_w   ),
  .dat_r        (s0_dat_r   ),
  .ack          (s0_ack     ),
  .err          (s0_err     )
);

qmem_slave #(
  .QAW(SAW),
  .QDW(DW),
  .QSW(SW),
  .MS(MS)
) s1 (
  .clk          (clk        ),
  .rst          (rst        ),
  .cs           (s1_cs      ),
  .we           (s1_we      ),
  .sel          (s1_sel     ),
  .adr          (s1_adr     ),
  .dat_w        (s1_dat_w   ),
  .dat_r        (s1_dat_r   ),
  .ack          (s1_ack     ),
  .err          (s1_err     )
);


//// dump ////
`ifdef WAVEDUMP
initial begin
  $dumpfile("out/wav/wavedummp.vcd");
  $dumpvars(0, qmem_tb);
end
`endif


endmodule

