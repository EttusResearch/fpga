//
// Copyright (c) 2017 Ettus Research
//
module regport_to_xbar_settingsbus
#(
  parameter BASE   = 0,
  parameter DWIDTH = 32,
  parameter AWIDTH = 14,
  parameter SR_AWIDTH = 12
)
(
  input                   clk,
  input                   reset,

  input                   reg_wr_req,
  input [AWIDTH-1:0]      reg_wr_addr,
  input [DWIDTH-1:0]      reg_wr_data,

  input                   reg_rd_req,
  input [AWIDTH-1:0]      reg_rd_addr,
  output [DWIDTH-1:0]     reg_rd_data,
  output                  reg_rd_resp,

  output                  set_stb,
  output [AWIDTH-1:0]     set_addr,
  output [DWIDTH-1:0]     set_data,

  output                  rb_stb,
  output reg [AWIDTH-1:0] rb_addr,
  input  [DWIDTH-1:0]     rb_data
);

reg              reg_rd_resp_int;

always @(posedge clk)
  if (reset) begin
    reg_rd_resp_int <= 1'b0;
    rb_addr     <= 'd0;
  end
  else if (reg_rd_req) begin
    rb_addr         <= reg_rd_addr - BASE;
    reg_rd_resp_int <= reg_rd_req;
  end
  else if (reg_rd_resp_int) begin
    reg_rd_resp_int <= 1'b0;
    rb_addr         <= 'd0;
  end

assign set_stb  = reg_wr_req & ~(|set_addr[AWIDTH-1:SR_AWIDTH]); //Assert set_stb only when address range matches the xbar address range
assign set_addr = reg_wr_addr - BASE;
assign set_data = reg_wr_data;

assign rb_stb   = reg_rd_resp_int & ~(|rb_addr[AWIDTH-1:SR_AWIDTH]); //Assert rb_stb only when address range matches the xbar address range
assign reg_rd_resp = rb_stb;
assign reg_rd_data = rb_data;

endmodule
