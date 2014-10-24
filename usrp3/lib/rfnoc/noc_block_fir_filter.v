module noc_block_fir_filter #(
  parameter NOC_ID = 64'hF112_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  localparam SR_READBACK = 255;
  
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .rb_data(rb_data),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 2;
  
  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;
  
  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;

  
  wire [NUM_AXI_CONFIG_BUS*32-1:0] m_axis_config_tdata;
  wire [31:0] m_axis_config_tdata_array[0:NUM_AXI_CONFIG_BUS-1];
  wire [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tlast;
  wire [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tvalid;
  wire [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tready;
  
  // Create an array of configuration busses
  genvar k;
  generate
    for (k = 0; k < NUM_AXI_CONFIG_BUS; k = k + 1) begin
        assign m_axis_config_tdata_array[k] = m_axis_config_tdata[k*32+31:k*32];
    end
  endgenerate
  
  localparam AXI_WRAPPER_BASE = 128;

  axi_wrapper #(
    .BASE(AXI_WRAPPER_BASE),
    .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS),
    .CONFIG_BUS_FIFO_DEPTH(6)) // Need deeper FIFO to prevent overflow when configuring coefficients
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .m_axis_config_tdata(m_axis_config_tdata),
    .m_axis_config_tlast(m_axis_config_tlast),
    .m_axis_config_tvalid(m_axis_config_tvalid), 
    .m_axis_config_tready(m_axis_config_tready));
  
  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////
  
  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;
  
  localparam NUM_TAPS = 41;
  localparam RB_ADDR_WIDTH = 3;
  
  wire [RB_ADDR_WIDTH-1:0] rb_addr;
  setting_reg #(
    .my_addr(SR_READBACK), .awidth(8), .width(RB_ADDR_WIDTH)) 
  sr_rdback (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(rb_addr), .changed());
  
  // Readback register for number of FIR filter taps
  always @*
    case(rb_addr)
      3'd0    : rb_data <= {NUM_TAPS};
      default : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase
  
  // AXI configuration bus 0
  wire [31:0] m_axis_fir_reload_tdata  = m_axis_config_tdata_array[0];
  wire        m_axis_fir_reload_tvalid = m_axis_config_tvalid[0];
  wire        m_axis_fir_reload_tready;
  assign      m_axis_config_tready[0]  = m_axis_fir_reload_tready;
  wire        m_axis_fir_reload_tlast  = m_axis_config_tlast[0];

  // AXI configuration bus 1
  wire [7:0]  m_axis_fir_config_tdata  = m_axis_config_tdata_array[1][7:0];
  wire        m_axis_fir_config_tvalid = m_axis_config_tvalid[1];
  wire        m_axis_fir_config_tready;
  assign      m_axis_config_tready[1]  = m_axis_fir_config_tready;

  simple_fir inst_simple_fir (
    .aresetn(~ce_rst), .aclk(ce_clk),
    .s_axis_data_tdata(m_axis_data_tdata),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tdata(s_axis_data_tdata),
    .m_axis_data_tlast(s_axis_data_tlast),
    .m_axis_data_tvalid(s_axis_data_tvalid),
    .m_axis_data_tready(s_axis_data_tready),
    .s_axis_config_tdata(m_axis_fir_config_tdata),
    .s_axis_config_tvalid(m_axis_fir_config_tvalid),
    .s_axis_config_tready(m_axis_fir_config_tready),
    .s_axis_reload_tdata(m_axis_fir_reload_tdata),
    .s_axis_reload_tvalid(m_axis_fir_reload_tvalid),
    .s_axis_reload_tready(m_axis_fir_reload_tready),
    .s_axis_reload_tlast(m_axis_fir_reload_tlast));

endmodule