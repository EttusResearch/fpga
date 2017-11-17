//
// Copyright (c) 2017 Ettus Research
//
module regport_to_xbar_settingsbus
#(
  parameter BASE   = 14'h0,
  parameter END_ADDR = 14'h3FFF,
  parameter DWIDTH = 32,
  parameter AWIDTH = 14,
  parameter SR_AWIDTH = 12,
  // Dealign for settings bus by shifting by 2
  parameter DEALIGN = 0
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
  output [SR_AWIDTH-1:0]  set_addr,
  output [DWIDTH-1:0]     set_data,

  output                  rb_stb,
  output [SR_AWIDTH-1:0]  rb_addr,
  input  [DWIDTH-1:0]     rb_data
);

reg              reg_rd_req_delay;
reg              reg_rd_req_delay2;
wire [AWIDTH-1:0] set_addr_int;
reg [AWIDTH-1:0] rb_addr_int;

always @(posedge clk)
  begin
    if (reset) begin
      reg_rd_req_delay <= 1'b0;
      reg_rd_req_delay2 <= 1'b0;
      rb_addr_int     <= 'd0;
    end
    else if (reg_rd_req) begin
      rb_addr_int <= reg_rd_addr - BASE;
      reg_rd_req_delay <= 1'b1;
    end
    else if (reg_rd_req_delay) begin
      reg_rd_req_delay2 <= 1'b1;
      reg_rd_req_delay <= 1'b0;
    end
    // Deassert after two clock cycles
    else if (reg_rd_req_delay2) begin
      reg_rd_req_delay <= 1'b0;
      reg_rd_req_delay2 <= 1'b0;
      rb_addr_int     <= 'd0;
    end
    else begin
      reg_rd_req_delay <= 1'b0;
      reg_rd_req_delay2 <= 1'b0;
      rb_addr_int     <= 'd0;
    end
  end

// Strobe asserted only when address is between BASE and END ADDR
assign set_stb = reg_wr_req & (reg_wr_addr >= BASE) & (reg_wr_addr <= END_ADDR);
assign set_addr_int = reg_wr_addr - BASE;
assign set_addr = DEALIGN ? {2'b0, set_addr_int[SR_AWIDTH-1:2]}
                          : set_addr_int[SR_AWIDTH-1:0];
assign set_data = reg_wr_data;

assign rb_addr = DEALIGN ? {2'b0, rb_addr_int[SR_AWIDTH-1:2]}
                          : rb_addr_int[SR_AWIDTH-1:0];
// Strobe asserted two cycle after read request only when address is between BASE and END ADDR
// This is specific to the xbar as the xbar delays read data by an extra clock
// cycle to relax timing.
assign rb_stb  = reg_rd_req_delay2 & (reg_rd_addr >= BASE) & (reg_rd_addr <= END_ADDR);
assign reg_rd_resp = rb_stb;
assign reg_rd_data = rb_data;

endmodule
