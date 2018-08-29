/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Noc Block: EISCAT FIR
//
// Input:  Standard Noc Block AXI NoC interface
//         16 Channel Radio RX from ADC
//         Aurora input lane
//
// Output: Standard Noc Block AXI NoC interface
//         Aurora output lane
//
// Top level of Eiscat DSP functionality.
// Calculates beamforming operations on input Radio RX streams generating 10 output beams.
// 5 of those beams are swapped with a neighbor across the Aurora I/O lane.
// Previous 5 contribution Beams are received from Noc Block AXI NoC input.
// 5 sets of 3 beam sources (This device, neighbor, and previous) are summed
// and output to Noc Block AXI NoC output of this module.
// All Configuration in this module is done using standard Noc Block
// functionality through the Noc Shell.
//
// DDC is a seperate Noc Block.


module noc_block_radio_core_eiscat #(
  parameter NOC_ID = 64'hE15C_A700_0000_0000,
  parameter INPUT_PORTS = 5,
  parameter OUTPUT_PORTS = 5,
  parameter [INPUT_PORTS*8-1:0] STR_SINK_FIFOSIZE = {INPUT_PORTS{8'd11}},
  parameter [OUTPUT_PORTS*8-1:0] MTU = {OUTPUT_PORTS{8'd11}},
  parameter COMPAT_NUM_MAJOR  = 32'h1,
  parameter COMPAT_NUM_MINOR  = 32'h0, 
  parameter NUM_CHANNELS=16,
  parameter NUM_BEAMS=10,
  parameter ENABLE_BEAMFORM=1,
  parameter AURORA_DEBUG=0)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug,
  //radio rx channels
  input  [NUM_CHANNELS*16-1:0] rx, input [NUM_CHANNELS-1:0] rx_stb,
  //triggers on next clock cycle after aurora channel is available.
  output sysref_pulse,
  input pps,
  input sync_in,
  output sync_out,
  output rst_npio,
  //i/o to NPIO MGT cores
  input [63:0]  i_npio_tdata,
  input         i_npio_tvalid,
  input         i_npio_tlast,
  output        i_npio_tready,

  output [63:0] o_npio_tdata,
  output        o_npio_tvalid,
  output        o_npio_tlast,
  input         o_npio_tready


);

  //NUM RFNOC PORTS
  localparam NUM_BEAMS_DIV2 = NUM_BEAMS/2;

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [NUM_BEAMS_DIV2*32-1:0]      set_data;
  wire [NUM_BEAMS_DIV2*8-1:0]       set_addr;
  wire [NUM_BEAMS_DIV2-1:0]         set_stb;
  wire [NUM_BEAMS_DIV2*64-1:0]      set_time;
  wire [8*NUM_BEAMS_DIV2-1:0]       rb_addr;
  reg  [64*NUM_BEAMS_DIV2-1:0]      rb_data;
  wire [NUM_BEAMS_DIV2-1:0]         rb_stb;

  wire [63:0]                     cmdout_tdata, ackin_tdata;
  wire                            cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0]                      str_sink_tdata[0:NUM_BEAMS_DIV2-1];
  wire [63:0]                      str_src_tdata[0:NUM_BEAMS_DIV2-1];

  wire [NUM_BEAMS_DIV2-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [NUM_BEAMS_DIV2-1:0]         clear_tx_seqnum;
  wire [16*NUM_BEAMS_DIV2-1:0]      src_sid, next_dst_sid, resp_in_dst_sid, resp_out_dst_sid;
  wire [63:0]                       vita_time;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_BEAMS_DIV2),
    .OUTPUT_PORTS(NUM_BEAMS_DIV2),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE),
    .MTU(MTU),
    .USE_GATE_MASK(5'h1F), //need this for custom mtu/ size
    .RESP_FIFO_SIZE(5))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time),
    .rb_stb(rb_stb), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata({str_sink_tdata[4], str_sink_tdata[3], str_sink_tdata[2], str_sink_tdata[1], str_sink_tdata[0]}),
    .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata({str_src_tdata[4], str_src_tdata[3], str_src_tdata[2], str_src_tdata[1], str_src_tdata[0]}),
    .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    //other things
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(resp_in_dst_sid), .resp_out_dst_sid(resp_out_dst_sid),
    .vita_time(vita_time), .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  // Data received from this interface is 5 streams from the previous chassis.
  // Final output of combining (summing) all signal sources is sent out this interface.
  //
  ////////////////////////////////////////////////////////////
  // will eventually need 5 channels of axi wrappers I think.
  //

  wire [31:0]                  m_axis_data_tdata[0:NUM_BEAMS_DIV2-1];
  //wire [127:0]                m_axis_data_tuser[0:NUM_BEAMS_DIV2-1];
  wire [(NUM_BEAMS_DIV2)*128-1:0]  m_axis_data_tuser;
  reg [(NUM_BEAMS_DIV2)*128-1:0]  m_axis_data_tuser_reg;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data_tready;
  wire [15:0]                   m_axis_data16_tdata[0:NUM_BEAMS_DIV2-1];
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_tready;
  wire [15:0]                   m_axis_data16_fifo_tdata[0:NUM_BEAMS_DIV2-1];
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     m_axis_data16_fifo_tready;

  wire [31:0]                   s_axis_data_tdata[0:NUM_BEAMS_DIV2-1];
  wire [128*NUM_BEAMS_DIV2-1:0] s_axis_data_tuser;
  wire [128*NUM_BEAMS_DIV2-1:0] s_axis_data_tuser_corrected_seqnum;
  //wire [(NUM_BEAMS_DIV2)*128-1:0]  s_axis_data_tuser;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_tready;
  wire [31:0]                   s_axis_data_fifo_tdata[0:NUM_BEAMS_DIV2-1];
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data_fifo_tready;
  wire [16*NUM_BEAMS_DIV2-1:0]  s_axis_data16_sum_tdata;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_sum_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_sum_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_sum_tready;
  wire [16*NUM_BEAMS_DIV2-1:0]  s_axis_data16_tdata;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_tready;
  wire [16*NUM_BEAMS_DIV2-1:0]  s_axis_data16_streams_tdata; //streams direct from rx_eiscat_control for testing
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_streams_tlast;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_streams_tvalid;
  wire [NUM_BEAMS_DIV2-1:0]     s_axis_data16_streams_tready;
