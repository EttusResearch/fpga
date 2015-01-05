//
// Copyright 2014-2015 Ettus Research LLC
//
// Simulation library containing common code for 
// interfacing and controlling a RFNoC test bench:
// - Sets up clocks and resets
// - Instantiates an AXI crossbar and programs
//   routing table
// - Instantiates a NoC Shell for test bench to 
//   use to communicate with NoC block(s) under test
// - Optional instantiation of AXI wrapper
// - Defines tasks to simplify sending control / data packets
// - Defines various useful constants
//

  /*********************************************
  ** Default user parameters
  *********************************************/
  `ifndef CE_CLOCK_FREQ
  `define CE_CLOCK_FREQ  200e6
  `endif
  `ifndef CE_RESET_TIME
  `define CE_RESET_TIME  100
  `endif
  `ifndef BUS_CLOCK_FREQ
  `define BUS_CLOCK_FREQ 167e6
  `endif
  `ifndef BUS_RESET_TIME
  `define BUS_RESET_TIME 100
  `endif
  `ifndef NUM_CE
  `define NUM_CE 14
  `endif
  // AXI wrapper related
  `ifndef NUM_AXI_CONFIG_BUS
  `define NUM_AXI_CONFIG_BUS 1 // Do not set to 0
  `endif
  `ifndef SIMPLE_MODE
  `define SIMPLE_MODE 1
  `endif


  /*********************************************
  ** Useful Constants
  *********************************************/
  localparam SC16_NUM_BYTES                       = 4;
  localparam RFNOC_BUS_WIDTH                      = 64;
  localparam RFNOC_CHDR_NUM_BYTES_PER_LINE        = RFNOC_BUS_WIDTH/8;
  localparam RFNOC_CHDR_NUM_SC16_PER_LINE         = RFNOC_CHDR_NUM_BYTES_PER_LINE/SC16_NUM_BYTES;


  /*********************************************
  ** Parameters
  ** - CHDR packet settings
  ** - Register addresses
  *********************************************/
  localparam [1:0] CHDR_DATA_PKT_TYPE             = 0;
  localparam [1:0] CHDR_FC_PKT_TYPE               = 1;
  localparam [1:0] CHDR_CTRL_PKT_TYPE             = 2;
  localparam [1:0] CHDR_EOB                       = 1 << 0;
  localparam [1:0] CHDR_HAS_TIME                  = 1 << 1;

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


  /*********************************************
  ** Clocks & Reset
  *********************************************/
  reg ce_clk;
  initial ce_clk = 1'b0;
  localparam CE_CLOCK_PERIOD = 1e9/`CE_CLOCK_FREQ;
  always
    #(CE_CLOCK_PERIOD) ce_clk = ~ce_clk;

  reg bus_clk;
  initial bus_clk = 1'b0;
  localparam BUS_CLOCK_PERIOD = 1e9/`BUS_CLOCK_FREQ;
  always
    #(BUS_CLOCK_PERIOD) bus_clk = ~bus_clk;

  reg ce_rst;
  wire ce_rst_n;
  assign ce_rst_n = ~ce_rst;
  initial begin
    ce_rst = 1'b1;
    #(`CE_RESET_TIME);
    @(posedge ce_clk);
    ce_rst = 1'b0;
  end

  reg bus_rst;
  wire bus_rst_n;
  assign bus_rst_n = ~bus_rst;
  initial begin
    bus_rst = 1'b1;
    #(`BUS_RESET_TIME);
    @(posedge bus_clk);
    bus_rst = 1'b0;
  end


  /*********************************************
  ** Interface signals to AXI crossbar
  *********************************************/
  wire [`NUM_CE*64-1:0] ce_flat_o_tdata, ce_flat_i_tdata;
  wire [63:0]           ce_o_tdata[0:`NUM_CE-1], ce_i_tdata[0:`NUM_CE-1];
  wire [`NUM_CE-1:0]    ce_o_tlast, ce_o_tvalid, ce_o_tready, ce_i_tlast, ce_i_tvalid, ce_i_tready;
  wire [63:0]           ce_debug[0:`NUM_CE-1];

  // Flattern CE tdata arrays
  genvar _i;
  generate
    for (_i = 0; _i < `NUM_CE; _i = _i + 1) begin
      assign ce_o_tdata[_i] = ce_flat_o_tdata[_i*64+63:_i*64];
      assign ce_flat_i_tdata[_i*64+63:_i*64] = ce_i_tdata[_i];
    end
  endgenerate

  wire [63:0] tb_o_tdata, tb_i_tdata;
  wire        tb_o_tlast, tb_o_tvalid, tb_o_tready, tb_i_tlast, tb_i_tvalid, tb_i_tready;

  /*********************************************
  ** AXI crossbar
  *********************************************/
  reg        xbar_set_stb       = 1'b0;
  reg [8:0]  xbar_set_addr      = 8'd0;
  reg [31:0] xbar_set_data      = 32'd0;

  localparam [6:0] BASE         = 8'd0;
  localparam [7:0] XBAR_ADDR    = 8'd3;
  localparam XBAR_PORTS         = `NUM_CE + 1;

  localparam [3:0]  TESTBENCH_XBAR_PORT = 4'd`NUM_CE; // CE's occupy ports 0 - NUM_CE-1
  localparam [15:0] TESTBENCH_SID       = {XBAR_ADDR, TESTBENCH_XBAR_PORT, 4'd0}; // Last 4 bits is the block port

  axi_crossbar #(
    .BASE(BASE),.FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_PORTS), .NUM_OUTPUTS(XBAR_PORTS))
  inst_axi_crossbar (
    .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
    .local_addr(XBAR_ADDR),
    .set_stb(xbar_set_stb), .set_addr({BASE,xbar_set_addr}), .set_data(xbar_set_data),
    .i_tdata({tb_i_tdata,ce_flat_i_tdata}),
    .i_tlast({tb_i_tlast,ce_i_tlast}),
    .i_tvalid({tb_i_tvalid,ce_i_tvalid}),
    .i_tready({tb_i_tready,ce_i_tready}),
    .o_tdata({tb_o_tdata,ce_flat_o_tdata}),
    .o_tlast({tb_o_tlast,ce_o_tlast}),
    .o_tvalid({tb_o_tvalid,ce_o_tvalid}),
    .o_tready({tb_o_tready,ce_o_tready}),
    .pkt_present({tb_i_tvalid,ce_i_tvalid}),
    .rb_rd_stb(), .rb_addr(), .rb_data());


  /*********************************************
  ** NoC Shell for Test bench
  *********************************************/
  wire        tb_set_stb    = 1'b0;
  wire [7:0]  tb_set_addr   = 8'd0;
  wire [31:0] tb_set_data   = 32'd0;
  reg  [63:0] tb_rb_data    = 64'd0;

  reg  [63:0] tb_cmdout_tdata = 64'd0;
  reg         tb_cmdout_tlast = 1'b0, tb_cmdout_tvalid = 1'b0; 
  wire        tb_cmdout_tready;
  wire [63:0] tb_ackin_tdata;
  wire        tb_ackin_tlast, tb_ackin_tvalid;
  reg         tb_ackin_tready = 1'b1;
  wire [63:0] tb_str_sink_tdata;
  wire        tb_str_sink_tlast, tb_str_sink_tvalid;
  wire        tb_str_src_tready;
  wire        tb_clear_tx_seqnum;
  `ifdef RFNOC_SIM_LIB_INC_AXI_WRAPPER
    wire        tb_str_sink_tready;
    wire [63:0] tb_str_src_tdata;
    wire        tb_str_src_tlast, tb_str_src_tvalid;
    localparam  USE_GATE = 0;
  `else
    reg         tb_str_sink_tready = 1'b1;
    reg  [63:0] tb_str_src_tdata = 64'd0;
    reg         tb_str_src_tlast = 1'b0, tb_str_src_tvalid = 1'b0;
    localparam  USE_GATE = 1;
  `endif

  noc_shell #(
    .NOC_ID(64'hFFFF_FFFF_FFFF_FFFF),
    .USE_GATE(USE_GATE))
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(tb_o_tdata), .i_tlast(tb_o_tlast), .i_tvalid(tb_o_tvalid), .i_tready(tb_o_tready),
    .o_tdata(tb_i_tdata), .o_tlast(tb_i_tlast), .o_tvalid(tb_i_tvalid), .o_tready(tb_i_tready),
    .clk(ce_clk), .reset(ce_rst),
    .set_data(tb_set_data), .set_addr(tb_set_addr), .set_stb(tb_set_stb), .rb_data(tb_rb_data),
    .cmdout_tdata(tb_cmdout_tdata), .cmdout_tlast(tb_cmdout_tlast), .cmdout_tvalid(tb_cmdout_tvalid), .cmdout_tready(tb_cmdout_tready),
    .ackin_tdata(tb_ackin_tdata), .ackin_tlast(tb_ackin_tlast), .ackin_tvalid(tb_ackin_tvalid), .ackin_tready(tb_ackin_tready),
    .str_sink_tdata(tb_str_sink_tdata), .str_sink_tlast(tb_str_sink_tlast), .str_sink_tvalid(tb_str_sink_tvalid), .str_sink_tready(tb_str_sink_tready),
    .str_src_tdata(tb_str_src_tdata), .str_src_tlast(tb_str_src_tlast), .str_src_tvalid(tb_str_src_tvalid), .str_src_tready(tb_str_src_tready),
    .clear_tx_seqnum(tb_clear_tx_seqnum),
    .debug());


  /*********************************************
  ** Optional AXI Wrapper
  ** To use define RFNOC_SIM_LIB_INC_AXI_WRAPPER
  *********************************************/
  `ifdef RFNOC_SIM_LIB_INC_AXI_WRAPPER
    wire [31:0]  tb_m_axis_data_tdata;
    wire [127:0] tb_m_axis_data_tuser;
    wire         tb_m_axis_data_tlast;
    wire         tb_m_axis_data_tvalid;
    reg          tb_m_axis_data_tready = 1'b0;
    reg  [31:0]  tb_s_axis_data_tdata  = 32'd0;
    // Sane tuser (CHDR) defaults (only valid if SIMPLE_MODE = 0):
    //   {Data packet, no EOB, no time, Seq num DC, Pkt length DC, SRC SID: Testbench, DSR SID: CE0 Block Port 0, Time DC}
    // DC = Don't care, Seq num & Pkt length handled by AXI Wrapper automatically
    reg  [127:0] tb_s_axis_data_tuser  = {2'b00,1'b0,1'b0,12'd0,16'd0,TESTBENCH_SID,{XBAR_ADDR,4'd0,4'd0},64'd0};
    reg          tb_s_axis_data_tlast  = 1'b0;
    reg          tb_s_axis_data_tvalid = 1'b0;
    wire         tb_s_axis_data_tready;
    wire [`NUM_AXI_CONFIG_BUS*32-1:0] tb_m_axis_config_tdata;
    wire [31:0] tb_m_axis_config_tdata_array[0:`NUM_AXI_CONFIG_BUS-1];
    wire [`NUM_AXI_CONFIG_BUS-1:0] tb_m_axis_config_tlast;
    wire [`NUM_AXI_CONFIG_BUS-1:0] tb_m_axis_config_tvalid;
    wire [`NUM_AXI_CONFIG_BUS-1:0] tb_m_axis_config_tready;

    // Create an array of configuration busses
    genvar _k;
    generate
      for (_k = 0; _k < `NUM_AXI_CONFIG_BUS; _k = _k + 1) begin
        assign tb_m_axis_config_tdata_array[_k] = tb_m_axis_config_tdata[_k*32+31:_k*32];
      end
    endgenerate

    localparam AXI_WRAPPER_BASE    = 128;
    localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

    reg [15:0] tb_next_dst = 16'd0;

    axi_wrapper #(
      .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
      .NUM_AXI_CONFIG_BUS(`NUM_AXI_CONFIG_BUS),
      .CONFIG_BUS_FIFO_DEPTH(7),
      .SIMPLE_MODE(`SIMPLE_MODE))
    inst_axi_wrapper (
      .clk(ce_clk), .reset(ce_rst),
      .clear_tx_seqnum(tb_clear_tx_seqnum),
      .next_dst(tb_next_dst),
      .set_stb(tb_set_stb), .set_addr(tb_set_addr), .set_data(tb_set_data),
      .i_tdata(tb_str_sink_tdata), .i_tlast(tb_str_sink_tlast), .i_tvalid(tb_str_sink_tvalid), .i_tready(tb_str_sink_tready),
      .o_tdata(tb_str_src_tdata), .o_tlast(tb_str_src_tlast), .o_tvalid(tb_str_src_tvalid), .o_tready(tb_str_src_tready),
      .m_axis_data_tdata(tb_m_axis_data_tdata),
      .m_axis_data_tlast(tb_m_axis_data_tlast),
      .m_axis_data_tvalid(tb_m_axis_data_tvalid),
      .m_axis_data_tready(tb_m_axis_data_tready),
      .m_axis_data_tuser(tb_m_axis_data_tuser),
      .s_axis_data_tdata(tb_s_axis_data_tdata),
      .s_axis_data_tlast(tb_s_axis_data_tlast),
      .s_axis_data_tvalid(tb_s_axis_data_tvalid),
      .s_axis_data_tready(tb_s_axis_data_tready),
      .s_axis_data_tuser(tb_s_axis_data_tuser),
      .m_axis_config_tdata(tb_m_axis_config_tdata),
      .m_axis_config_tlast(tb_m_axis_config_tlast),
      .m_axis_config_tvalid(tb_m_axis_config_tvalid), 
      .m_axis_config_tready(tb_m_axis_config_tready));
  `endif


  /*********************************************
  ** Useful Tasks
  *********************************************/
  reg [11:0] ctrl_pkt_seqnum = 12'd0;
  task SendCtrlPacket;
    input [15:0] dst;
    input [63:0] data;
  begin
    tb_cmdout_tdata = { 4'h8, ctrl_pkt_seqnum, 16'h16, {TESTBENCH_SID,dst}};
    tb_cmdout_tlast = 1'b0;
    tb_cmdout_tvalid = 1'b1;
    @(posedge ce_clk);
    while(~tb_cmdout_tready) @(posedge ce_clk);
    
    tb_cmdout_tdata = data;
    tb_cmdout_tlast = 1'b1;
    @(posedge ce_clk);
    while(~tb_cmdout_tready) @(posedge ce_clk);
    
    tb_cmdout_tdata = 1'b0;
    tb_cmdout_tvalid = 1'b0;
    tb_cmdout_tlast = 1'b0;
  end
  endtask

  `ifndef RFNOC_SIM_LIB_INC_AXI_WRAPPER
    task automatic SendDummyDataPacket;
      input [1:0]  flags;
      input [11:0] seqnum;
      input [12:0] len;
      input [15:0] dst;
      input [63:0] data;
      integer i = 0;
    begin
      @(posedge ce_clk);
      tb_str_src_tdata = { CHDR_DATA_PKT_TYPE, flags, seqnum, (len << 3) + 16'h8, {TESTBENCH_SID,dst}};
      tb_str_src_tlast = 1'b0;
      tb_str_src_tvalid = 1'b1;
      @(posedge ce_clk);
      while(~tb_str_src_tready) @(posedge ce_clk);
      while (i < len) begin
        tb_str_src_tdata = data + i;
        i = i + 1;
        if (i == len) tb_str_src_tlast = 1'b1;
        @(posedge ce_clk);
        while(~tb_str_src_tready) @(posedge ce_clk);
      end
      tb_str_src_tdata = 1'b0;
      tb_str_src_tlast = 1'b0;
      tb_str_src_tvalid = 1'b0;
    end
    endtask

    task SendChdr;
      input [1:0] pkt_type;
      input [1:0] flags;
      input [11:0] seqnum;
      input [12:0] len;
      input [15:0] dst;
      input [63:0] vita_time;
    begin
      if (flags & CHDR_HAS_TIME) begin
        tb_str_src_tdata = { pkt_type, flags, seqnum, (len << 3) + 16'h16, {TESTBENCH_SID,dst}};
      end else begin
        tb_str_src_tdata = { pkt_type, flags, seqnum, (len << 3) + 16'h8, {TESTBENCH_SID,dst}};
      end
      tb_str_src_tlast = 1'b0;
      tb_str_src_tvalid = 1'b1;
      @(posedge ce_clk);
      while(~tb_str_src_tready) @(posedge ce_clk);
      if (flags & CHDR_HAS_TIME) begin
        tb_str_src_tdata = vita_time;
        @(posedge ce_clk);
        while(~tb_str_src_tready) @(posedge ce_clk);
      end
    end
    endtask

    task SendPayload;
      input [63:0] data;
      input last;
    begin
      tb_str_src_tdata = data;
      tb_str_src_tlast = last;
      @(posedge ce_clk);
      while(~tb_str_src_tready) @(posedge ce_clk);
      tb_str_src_tvalid = 1'b0;
      tb_str_src_tlast = 1'b0;
    end
    endtask
  `else
    task SendAxi;
      input [31:0] data;
      input last;
    begin
      tb_s_axis_data_tvalid = 1'b1;
      tb_s_axis_data_tdata = data;
      tb_s_axis_data_tlast = last;
      @(posedge ce_clk);
      while(~tb_s_axis_data_tready) @(posedge ce_clk);
      tb_s_axis_data_tvalid = 1'b0;
      tb_s_axis_data_tlast = 1'b0;
    end
    endtask

    task RecvAxi;
      output [31:0] data;
      output last;
    begin
      tb_m_axis_data_tready = 1'b1;
      @(posedge ce_clk);
      while(~(tb_m_axis_data_tready & tb_m_axis_data_tvalid)) @(posedge ce_clk);
      tb_m_axis_data_tready = 1'b0;
      data = tb_m_axis_data_tdata;
      last = tb_m_axis_data_tlast;
    end
    endtask
  `endif