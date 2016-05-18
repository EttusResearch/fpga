//
// Copyright 2016 Ettus Research
//

module noc_block_siggen #(
   parameter NOC_ID = 64'h5166_3110_0000_0000,   
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
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [15:0] src_sid;
  wire [15:0] next_dst_sid, resp_out_dst_sid;
  wire [15:0] resp_in_dst_sid;

  wire        clear_tx_seqnum;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Stream IDs set by host 
    .src_sid(src_sid),                   // SID of this block
    .next_dst_sid(next_dst_sid),         // Next destination SID
    .resp_in_dst_sid(resp_in_dst_sid),   // Response destination SID for input stream responses / errors
    .resp_out_dst_sid(resp_out_dst_sid), // Response destination SID for output stream responses / errors
    // Misc
    .vita_time('d0), .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug)
  );


  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////

  localparam NUM_AXI_CONFIG_BUS = 1;
  
  wire [31:0] s_axis_data_tdata;
  wire [127:0] s_axis_data_tuser;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;
  wire [31:0] s_axis_const_tdata;
  wire [127:0] s_axis_const_tuser;
  wire        s_axis_const_tlast;
  wire        s_axis_const_tvalid;
  wire        s_axis_const_tready;
  wire [31:0] s_axis_sine_tdata;
  wire [127:0] s_axis_sine_tuser;
  wire        s_axis_sine_tlast;
  wire        s_axis_sine_tvalid;
  wire        s_axis_sine_tready;
  wire [31:0] packet_resizer_tdata;
  wire        packet_resizer_tlast;
  wire        packet_resizer_tvalid;
  wire        packet_resizer_tready;
  wire [127:0] packet_resizer_tuser;
  wire [127:0] modified_header;
  wire [2:0] wave_type;
  wire 	      enable;


  axi_wrapper #(
    .SIMPLE_MODE(0))
  axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(),
    .m_axis_data_tlast(),
    .m_axis_data_tvalid(),
    .m_axis_data_tready(),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(packet_resizer_tdata),
    .s_axis_data_tlast(packet_resizer_tlast),
    .s_axis_data_tvalid(packet_resizer_tvalid),
    .s_axis_data_tready(packet_resizer_tready),
    .s_axis_data_tuser(packet_resizer_tuser),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());


  ////////////////////////////////////////////////////////////
  //
  // Signal Generator Block
  //
  ////////////////////////////////////////////////////////////
      
  localparam SR_PKT_SIZE = 140;
  
  cvita_hdr_encoder cvita_hdr_encoder (
    .pkt_type(2'b0), .eob(0), .has_time(0),
    .seqnum(12'b0), .length(16'b0), .dst_sid(next_dst_sid),.src_sid(src_sid),
    .vita_time(64'b0),
    .header(modified_header));

  packet_resizer #(
   .SR_PKT_SIZE(SR_PKT_SIZE))
  inst_packet_resizer (
    .clk(ce_clk), .reset(ce_rst),
    .next_dst_sid(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(s_axis_data_tdata),
    .i_tuser(modified_header),
    .i_tlast(s_axis_data_tlast),
    .i_tvalid(s_axis_data_tvalid),
    .i_tready(s_axis_data_tready),
    .o_tdata(packet_resizer_tdata),
    .o_tuser(packet_resizer_tuser),
    .o_tlast(packet_resizer_tlast),
    .o_tvalid(packet_resizer_tvalid),
    .o_tready(packet_resizer_tready));


  ////////////////////////////////////////////////////////////
  //
  // Signal Generator Block
  //
  ////////////////////////////////////////////////////////////
  // NoC Shell registers 0 - 127,
  // User register address space starts at 128

  localparam SR_FREQ = 128;
  localparam SR_CARTESIAN = 130;
  localparam SR_ENABLE = 132;
  localparam SR_AMPLITUDE = 138;
  localparam SR_WAVEFORM = 142;

 // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  //settings bus for selecting wave type 
  setting_reg #(
    .my_addr(SR_WAVEFORM), .awidth(8), .width(3)) 
  set_wave (
    .clk(ce_clk), .rst(ce_reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(wave_type), .changed());
  
  //Start/stop functionality
  //settings bus for start/stop
  setting_reg #(
    .my_addr(SR_ENABLE), .awidth(8), .width(1)) 
  set_enable (
    .clk(ce_clk), .rst(ce_reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(enable), .changed());
  
  assign s_axis_data_tdata  = (wave_type == 3'b001) ? s_axis_sine_tdata : s_axis_const_tdata ;
  assign s_axis_data_tvalid = ((wave_type == 3'b001) ? s_axis_sine_tvalid : s_axis_const_tvalid) & enable;
  assign s_axis_data_tlast  = (wave_type == 3'b001) ? s_axis_sine_tlast : s_axis_const_tlast;
  
  assign s_axis_sine_tready = (wave_type == 3'b001) ? s_axis_data_tready : 1'b0;
  assign s_axis_const_tready = (wave_type == 3'b000) ? s_axis_data_tready : 1'b0;

  ////////////////////////////////////////////////////////////
  //
  // Sine_tone Block
  //
  ////////////////////////////////////////////////////////////
  
  //Sine tone block instance
  sine_tone #(.WIDTH(32), .SR_FREQ_ADDR(SR_FREQ), .SR_CARTESIAN_ADDR(SR_CARTESIAN)) sine_tone_inst
      (.clk(ce_clk), .reset(ce_rst), .clear(0), .enable(enable),
       .set_stb(set_stb), .set_data(set_data), .set_addr(set_addr), 
       .o_tdata(s_axis_sine_tdata), .o_tlast(s_axis_sine_tlast), .o_tvalid(s_axis_sine_tvalid), .o_tready(s_axis_sine_tready));	

  ////////////////////////////////////////////////////////////
  //
  // Constant Block
  //
  ////////////////////////////////////////////////////////////

  // AXI settings bus for CONSTANT values
  axi_setting_reg #(
    .ADDR(SR_AMPLITUDE), .AWIDTH(8), .WIDTH(32), .USE_LAST(1), .REPEATS(1) ) 
  const_block (
    .clk(ce_clk), .reset(ce_reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(s_axis_const_tdata), .o_tlast(s_axis_const_tlast), .o_tvalid(s_axis_const_tvalid), .o_tready(s_axis_const_tready));


endmodule
