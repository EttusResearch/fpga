//
// Copyright 2014 Ettus Research LLC
//

module noc_block_radio_core
  #(parameter NOC_ID = 64'h1112_0000_0000_0000,
    parameter STR_SINK_FIFOSIZE = 11,
    parameter RADIO_NUM = 0,
    parameter USE_TX_CORR = 0,
    parameter USE_RX_CORR = 0)
   (input bus_clk, input bus_rst,
    input ce_clk, input ce_rst,
    input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
    // Ports connected to hardware
    input [31:0] rx,
    output [31:0] tx,
    inout [31:0] db_gpio,
    inout [31:0] fp_gpio,
    output [7:0] sen, output sclk, output mosi, input miso,
    output [7:0] misc_outs, output [2:0] leds,
    input pps,
    output sync_dacs,
    output [63:0] debug
    );

   /////////////////////////////////////////////////////////////
   //
   // RFNoC Shell
   //
   ////////////////////////////////////////////////////////////
   wire [31:0] 	  set_data;
   wire [7:0] 	  set_addr;
   wire 	  set_stb;
   wire [63:0] 	  rb_data;
   
   wire [63:0] 	  cmdout_tdata, ackin_tdata;
   wire 	  cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;
   
   wire [63:0] 	  str_sink_tdata, str_src_tdata;
   wire 	  str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;
   
   wire 	  clear_tx_seqnum;
   
   noc_shell #(.NOC_ID(NOC_ID), .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) inst_noc_shell 
     (.bus_clk(bus_clk), .bus_rst(bus_rst),
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
   
   // ////////////////////////////////////////////////////////
   //
   // AXI Wrapper
   // Convert RFNoC Shell interface into AXI stream interface
   //
   ////////////////////////////////////////////////////////////
   localparam NUM_AXI_CONFIG_BUS = 1; // Not used
   
   wire [31:0] 	  m_axis_data_tdata;
   wire [127:0]   m_axis_data_tuser;
   wire 	  m_axis_data_tlast;
   wire 	  m_axis_data_tvalid;
   wire 	  m_axis_data_tready;
   
   wire [31:0] 	  s_axis_data_tdata;
   wire [127:0]   s_axis_data_tuser;
   wire 	  s_axis_data_tlast;
   wire 	  s_axis_data_tvalid;
   wire 	  s_axis_data_tready;
   
   wire [31:0] 	  m_axis_config_tdata;
   wire 	  m_axis_config_tvalid;
   wire 	  m_axis_config_tready;
   
   localparam AXI_WRAPPER_BASE    = 128;
   localparam SR_NEXT_DST         = AXI_WRAPPER_BASE;
   localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;
   
   axi_wrapper #(.SR_NEXT_DST(SR_NEXT_DST),
		 .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
		 .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS),
		 .SIMPLE_MODE(0)) inst_axi_wrapper 
     (.clk(ce_clk), .reset(ce_rst),
      .clear_tx_seqnum(clear_tx_seqnum),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
      .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
      .m_axis_data_tdata(m_axis_data_tdata),
      .m_axis_data_tuser(m_axis_data_tuser),
      .m_axis_data_tlast(m_axis_data_tlast),
      .m_axis_data_tvalid(m_axis_data_tvalid),
      .m_axis_data_tready(m_axis_data_tready),
      .s_axis_data_tdata(s_axis_data_tdata),
      .s_axis_data_tuser(s_axis_data_tuser),
      .s_axis_data_tlast(s_axis_data_tlast),
      .s_axis_data_tvalid(s_axis_data_tvalid),
      .s_axis_data_tready(s_axis_data_tready),
      .m_axis_config_tdata(m_axis_config_tdata),
      .m_axis_config_tlast(),
      .m_axis_config_tvalid(m_axis_config_tvalid), 
      .m_axis_config_tready(m_axis_config_tready));
   
   ////////////////////////////////////////////////////////////
   //
   // User code
   //
   ////////////////////////////////////////////////////////////
   
   // Control Source connected to radio tx responder
   assign ackin_tready  = 1'b1;
   
   localparam [7:0] SR_VECTOR_LEN = 129;
   localparam [7:0] SR_ALPHA      = 130;
   localparam [7:0] SR_BETA       = 131;
   localparam MAX_LOG2_OF_SIZE    = 11;

   radio_core #(.BASE(128), .RADIO_NUM(0), .USE_TX_CORR(USE_TX_CORR), .USE_RX_CORR(USE_RX_CORR)) radio_core
     (.clk(ce_clk), .reset(ce_rst),
      .rx(rx), .tx(tx),
      .db_gpio(db_gpio), .fp_gpio(fp_gpio),
      .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
      .misc_outs(misc_outs), .leds(leds),
      .pps(pps), .sync_dacs(sync_dacs),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .rb_data(rb_data),
      .vita_time(),
      .tx_tdata(m_axis_data_tdata), .tx_tlast(m_axis_data_tlast), 
      .tx_tvalid(m_axis_data_tvalid), .tx_tready(m_axis_data_tready), .tx_tuser(m_axis_data_tuser),
      .rx_tdata(s_axis_data_tdata), .rx_tlast(s_axis_data_tlast), 
      .rx_tvalid(s_axis_data_tvalid), .rx_tready(s_axis_data_tready), .rx_tuser(s_axis_data_tuser),
      .txresp_tdata(cmdout_tdata), .txresp_tlast(cmdout_tlast), .txresp_tvalid(cmdout_tvalid), .txresp_tready(cmdout_tready));
            
endmodule // noc_block_radio_core