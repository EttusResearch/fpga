//
// Copyright (c) 2017 Ettus Research
//

module axi_crossbar_wrapper
#(
  parameter REG_BASE    = 0,  // settings bus base address
  parameter FIFO_WIDTH  = 64, // AXI4-STREAM data bus width
  parameter DST_WIDTH   = 16, // Width of DST field we are routing on.
  parameter NUM_INPUTS  = 2,  // number of input AXI4-STREAM buses
  parameter NUM_OUTPUTS = 2,   // number of output AXI4-STREAM buses
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 14  // Width of the address bus
)
(
  input                                 clk,
  input                                 reset,
  input                                 clear,

  input                                 reg_wr_req,
  input  [REG_AWIDTH-1:0]               reg_wr_addr,
  input  [REG_DWIDTH-1:0]               reg_wr_data,

  input                                 reg_rd_req,
  input  [REG_AWIDTH-1:0]               reg_rd_addr,
  output [REG_DWIDTH-1:0]               reg_rd_data,
  output                                reg_rd_resp,

  input [7:0]                           local_addr,
  // Inputs
  input [(FIFO_WIDTH*NUM_INPUTS)-1:0]   i_tdata,
  input [NUM_INPUTS-1:0]                i_tvalid,
  input [NUM_INPUTS-1:0]                i_tlast,
  output [NUM_INPUTS-1:0]               i_tready,
  input [NUM_INPUTS-1:0]                pkt_present,

  // Output
  output [(FIFO_WIDTH*NUM_OUTPUTS)-1:0] o_tdata,
  output [NUM_OUTPUTS-1:0]              o_tvalid,
  output [NUM_OUTPUTS-1:0]              o_tlast,
  input [NUM_OUTPUTS-1:0]               o_tready
);

  wire                  xbar_set_stb;
  wire [REG_DWIDTH-1:0] xbar_set_data;
  wire [15:0]           xbar_set_addr;

  wire                  xbar_rb_stb;
  wire [15:0]           xbar_rb_addr;
  wire [REG_DWIDTH-1:0] xbar_rb_data;

  regport_to_xbar_settingsbus
  #(
    .BASE(REG_BASE),
    .DWIDTH(REG_DWIDTH),
    .AWIDTH(REG_AWIDTH)
  )
  inst_regport_to_xbar_settingsbus
  (
    .clk(clk),
    .reset(reset),

    .reg_wr_req(reg_wr_req),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .reg_rd_req(reg_rd_req),
    .reg_rd_addr(reg_rd_addr),
    .reg_rd_data(reg_rd_data),
    .reg_rd_resp(reg_rd_resp),

    .set_stb(xbar_set_stb),
    .set_addr(xbar_set_addr),
    .set_data(xbar_set_data),
    .rb_stb(xbar_rb_stb),
    .rb_addr(xbar_rb_addr),
    .rb_data(xbar_rb_data)
  );

  axi_crossbar
  #(
    .BASE(0), // TODO: Set to 0 as logic for other values has not been tested
    .FIFO_WIDTH(FIFO_WIDTH),
    .DST_WIDTH(DST_WIDTH),
    .NUM_INPUTS(NUM_INPUTS),
    .NUM_OUTPUTS(NUM_OUTPUTS)
  ) axi_crossbar
  (
    .clk(clk),
    .reset(reset),
    .clear(1'b0),
    .local_addr(local_addr),

    // settings bus for config
    .set_stb(xbar_set_stb),
    .set_addr({4'b0000,xbar_set_addr[13:2]}),
    .set_data(xbar_set_data),
    .rb_rd_stb(xbar_rb_stb),
    /* TODO: FIX THIS SHIT */
    .rb_addr(xbar_rb_addr[`LOG2(NUM_INPUTS)+`LOG2(NUM_OUTPUTS)-1+2:2]), // Also word aligned
    .rb_data(xbar_rb_data),

    // inputs, real men flatten busses
    .i_tdata(i_tdata),
    .i_tlast(i_tlast),
    .i_tvalid(i_tvalid),
    .i_tready(i_tready),

    // outputs, real men flatten busses
    .o_tdata(o_tdata),
    .o_tlast(o_tlast),
    .o_tvalid(o_tvalid),
    .o_tready(o_tready),
    .pkt_present(pkt_present)
  );


endmodule

