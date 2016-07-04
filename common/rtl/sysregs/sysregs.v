/********************************************/
/* sysregs.v                                */
/* basic system registers                   */
/*                                          */
/* 2016, rok.krajnc@gmail.com               */
/********************************************/


`ifdef QSOC_VERSION_INCLUDE
`include "qsoc_version.vh"
`endif


module sysregs #(
  // QMEM bus params
  parameter QAW = 22,             // qmem address width
  parameter QDW = 32,             // qmem data width
  parameter QSW = QDW/8,          // qmem select width
  // width params
  parameter RSTW  = 4,            // reset width
  parameter CFGW  = 8,            // config width
  parameter STAW  = 8,            // status width
  parameter SCSW  = 4,            // SPI CS width
  parameter GIOW  = 16,           // GPIO width
  // implementation params
  parameter IMPL_RST   = 1,       // implement reset register
  parameter IMPL_CFG   = 1,       // implement config (output) register
  parameter IMPL_STAT  = 1,       // implement status (input) register
  parameter IMPL_UART  = 1,       // implement UART
  parameter IMPL_TIMER = 1,       // implement timer
  parameter IMPL_SPI   = 1,       // implement SPI
  parameter IMPL_GPIO  = 1        // implement GPIO
)(
  // system
  input  wire             clk,
  input  wire             rst,
  // qmem bus
  input  wire [  QAW-1:0] adr,
  input  wire             cs,
  input  wire             we,
  input  wire [  QSW-1:0] sel,
  input  wire [  QDW-1:0] dat_w,
  output reg  [  QDW-1:0] dat_r,
  output reg              ack,
  output wire             err,
  // io
  output wire [ RSTW-1:0] rst_out,
  output wire [ CFGW-1:0] cfg,
  input  wire [ STAW-1:0] status,
  output wire             uart_txd,
  input  wire             uart_rxd,
  output reg  [ SCSW-1:0] spi_cs_n,
  output wire             spi_clk,
  output wire             spi_do,
  input  wire             spi_di,
  input  wire [ GIOW-1:0] gpio_i,
  output wire [ GIOW-1:0] gpio_o,
  output wire [ GIOW-1:0] gpio_oe
);



////////////////////////////////////////
// local parameters                   //
////////////////////////////////////////

// address width for register decoding
localparam RAW = 6;

// registers
// version register (RO, xxxxx000)
localparam [RAW-1:0] VER_ADR          = 'h00; // RO
// capabilities (RO, xxxxx004)
localparam [RAW-1:0] CAP_ADR          = 'h01; // RO
// reset control (WO, xxxxx008)
localparam [RAW-1:0] RST_ADR          = 'h02; // WO
// config register (RW, xxxxx00c)
localparam [RAW-1:0] CFG_ADR          = 'h03; // RW
// status register (RO, xxxxx010)
localparam [RAW-1:0] STAT_ADR         = 'h04; // RO
// timer registers (xxxxx020 - xxxxx028)
localparam [RAW-1:0] TICK_TIMER_ADR   = 'h08; // RO
localparam [RAW-1:0] MS_TIMER_ADR     = 'h09; // RW
localparam [RAW-1:0] TIMER_CTRL_ADR   = 'h0a; // RW
// UART registers (xxxxx040 - xxxxx050)
localparam [RAW-1:0] UART_TX_DAT_ADR  = 'h10; // WO
localparam [RAW-1:0] UART_RX_DAT_ADR  = 'h11; // RO
localparam [RAW-1:0] UART_TX_CNT_ADR  = 'h12; // RW
localparam [RAW-1:0] UART_RX_CNT_ADR  = 'h13; // RW
localparam [RAW-1:0] UART_STAT_ADR    = 'h14; // RO
// SPI registers (xxxxx080 - xxxxx090)
localparam [RAW-1:0] SPI_DIV_ADR      = 'h20; // RW
localparam [RAW-1:0] SPI_CS_ADR       = 'h21; // RW
localparam [RAW-1:0] SPI_DAT_ADR      = 'h22; // RW
localparam [RAW-1:0] SPI_BLOCK_ADR    = 'h23; // WO
// GPIO registers (xxxxx0c0 - xxxxx0d8)
localparam [RAW-1:0] GPIO_MASK_ADR    = 'h30; // RW
localparam [RAW-1:0] GPIO_DIR_ADR     = 'h31; // RW
localparam [RAW-1:0] GPIO_SET_ADR     = 'h32; // WO
localparam [RAW-1:0] GPIO_CLR_ADR     = 'h33; // WO
localparam [RAW-1:0] GPIO_DO_ADR      = 'h34; // RW
localparam [RAW-1:0] GPIO_DI_ADR      = 'h35; // RO



////////////////////////////////////////
// QMEM delay registers               //
////////////////////////////////////////

reg  [RAW+2-1:0] adr_r=0;
reg              cs_r=0;
reg              we_r=0;

always @ (posedge clk, posedge rst) begin
  if (rst)
    cs_r <= #1 1'b0;
  else
    cs_r <= #1 cs;
end

always @ (posedge clk) begin
  adr_r <= #1 adr[RAW+2-1:0];
  we_r  <= #1 we;
end



////////////////////////////////////////
// version output                     //
////////////////////////////////////////

wire [  32-1:0] version;
`ifndef QSOC_VER_MAJOR
`define QSOC_VER_MAJOR 8'd0
`define QSOC_VER_MINOR 8'd1
`define QSOC_VER_BETA  8'd255
`endif
assign version = {8'd0 /*TODO*/, `QSOC_VER_BETA, `QSOC_VER_MAJOR, `QSOC_VER_MINOR};



////////////////////////////////////////
// capabilities output                //
////////////////////////////////////////

wire [  32-1:0] capabilities;
//                     unimpl 7     6             5            4              3             2             1            0
assign capabilities = {24'b0, 1'b0, IMPL_GPIO[0], IMPL_SPI[0], IMPL_TIMER[0], IMPL_UART[0], IMPL_STAT[0], IMPL_CFG[0], IMPL_RST[0]};



////////////////////////////////////////
// reset                              //
////////////////////////////////////////

reg             rst_wren=0;
reg  [RSTW-1:0] rst_reg=0;

generate if (IMPL_RST) begin : RST_BLOCK
always @ (posedge clk, posedge rst) begin
  if (rst)
    rst_reg <= #1 {(RSTW){1'b0}};
  else if (rst_wren)
    rst_reg <= #1 dat_w[31] ? dat_w[RSTW-1:0] : {(RSTW){1'b0}};
end
end endgenerate

assign rst_out = IMPL_RST ? rst_reg : {(RSTW){1'b0}};



////////////////////////////////////////
// config                             //
////////////////////////////////////////

reg             cfg_wren;
reg  [CFGW-1:0] cfg_reg=0;

generate if (IMPL_CFG) begin : CFG_BLOCK
always @ (posedge clk, posedge rst) begin
  if (rst)
    cfg_reg <= #1 {(CFGW){1'b0}};
  else if (cfg_wren)
    cfg_reg <= #1 dat_w[CFGW-1:0];
end
end endgenerate

assign cfg = IMPL_CFG ? cfg_reg : {(CFGW){1'b0}};



////////////////////////////////////////
// status                             //
////////////////////////////////////////

reg  [STAW-1:0] status_reg;
wire [  32-1:0] status_out;

generate if (IMPL_STAT) begin : STAT_BLOCK
always @ (posedge clk) status_reg <= #1 status;
end endgenerate

assign status_out = IMPL_STAT ? status_reg : {(STAW){1'b0}};



////////////////////////////////////////
// timer                              //
////////////////////////////////////////

// timer precounter value for 1ms @ 50MHz system clock
localparam TIMER_CNT    = 16'd50_000;

reg  [  16-1:0] ms_pre_timer;
reg             ms_timer_wren;
reg  [  16-1:0] ms_timer;
wire [  16-1:0] ms_timer_out;
reg  [  32-1:0] tick_timer;
wire [  32-1:0] tick_timer_out;
reg             timer_ctrl_wren;
reg  [   2-1:0] timer_ctrl;
wire [   2-1:0] timer_ctrl_out;

generate if (IMPL_TIMER) begin : TIMER_BLOCK

// timer control
always @ (posedge clk, posedge rst) begin
  if (rst)
    timer_ctrl <= #1 {1'b1, 1'b0};
  else if (timer_ctrl_wren)
    timer_ctrl <= #1 dat_w[1:0];
end

// ms pre timer counter
always @ (posedge clk, posedge rst) begin
  if (rst)
    ms_pre_timer <= #1 TIMER_CNT - 16'd1;
  else if (ms_timer_wren)
    ms_pre_timer <= #1 TIMER_CNT - 16'd1;
  else if (~|ms_pre_timer)
    ms_pre_timer <= #1 TIMER_CNT - 16'd1;
  else if (timer_ctrl[1])
    ms_pre_timer <= #1 ms_pre_timer - 16'd1;
end

// ms timer
// using ms pre_timer, this increases each milisecond
always @ (posedge clk, posedge rst) begin
  if (rst)
    ms_timer <= #1 16'h0000;
  else if (ms_timer_wren)
    ms_timer <= #1 dat_w[15:0];
  else if (~|ms_pre_timer)
    ms_timer <= #1 ms_timer + 16'h1;
end

// tick timer
always @ (posedge clk, posedge rst) begin
  if (rst)
    tick_timer <= #1 32'd0;
  else if (timer_ctrl[0])
    tick_timer <= #1 tick_timer + 32'd1;
end

end endgenerate

assign timer_ctrl_out = IMPL_TIMER ? timer_ctrl : 2'b00;
assign ms_timer_out   = IMPL_TIMER ? ms_timer : 16'd0;
assign tick_timer_out = IMPL_TIMER ? tick_timer : 32'd0;



////////////////////////////////////////
// UART transmit                      //
////////////////////////////////////////

// TODO add TX FIFO

// UART TxD counter value for 115200 @ 50MHz system clock (= 50000000 / 115200)
localparam TXD_CNT = 13'd434;

reg             tx_wren;
reg             tx_cnt_wren;
reg  [  13-1:0] tx_cnt;
wire [  13-1:0] tx_cnt_out;
reg  [  13-1:0] tx_timer=0;
reg  [   4-1:0] tx_bitcounter=0;
wire            tx_ready;
reg  [  10-1:0] tx_reg;

generate if (IMPL_UART) begin : UART_TXD_BLOCK

// TX cnt
// sets baud rate (default: 115200Baud, minimum: 9600Baud)
always @ (posedge clk, posedge rst) begin
  if (rst)
    tx_cnt <= #1 TXD_CNT - 13'd1;
  else if (tx_cnt_wren)
    tx_cnt <= dat_w[13-1:0];
end

// TX timer
always @ (posedge clk, posedge rst) begin
  if (rst)
    tx_timer <= #1 13'd0;
  else if (tx_wren && tx_ready)
    tx_timer <= #1 tx_cnt;
  else if (|tx_timer)
    tx_timer <= #1 tx_timer - 13'd1;
  else if (|tx_bitcounter)
    tx_timer <= #1 tx_cnt;
end

// TX bit counter
always @ (posedge clk, posedge rst) begin
  if (rst)
    tx_bitcounter <= #1 4'd0;
  else if (tx_wren && tx_ready)
    tx_bitcounter <= #1 4'd11 - 4'd1;
  else if ((|tx_bitcounter) && (~|tx_timer))
    tx_bitcounter <= #1 tx_bitcounter - 4'd1;
end

// TX register
// 8N1 transmit format
always @ (posedge clk, posedge rst) begin
  if (rst)
    tx_reg <= #1 10'b1111111111;
  else if (tx_wren && tx_ready)
    tx_reg <= #1 {1'b1, dat_w[7:0], 1'b0};
  else if (~|tx_timer)
    tx_reg <= #1 {1'b1, tx_reg[9:1]};
end

end endgenerate

// TX ready
assign tx_ready = IMPL_UART ? (~|tx_bitcounter) && (~|tx_timer) : 1'b1;

// UART TXD
assign uart_txd = IMPL_UART ? tx_reg[0] : 1'b1;

assign tx_cnt_out = IMPL_UART ? tx_cnt : 13'd0;



////////////////////////////////////////
// UART receive                       //
////////////////////////////////////////

// TODO add RX FIFO

// UART RxD counter value for 115200 @ 50MHz with 16x oversampling (= 50000000 / 115200 / 16)
localparam RXD_CNT = 7'd27;

reg             rx_cnt_wren;
reg  [   7-1:0] rx_cnt;
wire [   7-1:0] rx_cnt_out;
reg  [   2-1:0] rxd_sync = 2'b11;
reg             rxd_bit = 1'b1;
wire            rx_start;
reg  [   5-1:0] rx_sample_cnt = RXD_CNT - 1;
reg  [   4-1:0] rx_oversample_cnt = 4'b1111;
wire            rx_sample;
reg             rx_sample_d=0;
reg  [   4-1:0] rx_bit_cnt = 4'd0;
reg  [  10-1:0] rx_recv = 10'd0;
reg  [   8-1:0] rx_reg = 8'd0;
wire [   8-1:0] rx_reg_out;
reg             rx_valid = 1'b0;
wire            rx_valid_out;
wire            rx_ready;
reg             rx_wren;
reg             rx_miss=0;
wire            rx_miss_out;
reg             uart_stat_wren;

generate if (IMPL_UART) begin : UART_RXD_BLOCK

// sync input
always @ (posedge clk) rxd_sync <= #1 {rxd_sync[0], uart_rxd};

// detect start condition
// start condition is negedge of rx line
always @ (posedge clk) rxd_bit <= #1 rxd_sync[1];
assign rx_start = rxd_bit && !rxd_sync[1] && ~|rx_bit_cnt;

// RX cnt
// sets baud rate (default: 115200Baud, minimum: 9600Baud)
always @ (posedge clk, posedge rst) begin
  if (rst)
    rx_cnt <= #1 RXD_CNT - 7'd1;
  else if (rx_cnt_wren)
    rx_cnt <= dat_w[7-1:0];
end

// sampling counter
always @ (posedge clk) begin
  if (rx_start || ~|rx_sample_cnt) rx_sample_cnt <= #1 rx_cnt;
  else if (|rx_bit_cnt) rx_sample_cnt <= rx_sample_cnt -1;
end

// oversampling counter
// set for 16x oversampling
always @ (posedge clk) begin
  if (rx_start) rx_oversample_cnt <= #1 4'b1111;
  else if (~|rx_sample_cnt) rx_oversample_cnt <= #1 rx_oversample_cnt - 1;
end

assign rx_sample = (rx_oversample_cnt == 4'b1000) && (~|rx_sample_cnt);
always @ (posedge clk) rx_sample_d <= #1 rx_sample;

// bit counter
// 8N1 format = 10bits
always @ (posedge clk) begin
  if (rx_start) rx_bit_cnt <= #1 4'd10;
  else if (rx_sample && |rx_bit_cnt) rx_bit_cnt <= #1 rx_bit_cnt - 1;
end

// RX receive register
// 8N1 format
always @ (posedge clk) begin
  if (rx_sample && |rx_bit_cnt) rx_recv <= #1 {rxd_bit, rx_recv[9:1]};
end

// RX data register
always @ (posedge clk) begin
  if (~|rx_bit_cnt && rx_recv[9] && rx_sample_d) rx_reg <= #1 rx_recv[8:1];
end

// RX valid
// set when valid frame is received, reset when rx_reg is read
always @ (posedge clk) begin
  if (~|rx_bit_cnt && rx_sample_d) rx_valid <= #1 rx_recv[9];
  else if ((adr_r[RAW+2-1:2] == UART_RX_DAT_ADR) && cs_r && !we_r) rx_valid <= #1 1'b0;
end

// RX missed char
// set when there is a valid char in output reg but it wasn't read, reset by reading the UART status
always @ (posedge clk) begin
  if (rx_valid && (~|rx_bit_cnt && rx_recv[9] && rx_sample_d)) rx_miss <= #1 1'b1;
  else if ((adr_r[RAW+2-1:2] == UART_RX_DAT_ADR) && cs_r && !we_r) rx_miss <= #1 1'b0;
end

end endgenerate

// RX ready
// is the receiver ready
assign rx_ready     = IMPL_UART ? ~|rx_bit_cnt : 1'b1;

assign rx_valid_out = IMPL_UART ? rx_valid : 1'b0;
assign rx_miss_out  = IMPL_UART ? rx_miss : 1'b0;
assign rx_reg_out   = IMPL_UART ? rx_reg : 8'd0;
assign rx_cnt_out   = IMPL_UART ? rx_cnt : 7'd0;



////////////////////////////////////////
// SPI                                //
////////////////////////////////////////

// this is SPI mode 3 (CPOL=1, CPHA=1)
// clock default state is HI, data are captured on clock's rising edge and data are propagated on a falling edge

// SPI counter value for 400kHz @ 50MHz system clock (SD init clock)
localparam SPI_CNT      = 6'd63;

reg             spi_cs_n_wren;
wire [SCSW-1:0] spi_cs_n_out;
reg             spi_act;
reg             spi_act_d;
reg  [   6-1:0] spi_div;
reg  [   6-1:0] spi_div_r;
wire [   6-1:0] spi_div_r_out;
reg             spi_div_wren;
reg  [   4-1:0] spi_cnt;
reg  [   8-1:0] spi_dat_w;
reg             spi_dat_wren;
reg  [   8-1:0] spi_dat_r;
wire [   8-1:0] spi_dat_r_out;
reg             spi_block_wren;
reg  [  10-1:0] spi_block;

generate if (IMPL_SPI) begin : SPI_BLOCK

// SPI chip-select (active low)
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_cs_n <= #1 {(SCSW){1'b1}};
  else if (spi_cs_n_wren)
    spi_cs_n <= #1 dat_w[SCSW-1:0];
end

// SPI active
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_act <= #1 1'b0;
  else if (spi_act && (~|spi_cnt) && (~|spi_div) && (~|spi_block))
    spi_act <= #1 1'b0;
  else if (spi_dat_wren && !spi_act_d)
    spi_act <= #1 1'b1;
end

// SPI active - last cycle
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_act_d <= #1 1'b0;
  else if (spi_act && (~|spi_cnt) && (~|spi_div) && (~|spi_block))
    spi_act_d  <= #1 1'b1;
  else if (spi_act_d && (~|spi_div))
    spi_act_d  <= #1 1'b0;
end

// SPI clock divider register
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_div_r <= #1 SPI_CNT - 6'd1;
  else if (spi_div_wren && !(spi_act || spi_act_d))
    spi_div_r <= #1 dat_w[5:0];
end

// SPI clock divider
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_div <= #1 SPI_CNT - 6'd1;
  else if (spi_div_wren && !(spi_act || spi_act_d))
    spi_div <= #1 dat_w[5:0];
  else if (spi_act && (~|spi_div))
    spi_div <= #1 spi_div_r;
  else if ((spi_act || spi_act_d) && ( |spi_div))
    spi_div <= #1 spi_div - 6'd1;
end

// SPI counter
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_cnt <= #1 4'b1111;
  else if (spi_act && (~|spi_div))
    spi_cnt <= #1 spi_cnt - 4'd1;
end

// SPI clock
assign spi_clk = spi_cnt[0];

// SPI write data
always @ (posedge clk) begin
  if (spi_dat_wren && !(spi_act || spi_act_d))
    spi_dat_w <= #1 dat_w[7:0];
  else if (spi_act && spi_clk && (~|spi_div) && (~(&spi_cnt)))
    spi_dat_w <= #1 {spi_dat_w[6:0], 1'b1};
end

// SPI data out
assign spi_do = spi_dat_w[7];

// SPI read data
always @ (posedge clk) begin
  if (spi_act && !spi_clk && (~|spi_div))
    spi_dat_r <= #1 {spi_dat_r[6:0], spi_di};
end

// SPI block count
always @ (posedge clk, posedge rst) begin
  if (rst)
    spi_block <= #1 10'd0;
  else if (spi_block_wren && !(spi_act || spi_act_d))
    spi_block <= #1 dat_w[9:0];
  else if (spi_act && (~|spi_div) && (~|spi_cnt) && (|spi_block))
    spi_block <= #1 spi_block - 10'd1;
end

end endgenerate

assign spi_cs_n_out   = IMPL_SPI ? spi_cs_n : {(SCSW){1'b1}};
assign spi_div_r_out  = IMPL_SPI ? spi_div_r : 6'd0;
assign spi_dat_r_out  = IMPL_SPI ? spi_dat_r : 8'd0;



////////////////////////////////////////
// GPIO                               //
////////////////////////////////////////

reg  [GIOW-1:0] gpio_i_sync_0=0;
reg  [GIOW-1:0] gpio_i_sync=0;
wire [GIOW-1:0] gpio_i_out;
reg  [GIOW-1:0] gpio_mask=0;
wire [GIOW-1:0] gpio_mask_out;
reg             gpio_mask_wren;
reg  [GIOW-1:0] gpio_dir=0;
wire [GIOW-1:0] gpio_dir_out;
reg             gpio_dir_wren;
reg  [GIOW-1:0] gpio_dat=0;
wire [GIOW-1:0] gpio_dat_out;
reg             gpio_dat_wren;
reg             gpio_set_wren;
reg             gpio_clr_wren;

generate if (IMPL_GPIO) begin : GPIO_BLOCK

// sync input
always @ (posedge clk) begin
  gpio_i_sync_0 <= #1 gpio_i;
  gpio_i_sync   <= #1 gpio_i_sync_0;
end

// gpio mask
always @ (posedge clk, posedge rst) begin
  if (rst)
    gpio_mask <= #1 {(GIOW){1'b1}};
  else if (gpio_mask_wren)
    gpio_mask <= #1 dat_w[GIOW-1:0];
end

// gpio dir
always @ (posedge clk, posedge rst) begin
  if (rst)
    gpio_dir <= #1 {(GIOW){1'b1}};
  else if (gpio_dir_wren)
    gpio_dir <= #1 dat_w[GIOW-1:0];
end

// gpio dat
 always @ (posedge clk, posedge rst) begin
  if (rst)
    gpio_dat <= #1 {(GIOW){1'b1}};
  else if (gpio_dat_wren)
    gpio_dat <= #1 (~gpio_mask[GIOW-1:0] & gpio_dat[GIOW-1:0]) |  (gpio_mask[GIOW-1:0] & dat_w[GIOW-1:0]);
  else if (gpio_set_wren)
    gpio_dat <= #1 gpio_dat[GIOW-1:0]                          |  (gpio_mask[GIOW-1:0] & dat_w[GIOW-1:0]);
  else if (gpio_clr_wren)
    gpio_dat <= #1 gpio_dat[GIOW-1:0]                          & ~(gpio_mask[GIOW-1:0] & dat_w[GIOW-1:0]);
end

end endgenerate

assign gpio_i_out    = IMPL_GPIO ? gpio_i_sync : {(GIOW){1'b0}};
assign gpio_mask_out = IMPL_GPIO ? gpio_mask   : {(GIOW){1'b1}};
assign gpio_dir_out  = IMPL_GPIO ? gpio_dir    : {(GIOW){1'b0}};
assign gpio_dat_out  = IMPL_GPIO ? gpio_dat    : {(GIOW){1'b0}};

assign gpio_o        = gpio_dat_out;
assign gpio_oe       = gpio_dir;



////////////////////////////////////////
// registers write enable             //
////////////////////////////////////////

always @ (*) begin
  if (cs && we) begin
      rst_wren        = 1'b0;
      cfg_wren        = 1'b0;
      ms_timer_wren   = 1'b0;
      timer_ctrl_wren = 1'b0;
      tx_wren         = 1'b0;
      tx_cnt_wren     = 1'b0;
      rx_cnt_wren     = 1'b0;
      spi_div_wren    = 1'b0;
      spi_cs_n_wren   = 1'b0;
      spi_dat_wren    = 1'b0;
      spi_block_wren  = 1'b0;
      gpio_mask_wren  = 1'b0;
      gpio_dir_wren   = 1'b0;
      gpio_set_wren   = 1'b0;
      gpio_clr_wren   = 1'b0;
      gpio_dat_wren   = 1'b0;
    case(adr[RAW+2-1:2])
      RST_ADR         : rst_wren        = 1'b1;
      CFG_ADR         : cfg_wren        = 1'b1;
      MS_TIMER_ADR    : ms_timer_wren   = 1'b1;
      TIMER_CTRL_ADR  : timer_ctrl_wren = 1'b1;
      UART_TX_DAT_ADR : tx_wren         = 1'b1;
      UART_TX_CNT_ADR : tx_cnt_wren     = 1'b1;
      UART_RX_CNT_ADR : rx_cnt_wren     = 1'b1;
      SPI_DIV_ADR     : spi_div_wren    = 1'b1;
      SPI_CS_ADR      : spi_cs_n_wren   = 1'b1;
      SPI_DAT_ADR     : spi_dat_wren    = 1'b1;
      SPI_BLOCK_ADR   : spi_block_wren  = 1'b1;
      GPIO_MASK_ADR   : gpio_mask_wren  = 1'b1;
      GPIO_DIR_ADR    : gpio_dir_wren   = 1'b1;
      GPIO_SET_ADR    : gpio_set_wren   = 1'b1;
      GPIO_CLR_ADR    : gpio_clr_wren   = 1'b1;
      GPIO_DO_ADR     : gpio_dat_wren   = 1'b1;
      default : begin
        rst_wren        = 1'b0;
        cfg_wren        = 1'b0;
        ms_timer_wren   = 1'b0;
        timer_ctrl_wren = 1'b0;
        tx_wren         = 1'b0;
        tx_cnt_wren     = 1'b0;
        rx_cnt_wren     = 1'b0;
        spi_div_wren    = 1'b0;
        spi_cs_n_wren   = 1'b0;
        spi_dat_wren    = 1'b0;
        spi_block_wren  = 1'b0;
        gpio_mask_wren  = 1'b0;
        gpio_dir_wren   = 1'b0;
        gpio_set_wren   = 1'b0;
        gpio_clr_wren   = 1'b0;
        gpio_dat_wren   = 1'b0;
      end
    endcase
  end else begin
    rst_wren        = 1'b0;
    cfg_wren        = 1'b0;
    ms_timer_wren   = 1'b0;
    timer_ctrl_wren = 1'b0;
    tx_wren         = 1'b0;
    tx_cnt_wren     = 1'b0;
    rx_cnt_wren     = 1'b0;
    spi_div_wren    = 1'b0;
    spi_cs_n_wren   = 1'b0;
    spi_dat_wren    = 1'b0;
    spi_block_wren  = 1'b0;
    gpio_mask_wren  = 1'b0;
    gpio_dir_wren   = 1'b0;
    gpio_set_wren   = 1'b0;
    gpio_clr_wren   = 1'b0;
    gpio_dat_wren   = 1'b0;
  end
end



////////////////////////////////////////
// registers read                     //
////////////////////////////////////////

always @ (posedge clk) begin
  if (cs && !we) begin
    case(adr[RAW+2-1:2])
      VER_ADR         : dat_r <= #1 version;
      CAP_ADR         : dat_r <= #1 capabilities;
      CFG_ADR         : dat_r <= #1 {{(32-CFGW){1'b0}}, cfg};
      STAT_ADR        : dat_r <= #1 {{(32-STAW){1'b0}}, status_out};
      TICK_TIMER_ADR  : dat_r <= #1 tick_timer_out;
      MS_TIMER_ADR    : dat_r <= #1 {16'd0, ms_timer_out};
      TIMER_CTRL_ADR  : dat_r <= #1 {30'd0, timer_ctrl_out};
      UART_RX_DAT_ADR : dat_r <= #1 {24'd0, rx_reg_out};
      UART_TX_CNT_ADR : dat_r <= #1 {19'd0, tx_cnt_out};
      UART_RX_CNT_ADR : dat_r <= #1 {19'd0, rx_cnt_out};
      UART_STAT_ADR   : dat_r <= #1 {28'h0000000, tx_ready, rx_ready, rx_miss_out, rx_valid_out};
      SPI_DIV_ADR     : dat_r <= #1 {26'h0000000, spi_div_r_out};
      SPI_CS_ADR      : dat_r <= #1 {{(32-SCSW){1'b0}}, spi_cs_n_out};
      SPI_DAT_ADR     : dat_r <= #1 {24'h000000, spi_dat_r_out};
      GPIO_MASK_ADR   : dat_r <= #1 {{(32-GIOW){1'b0}}, gpio_mask_out};
      GPIO_DIR_ADR    : dat_r <= #1 {{(32-GIOW){1'b0}}, gpio_dir_out};
      GPIO_DO_ADR     : dat_r <= #1 {{(32-GIOW){1'b0}}, gpio_dat_out};
      GPIO_DI_ADR     : dat_r <= #1 {{(32-GIOW){1'b0}}, gpio_mask_out & gpio_i_out};
      default         : dat_r <= #1 32'hxxxxxxxx;
    endcase
  end
end



////////////////////////////////////////
// ack & err                          //
////////////////////////////////////////

// ack
always @ (*) begin
  case(adr[RAW+2-1:2])
    UART_TX_DAT_ADR : ack = tx_ready;
    SPI_DIV_ADR,
    SPI_CS_ADR,
    SPI_DAT_ADR,
    SPI_BLOCK_ADR : ack = !(spi_act | spi_act_d);
    default       : ack = 1'b1;
  endcase
end

// err TODO
assign err = 1'b0;



endmodule

