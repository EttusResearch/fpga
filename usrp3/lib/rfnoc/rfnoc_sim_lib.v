//
// Copyright 2014 Ettus Research LLC
//

  localparam [1:0] CHDR_DATA_PKT_TYPE             = 0;
  localparam [1:0] CHDR_FC_PKT_TYPE               = 1;
  localparam [1:0] CHDR_CTRL_PKT_TYPE             = 2;

  // One register per port, spaced by 16 for 16 ports
  localparam [7:0] SR_FLOW_CTRL_CYCS_PER_ACK_BASE = 0;
  localparam [7:0] SR_FLOW_CTRL_PKTS_PER_ACK_BASE = 16;
  localparam [7:0] SR_FLOW_CTRL_WINDOW_SIZE_BASE  = 32;
  localparam [7:0] SR_FLOW_CTRL_WINDOW_EN_BASE    = 48;
  // One register per noc shell
  localparam [7:0] SR_FLOW_CTRL_CLR_SEQ           = 126;
  localparam [7:0] SR_NOC_SHELL_READBACK          = 127;
  // Next destinations as allocated by the user, one per port (if used)
  localparam [7:0] SR_NEXT_DST_BASE               = 128;
  localparam [7:0] SR_READBACK_ADDR               = 255;

  reg clk;
  initial clk = 1'b0;
  localparam CLOCK_PERIOD = 1e9/CLOCK_FREQ;
  always
    #(CLOCK_PERIOD) clk = ~clk;

  reg rst;
  wire rst_n;
  assign rst_n = ~rst;
  initial
  begin
    rst = 1'b1;
    #(RESET_TIME) rst = 1'b0;
  end

  reg [63:0] i_tdata;
  reg i_tlast, i_tvalid;
  wire i_tready;
  wire [63:0] o_tdata;
  wire o_tlast, o_tvalid, o_tready;

  task SendCtrlPacket;
    input [11:0] seqnum;
    input [31:0] sid;
    input [63:0] data;
  begin
    @(posedge clk);
    i_tdata = { 4'h8, seqnum, 16'h16, sid };
    i_tlast = 0;
    i_tvalid = 1;
    while(~i_tready) @(posedge clk);

    @(posedge clk);
    i_tdata = data;
    i_tlast = 1;
    while(~i_tready) @(posedge clk);

    @(posedge clk);
    i_tdata = 0;
    i_tvalid = 0;
    i_tlast = 0;
    @(posedge clk);
  end
  endtask

  task automatic SendDataPacket;
    input [1:0]  flags;
    input [11:0] seqnum;
    input [12:0] len;
    input [31:0] sid;
    input [63:0] data;
    integer i = 0;
  begin
    @(posedge clk);
    i_tdata = { CHDR_DATA_PKT_TYPE, flags, seqnum, (len << 3) + 16'h8, sid };
    i_tlast = 0;
    i_tvalid = 1;
    @(posedge clk);
    while(~i_tready) @(posedge clk);
    while (i < len) begin
      i_tdata = data + i;
      i = i + 1;
      if (i == len) i_tlast = 1;
      @(posedge clk);
      while(~i_tready) @(posedge clk);
    end
    i_tdata = 0;
    i_tlast = 0;
    i_tvalid = 0;
    @(posedge clk);
  end
  endtask