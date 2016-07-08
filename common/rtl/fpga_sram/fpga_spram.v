module fpga_spram #(
  parameter QAW = 32,             // qmem address width
  parameter QDW = 32,             // data width
  parameter QSW = QDW/8,          // select width
  parameter MS  = 1024,           // memory size
  parameter MSI = "./init.hex",   // simulation memory init file
  parameter MFI = "./init.mif",   // fpga memory init file
  parameter MRM = 1,              // enable or disable runtime fpga memory mods
  parameter MRN = "fpga_spram"    // fpga memory instance name
)(
  // system
  input  wire           clk,
  // master 0 (dcpu)
  input  wire [QAW-1:0] adr,
  input  wire           cs,
  input  wire           we,
  input  wire [QSW-1:0] sel,
  input  wire [QDW-1:0] dat_w,
  output wire [QDW-1:0] dat_r,
  output wire           ack,
  output wire           err
);


//// local parameters ////
localparam MAW  = QAW-2;
localparam MDW  = QDW;
localparam MSW  = QSW;
localparam MBW  = QDW/QSW;
localparam MSEL = QSW >1 ? 1 : 0;
localparam RTMM = MRM ? {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=", MRN} : "ENABLE_RUNTIME_MOD=NO";


//// synchronous memory instance ////

`ifdef SOC_SIM
// generic RAM TODO untested

integer i;
reg [MSW-1:0][MBW-1:0] mem [0:MS-1];
reg [QDW-1:0] q;

always @ (posedge clk) begin
  if (cs && we) begin
    for (i=0; i<MSW; i=i+1) begin : BYTE_MEM_BLOCK
      mem[adr][i] <= #1 dat_w[i*MBW+:MBW];
    end
  end
  if (cs && !we) begin
    q <= #1 mem[adr];
  end
end

assign dat_r = q;


`else // !SOC_SIM
// FPGA RAM
////`ifdef QSOC_ALTERA
// ALTERA RAM
  altsyncram  altsyncram_component (
    .address_a      (adr[QAW-1:2] ),
    .byteena_a      (MSEL?sel:1'b1),
    .clock0         (clk          ),
    .data_a         (dat_w        ),
    .wren_a         (cs && we     ),
    .q_a            (dat_r        ),
    .aclr0          (1'b0),
    .aclr1          (1'b0),
    .address_b      (1'b1),
    .addressstall_a (1'b0),
    .addressstall_b (1'b0),
    .byteena_b      (1'b1),
    .clock1         (1'b1),
    .clocken0       (1'b1),
    .clocken1       (1'b1),
    .clocken2       (1'b1),
    .clocken3       (1'b1),
    .data_b         (1'b1),
    .eccstatus      (),
    .q_b            (),
    .rden_a         (1'b1),
    .rden_b         (1'b1),
    .wren_b         (1'b0));
  defparam
    altsyncram_component.byte_size = MBW,
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
  `ifdef NO_PLI
    altsyncram_component.init_file = "data.rif",
  `else
    altsyncram_component.init_file = MFI,
  `endif
    altsyncram_component.intended_device_family = "Cyclone III",
    altsyncram_component.lpm_hint = RTMM,
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = MS,
    altsyncram_component.operation_mode = "SINGLE_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.read_during_write_mode_port_a = "OLD_DATA",
    altsyncram_component.widthad_a = 10,
    altsyncram_component.width_a = QDW,
    altsyncram_component.width_byteena_a = QSW;
////`endif // QSOC_ALTERA

`endif // SOC_SIM


//// bus output signals ////

assign ack = cs;
assign err = 1'b0; // TODO


endmodule