//  wire [NUM_BEAMS_DIV2*64-1:0]  resp_tdata;
//  wire [NUM_BEAMS_DIV2-1:0]     resp_tlast, resp_tvalid, resp_tready;
  wire [3:0] choose_beams; //now effects some code up here so moving this wire declaration here though it's settings reg is below.


  // _tuser bit definitions
  //  [127:64] == CHDR header
  //    [127:126] == Packet type -- 00 for data, 01 for flow control, 10 for command, 11 for response
  //    [125]     == Has time? (0 for no, 1 for time field on next line)
  //    [124]     == EOB (end of burst indicator)
  //    [123:112] == 12-bit sequence number
  //    [111: 96] == 16-bit length in bytes
  //    [ 95: 80] == SRC SID (stream ID)
  //    [ 79: 64] == DST SID
  //  [ 63: 0] == timestamp

  genvar i;
  generate
    for (i = 0; i < NUM_BEAMS_DIV2; i = i + 1) begin : gen
      ////////////////////////////////////////////////////////////
      //
      // AXI Wrapper
      // Convert RFNoC Shell interface into AXI stream interface
      // One per radio interface
      //
      ////////////////////////////////////////////////////////////
      axi_wrapper #(
        .MTU(MTU[8*i+7:8*i]),
        .SIMPLE_MODE(0),
        .USE_SEQ_NUM(0))
      axi_wrapper (
        .bus_clk(bus_clk), .bus_rst(bus_rst),
        .clk(ce_clk), .reset(ce_rst),
        .clear_tx_seqnum(clear_tx_seqnum[i]),
        .next_dst(next_dst_sid[16*i+15:16*i]),
        .set_stb(1'b0), .set_addr(8'd0), .set_data(32'd0),
        .i_tdata(str_sink_tdata[i]), .i_tlast(str_sink_tlast[i]), .i_tvalid(str_sink_tvalid[i]), .i_tready(str_sink_tready[i]),
        .o_tdata(str_src_tdata[i]), .o_tlast(str_src_tlast[i]), .o_tvalid(str_src_tvalid[i]), .o_tready(str_src_tready[i]),
        .m_axis_data_tdata(m_axis_data_tdata[i]),
        .m_axis_data_tuser(m_axis_data_tuser[128*i+127:128*i]),
        .m_axis_data_tlast(m_axis_data_tlast[i]),
        .m_axis_data_tvalid(m_axis_data_tvalid[i]),
        .m_axis_data_tready(m_axis_data_tready[i]),
        .s_axis_data_tdata(s_axis_data_tdata[i]),
        //.s_axis_data_tuser(s_axis_data_tuser_corrected_seqnum[128*i+127:128*i]),
        .s_axis_data_tuser(s_axis_data_tuser[128*i+127:128*i]),
        .s_axis_data_tlast(s_axis_data_tlast[i]),
        .s_axis_data_tvalid(s_axis_data_tvalid[i]),
        .s_axis_data_tready(s_axis_data_tready[i]),
        .m_axis_pkt_len_tdata(),
        .m_axis_pkt_len_tvalid(),
        .m_axis_pkt_len_tready(),
        .m_axis_config_tdata(),
        .m_axis_config_tlast(),
        .m_axis_config_tvalid(),
        .m_axis_config_tready(1'b0));

        /////
        //convert m_axis_data 32 bits to 16 bits
        axi_fifo32_to_fifo16 axi_fifo32_to_fifo16_inst(
          .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
          .i_tdata(m_axis_data_tdata[i]),
          .i_tuser(3'b00), //need to figure out what to do with this
          .i_tlast(m_axis_data_tlast[i]),
          .i_tvalid(m_axis_data_tvalid[i]),
          .i_tready(m_axis_data_tready[i]),
          .o_tdata(m_axis_data16_tdata[i]),
          .o_tuser(),
          .o_tlast(m_axis_data16_tlast[i]),
          .o_tvalid(m_axis_data16_tvalid[i]),
          .o_tready(m_axis_data16_tready[i])
        );

        //output of this axi_fifo is final output of this module.
        axi_fifo #(.WIDTH(17), .SIZE(1)) fifo16bit_m_axis_axi_wrapper (
          .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
          .i_tdata({m_axis_data16_tlast[i],m_axis_data16_tdata[i]}),
          .i_tvalid(m_axis_data16_tvalid[i]),
          .i_tready(m_axis_data16_tready[i]),
          .o_tdata({m_axis_data16_fifo_tlast[i],m_axis_data16_fifo_tdata[i]}),
          .o_tvalid(m_axis_data16_fifo_tvalid[i]),
          .o_tready(m_axis_data16_fifo_tready[i]),
          .occupied(), .space());

        /////
        /////
        //Convert final beamform summation to 32 bits for AXI WRAPPER S AXIS
        axi_fifo16_to_fifo32 axi_fifo16_to_fifo32_inst(
         .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
         .i_tdata(s_axis_data16_tdata[i*16+15:i*16]),
         .i_tuser(2'b00), //need to figure out what to do with this
         .i_tlast(s_axis_data16_tlast[i]),
         .i_tvalid(s_axis_data16_tvalid[i]),
         .i_tready(s_axis_data16_tready[i]),
         .o_tdata(s_axis_data_fifo_tdata[i]),
         .o_tuser(),
         .o_tlast(s_axis_data_fifo_tlast[i]),
         .o_tvalid(s_axis_data_fifo_tvalid[i]),
         .o_tready(s_axis_data_fifo_tready[i])
         );

        axi_fifo #(.WIDTH(33), .SIZE(1)) fifo32bit_before_axi_wrapper (
          .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
          .i_tdata({s_axis_data_fifo_tlast[i],s_axis_data_fifo_tdata[i]}),
          .i_tvalid(s_axis_data_fifo_tvalid[i]),
          .i_tready(s_axis_data_fifo_tready[i]),
          .o_tdata({s_axis_data_tlast[i],s_axis_data_tdata[i]}),
          .o_tvalid(s_axis_data_tvalid[i]),
          .o_tready(s_axis_data_tready[i]),
//          .o_tready(1'b1),
          .occupied(), .space());
        /////
    end
  endgenerate

  ////////////////////////////////////////////////////////////
  //
  // START USER CODE
  // Broken down into sections.
  // 0.   localparams, readback regs, and wires (this section)
  // 1.   Beamforming delay and sum
  // 2.   Timekeeper & RX Control
  // 3.   Mux beams to either stay local or goto neighbor
  // 4.   Aurora interface (including demux to determine which beams are sent to the neighbor)
  // 5.   Get data from previous chassis or null source
  // 6.   Sum everything
  //
  ////////////////////////////////////////////////////////////


  //params. submodules. register addresses, register values.
  localparam NUM_TAPS = 10;
  localparam NUM_FILTERS = NUM_CHANNELS*NUM_BEAMS;
  `include "radio_core_regs.vh"


  //timekeeper SR (in radio_core_regs.vh)
  //RX control (in radio_core_regs.vh)

  //beamforming FIR reload
  localparam [7:0] SR_RX_STREAM_ENABLE = 159; //grouped with the other rx_control regs and it's available!
  localparam [7:0] SR_FIR_COMMANDS_RELOAD = 198;
  localparam [7:0] SR_FIR_COMMANDS_CTRL_TIME_HI = 199;
  localparam [7:0] SR_FIR_COMMANDS_CTRL_TIME_LO = 200;
  localparam [7:0] SR_FIR_BRAM_WRITE_TAPS = 201;
  //set the mux for whether this device sends the upper or lower 5 beam contributions to their neighbor.
  localparam [7:0] SR_BEAMS_TO_NEIGHBOR = 202;
  //mux for whether this device adds 0's or the previous beam row into this device's beam contribution
  localparam [7:0] SR_PREV_OR_NULL = 203;
  localparam [7:0] SR_CHANNEL_GAIN_BASE = 204; //204-219 for all 16 gain regs
  localparam [7:0] SR_AURORA_BIST = 220;
  localparam [7:0] SR_SYSREF = 221;//trigger sysref pulse here
  localparam [7:0] SR_FIR_COMMANDS_CTRL_CLEAR_CMDS = 223;

  localparam RB_NUM_TAPS = 6;
  localparam RB_NUM_CHANNELS = 7;
  localparam RB_NUM_BEAMS = 8;
  localparam RB_NUM_FILTERS = 9;
  localparam RB_STREAM_ENABLED = 10;
  localparam RB_CHOOSE_BEAMS = 11;
  localparam RB_AURORA_CORE_STATUS = 12;
  localparam RB_AURORA_OVERRUNS = 13;
  localparam RB_AURORA_BIST_SAMPS = 14;
  localparam RB_AURORA_BIST_ERRORS = 15;

 //WIRES GO HERE

  // Mux settings bus because we only have 1 settings bus not the 5
  wire                     set_stb_mux;
  wire [7:0]               set_addr_mux;
  wire [31:0]              set_data_mux;

  wire [31:0] test_readback;
  wire test_readback_changed;
  wire sysref;
  //wire sysref_pulse;

  //output from radio rx input of this module. Connects to FIR Filters
  wire [NUM_CHANNELS*16-1:0] radio_rx_tdata;
  wire [NUM_CHANNELS-1:0] radio_rx_tvalid;

  //output from beamforming calculation
  wire [NUM_BEAMS*16-1:0] contribute_beams_tdata;
  wire [NUM_BEAMS-1:0] contribute_beams_tvalid;

  //output from beamforming calculation
  wire [NUM_BEAMS*16-1:0] contribute_beams_mux_tdata;
  wire [NUM_BEAMS-1:0] contribute_beams_mux_tvalid;

  //settings error stb for beamforming settings regs
  wire [1:0] settings_error_stb;

  // VITA time
  wire [63:0] vita_time_lastpps;

  //output from rx_control_eiscat (data triggered with timed commands)
  //prepending "beams" to lessen some confusion with wire naming.
  wire [NUM_BEAMS*16-1:0] beams_rx_tdata;
  wire [NUM_BEAMS-1:0] beams_rx_tlast;
  wire [NUM_BEAMS-1:0] beams_rx_tvalid;
  wire [NUM_BEAMS-1:0] beams_rx_tready;
  wire [127:0] beams_rx_tuser;
  wire [NUM_BEAMS-1:0] rx_stream_enabled;
  wire run_rx;
  reg run_rx_reg;
  reg run_rx_reg_delay;
  wire run_rx_rising_edge;
  wire [2:0] rx_ibs_state_out;

  //ERROR output from rx_control_eiscat (data triggered with timed commands)
  wire [63:0] rx_resp_tdata;
  wire rx_resp_tlast;
  wire rx_resp_tvalid;
  wire rx_resp_tready;
  wire [127:0] rx_resp_tuser;
  wire rx_control_clear_out;
  reg rx_control_clear_reg_pb;
  reg rx_control_clear_reg_bth;
  reg rx_control_clear_reg_bfn;
  reg rx_control_clear_reg_tsce;
  reg rx_control_clear_tlast; //fake tlast to end whatever packet we're in the middle of during an overflow.
  reg rx_control_clear_ddc;
  reg rx_control_clear_aurora;
  reg [NUM_BEAMS_DIV2-1:0] rx_control_clear_eob;

  //contributions get routed either to neighbor or to internal summing contribution
  wire [NUM_BEAMS_DIV2*16-1:0] beams_to_neighbors_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_neighbors_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_neighbors_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_neighbors_tready;
  wire [NUM_BEAMS_DIV2*128-1:0] beams_to_neighbors_tuser; //useful for streaming testing direct rx
  reg [NUM_BEAMS_DIV2*128-1:0] beams_to_neighbors_tuser_reg; //useful for streaming testing direct rx


  //beams from neighbor (RX from AURORA to final summation)
  wire [NUM_BEAMS_DIV2*16-1:0] beams_from_neighbors_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_tready;
  wire [NUM_BEAMS_DIV2*128-1:0] beams_from_neighbors_tuser;
  wire [NUM_BEAMS_DIV2*16-1:0] beams_from_neighbors_fifo_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] beams_from_neighbors_sync_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_sync_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_sync_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_sync_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] beams_from_neighbors_fifo_flop_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_flop_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_flop_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_from_neighbors_fifo_flop_tready;
  wire [15:0] bfn_data_occupied[0:NUM_BEAMS_DIV2-1];
  wire [15:0] bfn_data_space[0:NUM_BEAMS_DIV2-1];
  //beams to here (RX from self to final summation)
  wire [NUM_BEAMS_DIV2*16-1:0] beams_to_here_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_tready;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_del_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_del_tready;
  reg  [NUM_BEAMS_DIV2*3-1:0] beam_to_here_tvalid_shift_reg;
  reg  [NUM_BEAMS_DIV2*3-1:0] beam_to_here_tready_shift_reg;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_test_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] beams_to_here_fifo_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_tready;  
  wire [NUM_BEAMS_DIV2*16-1:0] beams_to_here_sync_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_sync_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_sync_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_sync_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] beams_to_here_fifo_flop_tdata;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_flop_tlast;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_flop_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] beams_to_here_fifo_flop_tready;
  wire [15:0] bth_data_occupied[0:NUM_BEAMS_DIV2-1];
  wire [15:0] bth_data_space[0:NUM_BEAMS_DIV2-1];
  //previous beams (RX from noc shell/axi wrapper to final summation)
  wire choose_prev;
  wire [NUM_BEAMS_DIV2*16-1:0] previous_beam_tdata;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_tlast;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_tready;
  wire [NUM_BEAMS_DIV2*128-1:0] previous_beam_tuser;
  wire [NUM_BEAMS_DIV2*16-1:0] previous_beam_fifo_tdata;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] previous_beam_sync_tdata;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_sync_tlast;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_sync_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_sync_tready;
  wire [NUM_BEAMS_DIV2*16-1:0] previous_beam_fifo_flop_tdata;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_flop_tlast;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_flop_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] previous_beam_fifo_flop_tready;
  wire [15:0] pb_data_occupied[0:NUM_BEAMS_DIV2-1];
  wire [15:0] pb_data_space[0:NUM_BEAMS_DIV2-1];
  //handle tuser in final summation
  wire [128*NUM_BEAMS_DIV2-1:0] out_stream_tuser;
  wire [128*NUM_BEAMS_DIV2-1:0] out_stream_tuser_or_eob;
  wire [NUM_BEAMS_DIV2*64-1:0] time_stream_resp_tdata;
  wire [NUM_BEAMS_DIV2*128-1:0] time_stream_resp_tuser;
  wire [NUM_BEAMS_DIV2-1:0] time_stream_resp_tlast;
  wire [NUM_BEAMS_DIV2-1:0] time_stream_resp_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] time_stream_resp_tready;
  wire [NUM_BEAMS_DIV2-1:0] time_stream_error_out;
  //final summation output
  wire [NUM_BEAMS_DIV2-1:0] overflow;
  wire [NUM_BEAMS_DIV2*18-1:0] final_sum_tdata;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_tlast;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_tready;
  wire [NUM_BEAMS_DIV2*18-1:0] final_sum_fifo_tdata;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_fifo_tlast;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_fifo_tvalid;
  wire [NUM_BEAMS_DIV2-1:0] final_sum_fifo_tready;
  //if there's an error in final summation step, assert the collective error clear reg
  reg [NUM_BEAMS_DIV2-1:0] error_clear_reg;
  wire [NUM_BEAMS_DIV2-1:0] error_clear;
  reg [NUM_BEAMS_DIV2-1:0] bth_fifo_clear_reg;
  reg [NUM_BEAMS_DIV2-1:0] bfn_fifo_clear_reg;
  reg [NUM_BEAMS_DIV2-1:0] pb_fifo_clear_reg;
  reg [NUM_BEAMS_DIV2-1:0] time_stream_clear_reg;
  //debug
  wire [15:0] counter_tdata;
  wire [8:0] counter_out;
  wire  rx_counter_stb;


  wire [NUM_BEAMS_DIV2*64-1:0] rb_data_aurora;

  // Generate error response packets from TX & RX control
  axi_packet_mux #(.NUM_INPUTS(6), .MUX_POST_FIFO_SIZE(1), .FIFO_SIZE(5)) axi_packet_mux_cmd (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[0]),
    .i_tdata({rx_resp_tdata, time_stream_resp_tdata}), .i_tlast({rx_resp_tlast, time_stream_resp_tlast}),
    .i_tvalid({rx_resp_tvalid, time_stream_resp_tvalid}), .i_tready({rx_resp_tready, time_stream_resp_tready}), .i_tuser({rx_resp_tuser, time_stream_resp_tuser}),
    .o_tdata(cmdout_tdata), .o_tlast(cmdout_tlast), .o_tvalid(cmdout_tvalid), .o_tready(cmdout_tready));

  settings_bus_mux #(
    .AWIDTH(8),
    .DWIDTH(32),
    .NUM_BUSES(5))
  settings_bus_mux (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .in_set_stb(set_stb), .in_set_addr(set_addr), .in_set_data(set_data),
    .out_set_stb(set_stb_mux), .out_set_addr(set_addr_mux), .out_set_data(set_data_mux), .ready(1'b1));

  // Set this register to put a test value on the readback mux. Just like radio_core
  setting_reg #(.my_addr(SR_TEST), .width(32)) sr_test (
    .clk(ce_clk), .rst(ce_rst), .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux),
    .out(test_readback), .changed());

  // Set this register to put a test value on the readback mux. Just like radio_core
  setting_reg #(.my_addr(SR_SYSREF), .width(1)) sr_sysref (
    .clk(ce_clk), .rst(ce_rst), .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux),
    .out(sysref), .changed(sysref_pulse));

  // Readback register
  // repeat for each rfnoc port
  genvar rb;
  generate
  for (rb = 0; rb < NUM_BEAMS_DIV2; rb = rb + 1) begin : gen_rb
    assign rb_stb[rb] = 1'b1;
    always @(*) begin
      case(rb_addr[8*rb+7:8*rb])
        RB_VITA_TIME      : {rb_data[64*rb+63:64*rb]} <= {vita_time};
        RB_VITA_LASTPPS   : rb_data[64*rb+63:64*rb] <= vita_time_lastpps;
        RB_TEST           : rb_data[64*rb+63:64*rb] <= {32'h0, test_readback};
        RB_TXRX           : rb_data[64*rb+63:64*rb] <=  {64'h0};
        RB_RADIO_NUM      : rb_data[64*rb+63:64*rb] <= 64'd0;
        RB_COMPAT_NUM     : rb_data[64*rb+63:64*rb] <= {COMPAT_NUM_MAJOR, COMPAT_NUM_MINOR}; //just so the compat num check passes
        RB_NUM_TAPS       : rb_data[64*rb+63:64*rb] <= {NUM_TAPS};
        RB_NUM_CHANNELS   : rb_data[64*rb+63:64*rb] <= {NUM_CHANNELS};
        RB_NUM_BEAMS      : rb_data[64*rb+63:64*rb] <= {NUM_BEAMS};
        RB_NUM_FILTERS    : rb_data[64*rb+63:64*rb] <= {NUM_FILTERS};
        RB_STREAM_ENABLED : rb_data[64*rb+63:64*rb] <= {rx_stream_enabled};
        RB_CHOOSE_BEAMS   : rb_data[64*rb+63:64*rb] <= choose_beams;
        default           : rb_data[64*rb+63:64*rb] <= 64'hBADC0DE;
      endcase
    end
  end
  endgenerate
  

  //assign radio_rx_tdata from RX DB sources
  assign radio_rx_tdata = (choose_beams[3] == 1'b1) ? {16{counter_tdata}} : rx;
  assign radio_rx_tvalid = (choose_beams[3] == 1'b1) ? {16{rx_counter_stb}} : rx_stb;



  ////////////////////////////////////////////////////////////
  //
  // 1. Calculate this device's beam contributations. 5 output beams
  //
  ////////////////////////////////////////////////////////////

  wire [15:0] final_sum_probe;
  wire final_sum_valid_probe;
  wire final_sum_ready_probe;

  assign final_sum_probe = s_axis_data16_tdata;
  assign final_sum_valid_probe = s_axis_data16_tvalid;
  assign final_sum_ready_probe = s_axis_data16_tready;
  generate
  if( ENABLE_BEAMFORM==1) begin
  beamform_delay_and_sum
  #(.NUM_CHANNELS(NUM_CHANNELS),
    .NUM_BEAMS(NUM_BEAMS),
    .CHANNEL_WIDTH(14),
    .FILTER_OUT_WIDTH(16), 
    .JONATHONS_FIR(1),
    .SR_FIR_COMMANDS_RELOAD(SR_FIR_COMMANDS_RELOAD),
    .SR_FIR_BRAM_WRITE_TAPS(SR_FIR_BRAM_WRITE_TAPS),
    .SR_FIR_COMMANDS_CTRL_TIME_HI(SR_FIR_COMMANDS_CTRL_TIME_HI),
    .SR_FIR_COMMANDS_CTRL_TIME_LO(SR_FIR_COMMANDS_CTRL_TIME_LO),
    .SR_CHANNEL_GAIN_BASE(SR_CHANNEL_GAIN_BASE))
    inst_beamform_delay_and_sum (
    .clk(ce_clk), .rst(ce_rst),
    //input antenna sources
    .radio_rx_tdata(radio_rx_tdata),
    .radio_rx_tvalid(radio_rx_tvalid),
    //output beam contributions from these antennas
    .contribute_beams_tdata(contribute_beams_tdata),
    .contribute_beams_tvalid(contribute_beams_tvalid),
    //also include the settings reg inputs
    .error_stb(settings_error_stb),
    .set_stb(set_stb_mux), .set_addr(set_addr_mux), .set_data(set_data_mux),
    .vita_time(vita_time),
    .final_sum(final_sum_probe),
    .final_sum_valid(final_sum_valid_probe),
    .final_sum_ready(final_sum_ready_probe)
    );
  end
  endgenerate

  ////////////////////////////////////////////////////////////
  //
  // 2. TIME KEEPER AND RX CONTROL (INCLUDING TIME COMPARE FOR DATA)
  //
  ////////////////////////////////////////////////////////////

  //needs top reg and lower reg for time hi and time low. should match normal radio
  timekeeper #(
    .SR_TIME_HI(SR_TIME_HI),
    .SR_TIME_LO(SR_TIME_LO),
    .SR_TIME_CTRL(SR_TIME_CTRL))
  timekeeper (
    .clk(ce_clk), .reset(ce_rst), .pps(pps), .sync_in(sync_in), .strobe(1'b1),
    .set_stb(set_stb_mux), .set_addr(set_addr_mux), .set_data(set_data_mux),
    .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
    .sync_out(sync_out));

  /********************************************************
  ** RX Chain from radio core.
  ********************************************************/

  rx_control_eiscat #(
    .SR_RX_CTRL_COMMAND(SR_RX_CTRL_COMMAND),
    .SR_RX_CTRL_TIME_HI(SR_RX_CTRL_TIME_HI),
    .SR_RX_CTRL_TIME_LO(SR_RX_CTRL_TIME_LO),
    .SR_RX_CTRL_HALT(SR_RX_CTRL_HALT),
    .SR_RX_CTRL_MAXLEN(SR_RX_CTRL_MAXLEN),
    .SR_RX_CTRL_CLEAR_CMDS(SR_RX_CTRL_CLEAR_CMDS),
    .SR_RX_CTRL_OUTPUT_FORMAT(SR_RX_CTRL_OUTPUT_FORMAT),
    .SR_RX_STREAM_ENABLE(SR_RX_STREAM_ENABLE),
    .NUM_BEAMS(NUM_BEAMS),
    .BEAM_WIDTH(16)
  )
  rx_control_eiscat_inst (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[0]),
    .vita_time(vita_time), .sid(8'h00000000), .resp_sid({src_sid[15:0], resp_out_dst_sid[15:0]}),
    .set_stb(set_stb_mux), .set_addr(set_addr_mux), .set_data(set_data_mux),
    .rx_tdata(beams_rx_tdata), .rx_tlast(beams_rx_tlast),
    .rx_tvalid(beams_rx_tvalid), .rx_tready(beams_rx_tready), .rx_tuser(beams_rx_tuser),
    .resp_tdata(rx_resp_tdata), .resp_tlast(rx_resp_tlast), .resp_tvalid(rx_resp_tvalid), .resp_tready(rx_resp_tready), .resp_tuser(rx_resp_tuser),
    .strobe(contribute_beams_mux_tvalid), //output of beamform_delay_and_sum
    .sample(contribute_beams_mux_tdata),
    .run(run_rx),
    .clear_out(rx_control_clear_out),
    .stream_enabled_out(rx_stream_enabled),
    .ibs_state_out(rx_ibs_state_out)
    );
    
  //reg this to help with timing.
  always @(posedge ce_clk) begin
    if(rx_control_clear_out) begin
      rx_control_clear_reg_bth <= 1'b1;
      rx_control_clear_reg_bfn <= 1'b1;
      rx_control_clear_reg_pb <= 1'b1;
      rx_control_clear_reg_tsce <= 1'b1;
      rx_control_clear_tlast <= 1'b1;
      rx_control_clear_ddc <= 1'b1;
      rx_control_clear_aurora <= 1'b1;
    end else begin
      if(&s_axis_data16_tready) begin
        rx_control_clear_reg_bth <= 1'b0;
        rx_control_clear_reg_bfn <= 1'b0;
        rx_control_clear_reg_pb <= 1'b0;
        rx_control_clear_reg_tsce <= 1'b0;
        rx_control_clear_tlast <= 1'b0;
        rx_control_clear_ddc <= 1'b0;
        rx_control_clear_aurora <= 1'b0;
      end
    end
  end
  
  // Synchronous reset for the radio_clk domain, based on the global_rst.
  reset_sync radio_reset_gen (
    .clk(bus_clk),
    .reset_in(rx_control_clear_aurora),
    .reset_out(rst_npio)
  );


  counter #(.WIDTH(9)) counter_inst
    (.clk(ce_clk), .reset(ce_rst), .clear(0),
    .max(9'h0FF),
    .i_tlast(1'b0), .i_tvalid(rx_in_stb[0]), .i_tready(),
    .o_tdata(counter_out), .o_tlast(), .o_tvalid(rx_counter_stb), .o_tready(1'b1));

  assign counter_tdata = {7'b0000000, counter_out};

  wire [15:0]     rx_in[0:15];
  wire            rx_in_stb[0:15];
  wire [16*5-1:0] rx_mux;
  wire [4:0]      rx_mux_stb;
  wire [3:0]      ant_sel_base[4:0];


  assign contribute_beams_mux_tvalid = (choose_beams[2] == 1'b0) ? contribute_beams_tvalid:   // FIR output (note when choose_beams[3:2] = 2'b10, the FIR matrix is fed a counter.
                                       (choose_beams[3] == 1'b1) ? {10{rx_counter_stb}}:   // Counter
                                                                   {rx_mux_stb[4:0], rx_mux_stb[4:0]};    // Direct output for 5 channels // Select from 0-15

  assign contribute_beams_mux_tdata = (choose_beams[2] == 1'b0) ? contribute_beams_tdata :      // FIR
                                      (choose_beams[3] == 1'b1) ? {10{counter_tdata}}   :      // Counter
                                                                 {rx_mux[79:0], rx_mux[79:0]};      // Direct output for 5 channels // Select from 0-15                                              ;

  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin
      assign rx_in[k]     = rx[16*k+15:16*k];
      assign rx_in_stb[k] = rx_stb[k];
    end
  endgenerate

  localparam SR_ANT_SEL_BASE0 = 192;
  localparam SR_ANT_SEL_BASE1 = 193;
  localparam SR_ANT_SEL_BASE2 = 194;
  localparam SR_ANT_SEL_BASE3 = 195;
  localparam SR_ANT_SEL_BASE4 = 196;

  setting_reg #(
    .my_addr(SR_ANT_SEL_BASE0), .awidth(8), .width(4))
  sr_ant_sel_base0 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(ant_sel_base[0]), .changed());

  setting_reg #(
    .my_addr(SR_ANT_SEL_BASE1), .awidth(8), .width(4))
  sr_ant_sel_base1 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(ant_sel_base[1]), .changed());

  setting_reg #(
    .my_addr(SR_ANT_SEL_BASE2), .awidth(8), .width(4))
  sr_ant_sel_base2 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(ant_sel_base[2]), .changed());

  setting_reg #(
    .my_addr(SR_ANT_SEL_BASE3), .awidth(8), .width(4))
  sr_ant_sel_base3 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(ant_sel_base[3]), .changed());

  setting_reg #(
    .my_addr(SR_ANT_SEL_BASE4), .awidth(8), .width(4))
  sr_ant_sel_base4 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(ant_sel_base[4]), .changed());

  generate
  for (k = 0; k < 5; k = k + 1) begin
    assign rx_mux[16*k+15:16*k] = rx_in[ant_sel_base[k]];
    assign rx_mux_stb[k] = rx_in_stb[ant_sel_base[k]];
  end
  endgenerate
  
  //new delay trigger when starting a new run to clear any outstanding error conditions.
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      run_rx_reg <= 1'b0;
      run_rx_reg_delay <= 1'b0;
    end else
      run_rx_reg <= run_rx;
      run_rx_reg_delay <= run_rx_reg;
  end
  assign run_rx_rising_edge = run_rx & ~run_rx_reg_delay;


  ////////////////////////////////////////////////////////////
  //
  //  3. AXI MUXES with setting reg to decide which set of 5 contributions
  //     are kept here and which are shared with the neighbor.
  //
  ////////////////////////////////////////////////////////////

  //NOTE: adding debug functionality when choose_beams == 2, stream first 5 beams directly to block output
  //note when choose beams[2] = 1, do ramp.
  //overhauling choose beams:
  // choose_beams[0] chooses neighbors
  // choose_beams[1] = 1, beams_to_here goes directly to output, regardless of what it is.
  // choose_beams[2] = 1, input to rx_receive direct from jesd_core (bypassing beamforming)
  // choose_beams[3] = 1, set data source to counter.
  // if choose_beams[2] == 0 & choose_beams[3] = 1 -> use counter as data source on beamforming operation.
  setting_reg #(
    .my_addr(SR_BEAMS_TO_NEIGHBOR), .awidth(8), .width(4))
  sr_choose_beams (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(choose_beams), .changed());

  //if choose_beams[0] = 0, lower 5 beams stay here, 5 upper beams goto neighbor
  //if choose_beams[0] = 1, lower 5 beams goto neighbor, 5 upper beams stay here
  genvar ii;
  generate
  for (ii = 0; ii < (NUM_BEAMS_DIV2); ii = ii + 1) begin
    assign beams_to_here_tdata[ii*16+15:ii*16] = (choose_beams[0] == 1'b1) ?
        beams_rx_tdata[16*(ii+(NUM_BEAMS_DIV2))+15:16*(ii+(NUM_BEAMS_DIV2))] :
        beams_rx_tdata[16*(ii)+15:16*(ii)];
    assign beams_to_here_tvalid[ii] = (choose_beams[0] == 1'b1) ? beams_rx_tvalid[ii+(NUM_BEAMS_DIV2)] : beams_rx_tvalid[ii];
    assign beams_to_here_tlast[ii] = (choose_beams[0] == 1'b1) ? beams_rx_tlast[ii+(NUM_BEAMS_DIV2)] : beams_rx_tlast[ii];
    assign beams_to_neighbors_tdata[ii*16+15:ii*16] = (choose_beams[0] == 1'b1) ?
        beams_rx_tdata[16*(ii)+15:16*(ii)] :
        beams_rx_tdata[16*(ii+(NUM_BEAMS_DIV2))+15:16*(ii+(NUM_BEAMS_DIV2))];
    assign beams_to_neighbors_tvalid[ii] = (choose_beams[0] == 1'b1) ? beams_rx_tvalid[ii] : beams_rx_tvalid[ii+(NUM_BEAMS_DIV2)];
    assign beams_to_neighbors_tlast[ii] = (choose_beams[0] == 1'b1) ? beams_rx_tlast[ii] : beams_rx_tlast[ii+(NUM_BEAMS_DIV2)];
    assign beams_rx_tready[ii] = (choose_beams[1] == 1'b1) ? beams_to_here_test_tready[ii] : (choose_beams[0] == 1'b1) ? beams_to_neighbors_tready[ii] : beams_to_here_tready[ii]; //added addition tready option for stream testing mode
    assign beams_rx_tready[ii+(NUM_BEAMS_DIV2)] = (choose_beams[0] == 1'b1) ? beams_to_here_tready[ii] : beams_to_neighbors_tready[ii];

    always @(posedge ce_clk) begin
      bth_fifo_clear_reg[ii] <= error_clear[ii] | choose_beams[1] | clear_tx_seqnum[ii] | rx_control_clear_reg_bth;
      //bth_fifo_clear_reg[ii] = choose_beams[1] | clear_tx_seqnum[ii];
    end

    //beams to here needs to be put in a large fifo of some sort
    axi_fifo #(.WIDTH(17), .SIZE(14)) bth_axi16_8k_fifo
      (.clk(ce_clk), .reset(ce_rst), .clear(bth_fifo_clear_reg[ii]),
      .i_tdata({beams_to_here_tlast[ii],beams_to_here_tdata[ii*16+15:ii*16]}),
      .i_tvalid(beams_to_here_tvalid[ii]), .i_tready(beams_to_here_tready[ii]),
      .o_tdata({beams_to_here_fifo_tlast[ii],beams_to_here_fifo_tdata[ii*16+15:ii*16]}),
      .o_tvalid(beams_to_here_fifo_tvalid[ii]), .o_tready(beams_to_here_fifo_tready[ii]),
      .occupied(bth_data_occupied[ii]), .space(bth_data_space[ii]));

    //for testing/debug we need to
    axi_fifo #(.WIDTH(17), .SIZE(1)) bth_axi16_testing_fifo
      (.clk(ce_clk), .reset(ce_rst), .clear( clear_tx_seqnum[ii] | !choose_beams[1]),
      .i_tdata({beams_to_here_tlast[ii],beams_to_here_tdata[ii*16+15:ii*16]}),
      .i_tvalid(beams_to_here_tvalid[ii]), .i_tready(beams_to_here_test_tready[ii]),
      .o_tdata({s_axis_data16_streams_tlast[ii],s_axis_data16_streams_tdata[ii*16+15:ii*16]}),
      .o_tvalid(s_axis_data16_streams_tvalid[ii]), .o_tready(s_axis_data16_streams_tready[ii]),
      .occupied(), .space());

  end
  endgenerate




////////////////////////////////////////////////////////////
//
// 4. Aurora interface. Conversion module to get 1 aurora stream into 5 16 bit data streams.
//
////////////////////////////////////////////////////////////


  multi_stream_aurora_handler
  #(.NUM_STREAMS(NUM_BEAMS_DIV2),
    .DATA_WIDTH(16),
    .AURORA_DEBUG(AURORA_DEBUG)
    )
  inst_aurora_handler (
    .clk(ce_clk), .rst(ce_rst), 
    .bus_clk(bus_clk), .bus_rst(bus_rst),     
    .clear(rx_control_clear_aurora), .clear_tx_seqnum(clear_tx_seqnum),
    //input beam tuser (including time)
    .rx_tuser(beams_rx_tuser),
    .rx_src_sid(src_sid),
    .rx_dst_sid(next_dst_sid),
    //beams
    .streams_to_neighbors_tdata(beams_to_neighbors_tdata),
    .streams_to_neighbors_tlast(beams_to_neighbors_tlast),
    .streams_to_neighbors_tvalid(beams_to_neighbors_tvalid),
    .streams_to_neighbors_tready(beams_to_neighbors_tready),
    .streams_to_neighbors_tuser(beams_to_neighbors_tuser),
    .streams_from_neighbors_tdata(beams_from_neighbors_tdata),
    .streams_from_neighbors_tlast(beams_from_neighbors_tlast),
    .streams_from_neighbors_tvalid(beams_from_neighbors_tvalid),
    .streams_from_neighbors_tready(beams_from_neighbors_tready),
    //output beam time needed to time align data.
    .streams_from_neighbors_tuser(beams_from_neighbors_tuser),
    //64 bit AXIS to/from npio mgt core
    .i_npio_tdata(i_npio_tdata),
    .i_npio_tvalid(i_npio_tvalid),
    .i_npio_tlast(i_npio_tlast),
    .i_npio_tready(i_npio_tready),

    .o_npio_tdata(o_npio_tdata),
    .o_npio_tvalid(o_npio_tvalid),
    .o_npio_tlast(o_npio_tlast),
    .o_npio_tready(o_npio_tready)
  );
    //assign s_axis_data_tuser = beams_from_neighbors_tuser;

  //register this to help with timing.
  always @(posedge ce_clk) begin
    beams_to_neighbors_tuser_reg <= beams_to_neighbors_tuser;
  end


  //assign beams_from_neighbors_tready = {NUM_BEAMS_DIV2{1'b1}};
  genvar n;
  generate
    for (n = 0; n < (NUM_BEAMS_DIV2); n = n + 1) begin
      always @(posedge ce_clk) begin
        bfn_fifo_clear_reg[n] <= choose_beams[1] | clear_tx_seqnum[n] | error_clear[n] | rx_control_clear_reg_bfn;
      end

      //beams from neighbors needs to be put in a large fifo of some sort
      axi_fifo #(.WIDTH(17), .SIZE(14)) bfn_axi16_8k_fifo
        (.clk(ce_clk), .reset(ce_rst), .clear(bfn_fifo_clear_reg[n] ),
        .i_tdata({beams_from_neighbors_tlast[n],beams_from_neighbors_tdata[n*16+15:n*16]}),
        .i_tvalid(beams_from_neighbors_tvalid[n]), .i_tready(beams_from_neighbors_tready[n]),
        .o_tdata({beams_from_neighbors_fifo_tlast[n],beams_from_neighbors_fifo_tdata[n*16+15:n*16]}),
        .o_tvalid(beams_from_neighbors_fifo_tvalid[n]), .o_tready(beams_from_neighbors_fifo_tready[n]),
        .occupied(bfn_data_occupied[n]), .space(bfn_data_space[n]));
    end
  endgenerate





  ////////////////////////////////////////////////////////////
  //
  // 5. Get above contributions either from noc shell or null source. need 5 of these for the 5 previous beams
  //
  ////////////////////////////////////////////////////////////
  setting_reg #(
    .my_addr(SR_PREV_OR_NULL), .awidth(8), .width(1))
  sr_prev_beams_or_null (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb_mux), .addr(set_addr_mux), .in(set_data_mux), .out(choose_prev), .changed());

  //if this N310 is in the "top row" of the TILE, then there is not an above contribution so it's null
  genvar p;
  generate
    for (p = 0; p < (NUM_BEAMS_DIV2); p = p + 1) begin
      assign previous_beam_tdata[16*p+15:16*p] = ~choose_prev ? 16'b0 : m_axis_data16_fifo_tdata[p];
      assign previous_beam_tlast[p] = ~choose_prev ? beams_from_neighbors_tlast[p] : m_axis_data16_fifo_tlast[p];
      //when prev = null, previous beam tvalid is only valid when beams from neighbors is ready.
      assign previous_beam_tvalid[p] = ~choose_prev ? (beams_from_neighbors_tvalid[p] & beams_from_neighbors_tready[p]) : m_axis_data16_fifo_tvalid[p];
      assign previous_beam_tuser[128*p+127:128*p] = ~choose_prev ? beams_from_neighbors_tuser[128*p+127:128*p] : m_axis_data_tuser_reg[128*p+127:128*p];
      assign m_axis_data16_fifo_tready[p] = ~choose_prev ? 1'b0 : previous_beam_tready[p];

      always @(posedge ce_clk) begin
        if( ce_rst | pb_fifo_clear_reg[p]) begin
          m_axis_data_tuser_reg[128*p+127:128*p] = 128'h0FFF000000000000FFFFFFFFEEEEDDDD;//so that when we start with seqnum 000, this is triggered.;
        end else
          if( m_axis_data_tvalid[p] & m_axis_data_tready[p]) begin
            m_axis_data_tuser_reg[128*p+127:128*p] = m_axis_data_tuser[128*p+127:128*p];
          end
      end

      always @(posedge ce_clk) begin
        pb_fifo_clear_reg[p] = choose_beams[1] | clear_tx_seqnum[p] | error_clear[p] | rx_control_clear_reg_pb;
      end

      axi_fifo #(.WIDTH(17), .SIZE(14)) pb_axi16_8k_fifo
        (.clk(ce_clk), .reset(ce_rst), .clear(pb_fifo_clear_reg[p] ),
        .i_tdata({previous_beam_tlast[p],previous_beam_tdata[p*16+15:p*16]}),
        .i_tvalid(previous_beam_tvalid[p]), .i_tready(previous_beam_tready[p]),
        .o_tdata({previous_beam_fifo_tlast[p],previous_beam_fifo_tdata[p*16+15:p*16]}),
        .o_tvalid(previous_beam_fifo_tvalid[p]), .o_tready(previous_beam_fifo_tready[p]),
        .occupied(pb_data_occupied[p]), .space(pb_data_space[p]));

    end
  endgenerate
  //choose between the null source or the above contribution which we get from the axi wrapper/noc shell
  //debug
  //assign previous_beam_tvalid =5'b00001;

  ////////////////////////////////////////////////////////////
  //
  // 6. Sum together all sources. need 5 of these for the 5 beams.
  //
  ////////////////////////////////////////////////////////////
  // Drop packets at the input of summation block
  // in case of overflow or time alignment errors
  // till the radio restarts
  reg latched_error;

  //add together: this device's beamform contribution, the neighbor contribution (from the nano-pitch aurora link), & the output of the above demux
  genvar s;
  generate
    for (s = 0; s < (NUM_BEAMS_DIV2); s = s + 1) begin
      //clear time stream fifos with tusers
      always @(posedge ce_clk) begin
        time_stream_clear_reg[s] = run_rx_rising_edge | clear_tx_seqnum[s] | choose_beams[1] | rx_control_clear_reg_tsce;
      end

      always @ (posedge ce_clk) begin
        beam_to_here_tvalid_shift_reg[s*3+2:s*3] <= {beam_to_here_tvalid_shift_reg[s*3+1:s*3], beams_to_here_tvalid[s] & !choose_beams[1]};
        beam_to_here_tready_shift_reg[s*3+2:s*3] <= {beam_to_here_tready_shift_reg[s*3+1:s*3], beams_to_here_tready[s]};
      end
      //need to delay these values for the tuser to propagate to the time stream control at the right time
      assign beams_to_here_del_tvalid[s] = beam_to_here_tvalid_shift_reg[3*s+2];
      assign beams_to_here_del_tready[s] = beam_to_here_tvalid_shift_reg[3*s+2];


      time_align_control_eiscat #( .NUM_STREAMS(3)) tace_inst (
        .clk(ce_clk), .reset(ce_rst), .clear(time_stream_clear_reg[s]),
        .resp_sid({beams_to_neighbors_tuser_reg[95+128*s:80+128*s],resp_out_dst_sid[15:0]}),
        .i_tuser({previous_beam_tuser[128*s+127:128*s],beams_from_neighbors_tuser[128*s+127:128*s],beams_to_neighbors_tuser[128*s+127:128*s]}),
        .i_tlast({previous_beam_fifo_flop_tlast[s],beams_from_neighbors_fifo_flop_tlast[s],beams_to_here_fifo_flop_tlast[s]}),
        .i_tvalid({previous_beam_tvalid[s],beams_from_neighbors_tvalid[s],beams_to_here_del_tvalid[s]}),
        .i_tready({previous_beam_tready[s],beams_from_neighbors_tready[s],beams_to_here_del_tready[s]}),
        .o_tuser(out_stream_tuser[128*s+127:128*s]),
        .resp_tdata(time_stream_resp_tdata[64*s+63:64*s]), .resp_tuser(time_stream_resp_tuser[128*s+127:128*s]),
        .resp_tlast(time_stream_resp_tlast[s]), .resp_tvalid(time_stream_resp_tvalid[s]),
        .resp_tready(time_stream_resp_tready[s]),
        //.resp_tready(1'b1),
        .error_out(time_stream_error_out[s])
     );
     assign out_stream_tuser_or_eob[128*s+127:128*s] = {out_stream_tuser[128*s+127:128*s+125],
                                                        out_stream_tuser[128*s+124]|rx_control_clear_eob[s],
                                                        out_stream_tuser[128*s+123:128*s]}; //in an overrun force this packet header to have eob
     //this circuit will force an eob on the last overflow data packet until tlast, tvalid, and tready are all asserted. 
     always @ (posedge ce_clk) begin
       if(ce_rst | run_rx_rising_edge) begin
         rx_control_clear_eob[s] <= 1'b0;
       end else begin
         if(rx_control_clear_out & s_axis_data_tvalid[s]) begin
           rx_control_clear_eob[s] <= 1'b1;
         end else begin
           if( s_axis_data_tlast[s] & s_axis_data_tvalid[s] & s_axis_data_tready[s]) begin
             rx_control_clear_eob[s] <= 1'b0;
           end
         end
       end
     end

     axi_fifo #(.WIDTH(17), .SIZE(1)) ff_before_sum_beams_to_here (
       .clk(ce_clk), .reset(ce_rst), .clear(rx_control_clear_reg_tsce),
       .i_tdata({beams_to_here_fifo_tlast[s], beams_to_here_fifo_tdata[16*s+15:16*s]}),
       .i_tvalid(beams_to_here_fifo_tvalid[s]),
       .i_tready(beams_to_here_fifo_tready[s]),
       .o_tdata({beams_to_here_fifo_flop_tlast[s], beams_to_here_fifo_flop_tdata[16*s+15:16*s]}),
       .o_tvalid(beams_to_here_fifo_flop_tvalid[s]),
       .o_tready(beams_to_here_fifo_flop_tready[s]),
       .occupied(), .space());

     axi_fifo #(.WIDTH(17), .SIZE(1)) ff_before_sum_beams_from_neighbors (
       .clk(ce_clk), .reset(ce_rst), .clear(rx_control_clear_reg_tsce),
       .i_tdata({beams_from_neighbors_fifo_tlast[s], beams_from_neighbors_fifo_tdata[16*s+15:16*s]}),
       .i_tvalid(beams_from_neighbors_fifo_tvalid[s]),
       .i_tready(beams_from_neighbors_fifo_tready[s]),
       .o_tdata({beams_from_neighbors_fifo_flop_tlast[s], beams_from_neighbors_fifo_flop_tdata[16*s+15:16*s]}),
       .o_tvalid(beams_from_neighbors_fifo_flop_tvalid[s]),
       .o_tready(beams_from_neighbors_fifo_flop_tready[s]),
       .occupied(), .space());

     axi_fifo #(.WIDTH(17), .SIZE(1)) ff_before_sum_previous_beam (
       .clk(ce_clk), .reset(ce_rst), .clear(rx_control_clear_reg_tsce),
       .i_tdata({previous_beam_fifo_tlast[s], previous_beam_fifo_tdata[16*s+15:16*s]}),
       .i_tvalid(previous_beam_fifo_tvalid[s]),
       .i_tready(previous_beam_fifo_tready[s]),
       .o_tdata({previous_beam_fifo_flop_tlast[s], previous_beam_fifo_flop_tdata[16*s+15:16*s]}),
       .o_tvalid(previous_beam_fifo_flop_tvalid[s]),
       .o_tready(previous_beam_fifo_flop_tready[s]),
       .occupied(), .space());

      // Detect overflow
      assign overflow[s] = final_sum_tvalid[s] & ~final_sum_tready[s];
      
      //final summation from this device, neighbor, and previous
      //input i: beams_to_here, beams_from_neighbors, previous_beam
      //         16 bits, 1 integer bits. 1.0 float = 2**15-1
      //output o: final_sum_tdata
      //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1         
      multi_stream_add #(.WIDTH(16),.NUM_INPUTS(3)) final_beam_sum_inst (
       .clk(ce_clk), .rst(ce_rst), .drop(0),
       .i_tdata({previous_beam_fifo_flop_tdata[16*s+15:16*s],beams_from_neighbors_fifo_flop_tdata[16*s+15:16*s],beams_to_here_fifo_flop_tdata[16*s+15:16*s]}),
       .i_tlast({previous_beam_fifo_flop_tlast[s],beams_from_neighbors_fifo_flop_tlast[s],beams_to_here_fifo_flop_tlast[s]}),
       .i_tvalid({previous_beam_fifo_flop_tvalid[s],beams_from_neighbors_fifo_flop_tvalid[s],beams_to_here_fifo_flop_tvalid[s]}),
       .i_tready({previous_beam_fifo_flop_tready[s],beams_from_neighbors_fifo_flop_tready[s],beams_to_here_fifo_flop_tready[s]}),
       .sum_tdata(final_sum_tdata[18*s+17:18*s]),
       .sum_tlast(final_sum_tlast[s]),
       .sum_tvalid(final_sum_tvalid[s]),
       .sum_tready(final_sum_tready[s]));

     //final fifo after summation, after rounding, before final output contribution beams
     axi_fifo #(
       .WIDTH(19), .SIZE(1))
     inst_axi_fifo_sum_prev (
       .clk(ce_clk), .reset(ce_rst), .clear(rx_control_clear_reg_tsce),
       .i_tdata({final_sum_tlast[s], final_sum_tdata[18*s+17:18*s]}),
       .i_tvalid(final_sum_tvalid[s]), .i_tready(final_sum_tready[s]),
       .o_tdata({final_sum_fifo_tlast[s], final_sum_fifo_tdata[18*s+17:18*s]}),
       .o_tvalid(final_sum_fifo_tvalid[s]), .o_tready(final_sum_fifo_tready[s]),
       .space(), .occupied());

     // Clip extra bits for bit growth
     //FINAL CALCULATION STEP!!!! Next step is back to AXI WRAPPER!
     //input i: final_sum_fifo_tdata
     //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1         
     //output o: s_axis_data16_sum_tdata
     //          16 bits, 1 integer bits. 1.0 float = 2**15-1
     axi_clip #(
       .WIDTH_IN(18),
       .WIDTH_OUT(16))
     inst_axi_clip_sum (
       .clk(ce_clk), .reset(ce_rst),
       .i_tdata(final_sum_fifo_tdata[18*s+17:18*s]),
       .i_tlast(final_sum_fifo_tlast[s]),
       .i_tvalid(final_sum_fifo_tvalid[s]),
       .i_tready(final_sum_fifo_tready[s]),
       .o_tdata(s_axis_data16_sum_tdata[16*s+15:16*s]),
       .o_tlast(s_axis_data16_sum_tlast[s]),
       .o_tvalid(s_axis_data16_sum_tvalid[s]),
       .o_tready(s_axis_data16_sum_tready[s]));

    end
  endgenerate

  //testing mux and also prev/non prev mux.
  assign s_axis_data_tuser = (choose_beams[1] == 1'b1) ? beams_to_neighbors_tuser_reg : out_stream_tuser_or_eob; //if debug stream mode, use tuser for each stream generated for aurora tx purposes.
  assign s_axis_data16_tdata = (choose_beams[1] == 1'b1) ? s_axis_data16_streams_tdata : s_axis_data16_sum_tdata;
  assign s_axis_data16_tvalid = (choose_beams[1] == 1'b1) ? s_axis_data16_streams_tvalid : s_axis_data16_sum_tvalid;
  assign s_axis_data16_tlast = {5{rx_control_clear_tlast}} | ((choose_beams[1] == 1'b1) ? s_axis_data16_streams_tlast : s_axis_data16_sum_tlast);
  assign s_axis_data16_streams_tready = (choose_beams[1] == 1'b1) ? s_axis_data16_tready : 5'b0;
  assign s_axis_data16_sum_tready = (choose_beams[1] == 1'b0) ? s_axis_data16_tready : 5'b0;
  
  //clear from time stream when error occurs
  always @(posedge ce_clk) begin
    if(ce_rst | run_rx_rising_edge) begin
      error_clear_reg <= {NUM_BEAMS_DIV2{1'b0}};
    end else
      error_clear_reg <= time_stream_error_out;
  end
  assign error_clear = error_clear_reg;
  
endmodule
