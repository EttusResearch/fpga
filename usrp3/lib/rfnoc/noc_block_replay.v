//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: noc_block_replay
//
// Description: RFNoC data record and replay block. See axi_replay.v for 
//              details of operation.

`default_nettype none



module noc_block_replay #(
  // NOC_ID ("REPLAY")
  parameter NOC_ID = 64'h4E91_A000_0000_0000,

  // Input buffering to tolerate DMA (usually DRAM) latency variation
  parameter STR_SINK_FIFOSIZE = 11,

  // Log2 of maximum packet length
  parameter MTU = 10,

  // Number of replay blocks to implement
  parameter NUM_REPLAY_BLOCKS = 1,

  // Memory width to use internally
  parameter MEM_ADDR_W = 30
) (
  //
  // Clocks and Resets
  //
  input wire bus_clk,
  input wire bus_rst,
  input wire ce_clk,
  input wire ce_rst,

  //
  // RFNoC CHDR interface to crossbar
  //
  // Sink
  input  wire [63:0] i_tdata,
  input  wire        i_tlast,
  input  wire        i_tvalid,
  output wire        i_tready,
  // Source
  output wire [63:0] o_tdata,
  output wire        o_tlast,
  output wire        o_tvalid,
  input  wire        o_tready,

  //
  // AXI Memory Mapped Interface (for DRAM)
  //
  // -- AXI Write address channel
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_awid,     // Write address ID. This signal is the identification tag for the write address signals.
  output wire [(NUM_REPLAY_BLOCKS*32)-1:0] m_axi_awaddr,   // Write address. The write address gives the address of the first transfer in a write burst.
  output wire [ (NUM_REPLAY_BLOCKS*8)-1:0] m_axi_awlen,    // Burst length. The burst length gives the exact number of transfers in a burst.
  output wire [ (NUM_REPLAY_BLOCKS*3)-1:0] m_axi_awsize,   // Burst size. This signal indicates the size of each transfer in the burst.
  output wire [ (NUM_REPLAY_BLOCKS*2)-1:0] m_axi_awburst,  // Burst type. The burst type and the size information, determine how the address is calculated.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_awlock,   // Lock type. Provides additional information about the atomic characteristics of the transfer.
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_awcache,  // Memory type. This signal indicates how transactions are required to progress.
  output wire [ (NUM_REPLAY_BLOCKS*3)-1:0] m_axi_awprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_awqos,    // Quality of Service, QoS. The QoS identifier sent for each write transaction.
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_awregion, // Region identifier. Permits a single physical interface on a slave to be re-used.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_awuser,   // User signal. Optional User-defined signal in the write address channel.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_awvalid,  // Write address valid. This signal indicates that the channel is signaling valid write address.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_awready,  // Write address ready. This signal indicates that the slave is ready to accept an address.
  // -- AXI Write data channel
  output wire [(NUM_REPLAY_BLOCKS*64)-1:0] m_axi_wdata,    // Write data
  output wire [ (NUM_REPLAY_BLOCKS*8)-1:0] m_axi_wstrb,    // Write strobes. This signal indicates which byte lanes hold valid data.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_wlast,    // Write last. This signal indicates the last transfer in a write burst.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_wuser,    // User signal. Optional User-defined signal in the write data channel.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_wvalid,   // Write valid. This signal indicates that valid write data and strobes are available.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_wready,   // Write ready. This signal indicates that the slave can accept the write data.
  // -- AXI Write response channel signals
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_bid,      // Response ID tag. This signal is the ID tag of the write response.
  input  wire [ (NUM_REPLAY_BLOCKS*2)-1:0] m_axi_bresp,    // Write response. This signal indicates the status of the write transaction.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_buser,    // User signal. Optional User-defined signal in the write response channel.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_bvalid,   // Write response valid. This signal indicates that the channel is signaling a valid response.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_bready,   // Response ready. This signal indicates that the master can accept a write response.
  // -- AXI Read address channel
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_arid,     // Read address ID. This signal is the identification tag for the read address group of signals.
  output wire [(NUM_REPLAY_BLOCKS*32)-1:0] m_axi_araddr,   // Read address. The read address gives the address of the first transfer in a read burst.
  output wire [ (NUM_REPLAY_BLOCKS*8)-1:0] m_axi_arlen,    // Burst length. This signal indicates the exact number of transfers in a burst.
  output wire [ (NUM_REPLAY_BLOCKS*3)-1:0] m_axi_arsize,   // Burst size. This signal indicates the size of each transfer in the burst.
  output wire [ (NUM_REPLAY_BLOCKS*2)-1:0] m_axi_arburst,  // Burst type. The burst type and the size information determine how the address for each transfer.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_arlock,   // Lock type. This signal provides additional information about the atomic characteristics.
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_arcache,  // Memory type. This signal indicates how transactions are required to progress.
  output wire [ (NUM_REPLAY_BLOCKS*3)-1:0] m_axi_arprot,   // Protection type. This signal indicates the privilege and security level of the transaction.
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_arqos,    // Quality of Service, QoS. QoS identifier sent for each read transaction.
  output wire [ (NUM_REPLAY_BLOCKS*4)-1:0] m_axi_arregion, // Region identifier. Permits a single physical interface on a slave to be re-used.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_aruser,   // User signal. Optional User-defined signal in the read address channel.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_arvalid,  // Read address valid. This signal indicates that the channel is signaling valid read address.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_arready,  // Read address ready. This signal indicates that the slave is ready to accept an address.
  // -- AXI Read data channel
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_rid,      // Read ID tag. This signal is the identification tag for the read data group of signals.
  input  wire [(NUM_REPLAY_BLOCKS*64)-1:0] m_axi_rdata,    // Read data.
  input  wire [ (NUM_REPLAY_BLOCKS*2)-1:0] m_axi_rresp,    // Read response. This signal indicates the status of the read transfer.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_rlast,    // Read last. This signal indicates the last transfer in a read burst.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_ruser,    // User signal. Optional User-defined signal in the read data channel.
  input  wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_rvalid,   // Read valid. This signal indicates that the channel is signaling the required read data.
  output wire [ (NUM_REPLAY_BLOCKS*1)-1:0] m_axi_rready,   // Read ready. This signal indicates that the master can accept the read data and response.
  //
  // Debug
  //
  output wire [                      63:0] debug
);

  //---------------------------------------------------------------------------
  // Constants
  //---------------------------------------------------------------------------

  localparam MEM_DATA_W = 64;   // CHDR standard unit
  localparam MEM_COUNT_W = 8;   // Width of DMA count

  //---------------------------------------------------------------------------
  // Declarations
  //---------------------------------------------------------------------------

  wire [NUM_REPLAY_BLOCKS*MEM_DATA_W-1:0] m_axis_data_tdata; 
  wire [       NUM_REPLAY_BLOCKS-1:0] m_axis_data_tlast; 
  wire [       NUM_REPLAY_BLOCKS-1:0] m_axis_data_tvalid;
  wire [       NUM_REPLAY_BLOCKS-1:0] m_axis_data_tready;

  wire [NUM_REPLAY_BLOCKS*MEM_DATA_W-1:0] s_axis_data_tdata; 
  wire [   NUM_REPLAY_BLOCKS*128-1:0] s_axis_data_tuser;
  wire [       NUM_REPLAY_BLOCKS-1:0] s_axis_data_tlast; 
  wire [       NUM_REPLAY_BLOCKS-1:0] s_axis_data_tvalid;
  wire [       NUM_REPLAY_BLOCKS-1:0] s_axis_data_tready;

  wire [(NUM_REPLAY_BLOCKS*32)-1:0] set_data;
  wire [ (NUM_REPLAY_BLOCKS*8)-1:0] set_addr;
  wire [     NUM_REPLAY_BLOCKS-1:0] set_stb;
  wire [(NUM_REPLAY_BLOCKS*64)-1:0] rb_data;
  wire [ (NUM_REPLAY_BLOCKS*8)-1:0] rb_addr;

  wire [(NUM_REPLAY_BLOCKS*64)-1:0] str_sink_tdata,  str_src_tdata;
  wire [     NUM_REPLAY_BLOCKS-1:0] str_sink_tlast,  str_sink_tvalid,
                                    str_sink_tready, str_src_tlast,
                                    str_src_tvalid,  str_src_tready;

  wire [     NUM_REPLAY_BLOCKS-1:0] clear_tx_seqnum;
  wire [(NUM_REPLAY_BLOCKS*16)-1:0] src_id;
  wire [(NUM_REPLAY_BLOCKS*16)-1:0] next_dst_sid;   

  wire [NUM_REPLAY_BLOCKS*MEM_ADDR_W-1:0] write_addr;
  wire [         NUM_REPLAY_BLOCKS*8-1:0] write_count;
  wire [           NUM_REPLAY_BLOCKS-1:0] write_ctrl_valid;
  wire [           NUM_REPLAY_BLOCKS-1:0] write_ctrl_ready;
  wire [        NUM_REPLAY_BLOCKS*64-1:0] write_data;
  wire [           NUM_REPLAY_BLOCKS-1:0] write_data_valid;
  wire [           NUM_REPLAY_BLOCKS-1:0] write_data_ready;

  wire [NUM_REPLAY_BLOCKS*MEM_ADDR_W-1:0] read_addr;
  wire [         NUM_REPLAY_BLOCKS*8-1:0] read_count;
  wire [           NUM_REPLAY_BLOCKS-1:0] read_ctrl_valid;
  wire [           NUM_REPLAY_BLOCKS-1:0] read_ctrl_ready;
  wire [        NUM_REPLAY_BLOCKS*64-1:0] read_data;
  wire [           NUM_REPLAY_BLOCKS-1:0] read_data_valid;
  wire [           NUM_REPLAY_BLOCKS-1:0] read_data_ready;


  //---------------------------------------------------------------------------
  // RFNoC Shell
  //---------------------------------------------------------------------------
  //
  // This block crosses data between the crossbar (bus_clk) clock domain and 
  // the computation engine (ce_clk) clock domain. It also handles flow 
  // control, muxes/demuxes the different packet types onto different ports, 
  // and translates command/response to/from the settings bus.
  //
  //---------------------------------------------------------------------------

  noc_shell #(
    .NOC_ID            (NOC_ID),                                     
    .INPUT_PORTS       (NUM_REPLAY_BLOCKS),                          
    .OUTPUT_PORTS      (NUM_REPLAY_BLOCKS),                          
    .STR_SINK_FIFOSIZE ({NUM_REPLAY_BLOCKS{STR_SINK_FIFOSIZE[7:0]}}),
    .MTU               ({NUM_REPLAY_BLOCKS{MTU[7:0]}}),
    .USE_TIMED_CMDS    (0)
  ) noc_shell (
    // Bus clock domain
    .bus_clk (bus_clk),
    .bus_rst (bus_rst),

    // CHDR interface to crossbar
    .i_tdata  (i_tdata), 
    .i_tlast  (i_tlast), 
    .i_tvalid (i_tvalid),
    .i_tready (i_tready),
    //
    .o_tdata  (o_tdata), 
    .o_tlast  (o_tlast), 
    .o_tvalid (o_tvalid),
    .o_tready (o_tready),

    // Compute engine clock domain
    .clk   (ce_clk),
    .reset (ce_rst),

    // Control sink (settings bus)
    .set_data     (set_data),                 
    .set_addr     (set_addr),                 
    .set_stb      (set_stb),                  
    .set_time     (),                         
    .set_has_time (),                         
    .rb_stb       ({NUM_REPLAY_BLOCKS{1'b1}}),
    .rb_data      (rb_data),                  
    .rb_addr      (rb_addr),                         

    // Control source
    //
    // Command packets from CE to crossbar
    .cmdout_tdata  (64'h0),
    .cmdout_tlast  (1'b0), 
    .cmdout_tvalid (1'b0), 
    .cmdout_tready (),     
    // Response packets from crossbar to CE
    .ackin_tdata   (),     
    .ackin_tlast   (),     
    .ackin_tvalid  (),     
    .ackin_tready  (1'b1), 

    // Stream data sink (output)
    .str_sink_tdata  (str_sink_tdata), 
    .str_sink_tlast  (str_sink_tlast), 
    .str_sink_tvalid (str_sink_tvalid),
    .str_sink_tready (str_sink_tready),

    // Stream data source (input)
    .str_src_tdata  (str_src_tdata), 
    .str_src_tlast  (str_src_tlast), 
    .str_src_tvalid (str_src_tvalid),
    .str_src_tready (str_src_tready),

    // Stream IDs set by host
    .src_sid          (src_id),       // SID of this block
    .next_dst_sid     (next_dst_sid), // Next destination SID
    .resp_in_dst_sid  (),             // Response destination SID for input stream responses / errors
    .resp_out_dst_sid (),             // Response destination SID for output stream responses / errors

    // Misc
    .vita_time       (64'd0),          
    .clear_tx_seqnum (clear_tx_seqnum),
    .debug           (debug)           
  );


  //---------------------------------------------------------------------------
  // Replay Block Instances
  //---------------------------------------------------------------------------

  genvar i;
  generate
    for (i = 0; i < NUM_REPLAY_BLOCKS; i = i+1) begin : gen_replay_blocks
      wire [127:0] s_axis_data_tuser_tmp;

      // Update the src and dst fields in the header
      cvita_hdr_modify cvita_hdr_modify_i (
        .header_in  (s_axis_data_tuser_tmp),
        .header_out (s_axis_data_tuser[(128*(i+1))-1 : 128*i]),
        .use_pkt_type       (1'b0), .pkt_type       (2'b0),
        .use_has_time       (1'b0), .has_time       (1'b0),
        .use_eob            (1'b0), .eob            (1'b0),
        .use_seqnum         (1'b0), .seqnum         (12'b0),
        .use_length         (1'b0), .length         (16'b0),
        .use_payload_length (1'b0), .payload_length (16'b0),
        .use_src_sid        (1'b1), .src_sid        (src_id[(16*(i+1))-1       : 16*i]),
        .use_dst_sid        (1'b1), .dst_sid        (next_dst_sid[(16*(i+1))-1 : 16*i]),
        .use_vita_time      (1'b0), .vita_time      (64'b0)
      );


      //-----------------------------------------------------------------------
      // AXI Wrapper
      //-----------------------------------------------------------------------
      //
      // This block converts the CHDR stream to a pure data stream.
      //
      //-----------------------------------------------------------------------

      axi_wrapper #(
        .MTU                  (MTU),
        .NUM_AXI_CONFIG_BUS   (0),
        .SIMPLE_MODE          (0),
        .USE_SEQ_NUM          (0),
        .RESIZE_INPUT_PACKET  (0),
        .RESIZE_OUTPUT_PACKET (0),
        .WIDTH                (64)
      ) axi_wrapperx (
        .clk   (ce_clk),
        .reset (ce_rst),

        .bus_clk(bus_clk),
        .bus_rst(bus_rst),
        
        .clear_tx_seqnum (clear_tx_seqnum[ (1*(i+1))-1 :  1*i]),
        .next_dst        (next_dst_sid   [(16*(i+1))-1 : 16*i]),
        
        // Settings bus (input, from NoC shell)
        .set_stb  (set_stb [( 1*(i+1))-1 :  1*i]),
        .set_addr (set_addr[( 8*(i+1))-1 :  8*i]),
        .set_data (set_data[(32*(i+1))-1 : 32*i]),
        
        // NoC Shell Interface
        //
        // Stream sink (input, from NoC shell)
        .i_tdata  (str_sink_tdata [(64*(i+1))-1 : 64*i]),
        .i_tlast  (str_sink_tlast [( 1*(i+1))-1 :  1*i]),
        .i_tvalid (str_sink_tvalid[( 1*(i+1))-1 :  1*i]),
        .i_tready (str_sink_tready[( 1*(i+1))-1 :  1*i]),
        //
        // Stream source (output, to NoC shell)
        .o_tdata  (str_src_tdata [(64*(i+1))-1 : 64*i]),
        .o_tlast  (str_src_tlast [( 1*(i+1))-1 :  1*i]),
        .o_tvalid (str_src_tvalid[( 1*(i+1))-1 :  1*i]),
        .o_tready (str_src_tready[( 1*(i+1))-1 :  1*i]),
        
        // AXI4-Stream IP Interface
        //
        // Source (output, to IP)
        .m_axis_data_tdata  (m_axis_data_tdata [(64*(i+1))-1 : 64*i]),
        .m_axis_data_tuser  (),
        .m_axis_data_tlast  (m_axis_data_tlast [( 1*(i+1))-1 :  1*i]),
        .m_axis_data_tvalid (m_axis_data_tvalid[( 1*(i+1))-1 :  1*i]),
        .m_axis_data_tready (m_axis_data_tready[( 1*(i+1))-1 :  1*i]),
        //
        // Sink (input, from IP)
        .s_axis_data_tdata  (s_axis_data_tdata [( 64*(i+1))-1 :  64*i]),
        .s_axis_data_tuser  (s_axis_data_tuser [(128*(i+1))-1 : 128*i]),
        .s_axis_data_tlast  (s_axis_data_tlast [(  1*(i+1))-1 :   1*i]),
        .s_axis_data_tvalid (s_axis_data_tvalid[(  1*(i+1))-1 :   1*i]),
        .s_axis_data_tready (s_axis_data_tready[(  1*(i+1))-1 :   1*i]),
        
        //
        // Packet length control
        .m_axis_pkt_len_tdata  (16'b0),
        .m_axis_pkt_len_tvalid (1'b0),
        .m_axis_pkt_len_tready (),
        
        //
        // Control source (output)
        .m_axis_config_tdata  (),
        .m_axis_config_tlast  (),
        .m_axis_config_tvalid (),
        .m_axis_config_tready (2'b0)
      );


      //-----------------------------------------------------------------------
      // Replay Handler
      //-----------------------------------------------------------------------
      //
      // This block implements the state machine and control logic for 
      // recording and playback of data.
      //
      //-----------------------------------------------------------------------

      // rb_data is 64-bits on the the noc_shell, so set the upper 32-bits of 
      // each 64-bit word to 0.
      assign rb_data[(64*(i+1))-1:64*i+32] = 32'h0;

      axi_replay #(
        .MEM_DATA_W  (MEM_DATA_W),
        .MEM_ADDR_W  (MEM_ADDR_W),
        .MEM_COUNT_W (MEM_COUNT_W)
      ) axi_replay_i (
        .clk (ce_clk),
        .rst (ce_rst),
        
        // Settings Bus
        .set_stb  (set_stb [(    1*(i+1))-1 :  1*i]),
        .set_addr (set_addr[(    8*(i+1))-1 :  8*i]),
        .set_data (set_data[(   32*(i+1))-1 : 32*i]),
        .rb_data  (rb_data [(64*(i+1)-32)-1 : 64*i]),   // Connect lower 32 bits of each 64-bit word
        .rb_addr  (rb_addr [(    8*(i+1))-1 :  8*i]),
        
        // AXI Stream Interface
        //
        // Input
        .i_tdata  (m_axis_data_tdata [( MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .i_tvalid (m_axis_data_tvalid[(          1*(i+1))-1 :  1*i]),
        .i_tlast  (m_axis_data_tlast [(          1*(i+1))-1 :  1*i]),
        .i_tready (m_axis_data_tready[(          1*(i+1))-1 :  1*i]),
        //
        // Output
        .o_tdata  (s_axis_data_tdata [( MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .o_tuser  (s_axis_data_tuser_tmp),
        .o_tvalid (s_axis_data_tvalid[(          1*(i+1))-1 :  1*i]),
        .o_tlast  (s_axis_data_tlast [(          1*(i+1))-1 :  1*i]),
        .o_tready (s_axis_data_tready[(          1*(i+1))-1 :  1*i]),
        
        // DMA Interface
        //
        // Write interface
        .write_addr       (write_addr      [(  MEM_ADDR_W*(i+1))-1 : MEM_ADDR_W*i]),
        .write_count      (write_count     [( MEM_COUNT_W*(i+1))-1 : MEM_COUNT_W*i]),
        .write_ctrl_valid (write_ctrl_valid[(           1*(i+1))-1 :      1*i]),
        .write_ctrl_ready (write_ctrl_ready[(           1*(i+1))-1 :      1*i]),
        .write_data       (write_data      [(  MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .write_data_valid (write_data_valid[(           1*(i+1))-1 :      1*i]),
        .write_data_ready (write_data_ready[(           1*(i+1))-1 :      1*i]),
        //
        // Read interface
        .read_addr        (read_addr      [(  MEM_ADDR_W*(i+1))-1 : MEM_ADDR_W*i]),
        .read_count       (read_count     [( MEM_COUNT_W*(i+1))-1 : MEM_COUNT_W*i]),
        .read_ctrl_valid  (read_ctrl_valid[(           1*(i+1))-1 :      1*i]),
        .read_ctrl_ready  (read_ctrl_ready[(           1*(i+1))-1 :      1*i]),
        .read_data        (read_data      [(  MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .read_data_valid  (read_data_valid[(           1*(i+1))-1 :      1*i]),
        .read_data_ready  (read_data_ready[(           1*(i+1))-1 :      1*i])
      );


      //-----------------------------------------------------------------------
      // AXI DMA Master
      //-----------------------------------------------------------------------
      //
      // This block translates simple read and write requests to AXI4 
      // memory-mapped reads and writes for the RAM interface.
      //
      //-----------------------------------------------------------------------

      axi_dma_master axi_dma_master_i (
        //
        // AXI4 Memory Mapped Interface to DRAM
        //
        .aclk   (ce_clk), // input aclk
        .areset (ce_rst), // input aresetn
        
        // Write control
        .m_axi_awid     (m_axi_awid    [( 1*(i+1))-1 :  1*i]), // input [0 : 0] m_axi_awid
        .m_axi_awaddr   (m_axi_awaddr  [(32*(i+1))-1 : 32*i]), // input [31 : 0] m_axi_awaddr
        .m_axi_awlen    (m_axi_awlen   [( 8*(i+1))-1 :  8*i]), // input [7 : 0] m_axi_awlen
        .m_axi_awsize   (m_axi_awsize  [( 3*(i+1))-1 :  3*i]), // input [2 : 0] m_axi_awsize
        .m_axi_awburst  (m_axi_awburst [( 2*(i+1))-1 :  2*i]), // input [1 : 0] m_axi_awburst
        .m_axi_awvalid  (m_axi_awvalid [( 1*(i+1))-1 :  1*i]), // input m_axi_awvalid
        .m_axi_awready  (m_axi_awready [( 1*(i+1))-1 :  1*i]), // output m_axi_awready
        .m_axi_awlock   (m_axi_awlock  [( 1*(i+1))-1 :  1*i]),
        .m_axi_awcache  (m_axi_awcache [( 4*(i+1))-1 :  4*i]),
        .m_axi_awprot   (m_axi_awprot  [( 3*(i+1))-1 :  3*i]),
        .m_axi_awqos    (m_axi_awqos   [( 4*(i+1))-1 :  4*i]),
        .m_axi_awregion (m_axi_awregion[( 4*(i+1))-1 :  4*i]),
        .m_axi_awuser   (m_axi_awuser  [( 1*(i+1))-1 :  1*i]),
        
        // Write Data
        .m_axi_wdata  (m_axi_wdata [(64*(i+1))-1 : 64*i]), // input [63 : 0] m_axi_wdata
        .m_axi_wstrb  (m_axi_wstrb [( 8*(i+1))-1 :  8*i]), // input [7 : 0] m_axi_wstrb
        .m_axi_wlast  (m_axi_wlast [( 1*(i+1))-1 :  1*i]), // input m_axi_wlast
        .m_axi_wvalid (m_axi_wvalid[( 1*(i+1))-1 :  1*i]), // input m_axi_wvalid
        .m_axi_wready (m_axi_wready[( 1*(i+1))-1 :  1*i]), // output m_axi_wready
        .m_axi_wuser  (m_axi_wuser [( 1*(i+1))-1 :  1*i]), // output m_axi_wuser
        
        // Write Response
        .m_axi_bid    (m_axi_bid   [( 1*(i+1))-1 : 1*i]), // output [0 : 0] m_axi_bid
        .m_axi_bresp  (m_axi_bresp [( 2*(i+1))-1 : 2*i]), // output [1 : 0] m_axi_bresp
        .m_axi_bvalid (m_axi_bvalid[( 1*(i+1))-1 : 1*i]), // output m_axi_bvalid
        .m_axi_bready (m_axi_bready[( 1*(i+1))-1 : 1*i]), // input m_axi_bready
        .m_axi_buser  (),
        
        // Read Control
        .m_axi_arid     (m_axi_arid    [( 1*(i+1))-1 :  1*i]), // input [0 : 0] m_axi_arid
        .m_axi_araddr   (m_axi_araddr  [(32*(i+1))-1 : 32*i]), // input [31 : 0] m_axi_araddr
        .m_axi_arlen    (m_axi_arlen   [( 8*(i+1))-1 :  8*i]), // input [7 : 0] m_axi_arlen
        .m_axi_arsize   (m_axi_arsize  [( 3*(i+1))-1 :  3*i]), // input [2 : 0] m_axi_arsize
        .m_axi_arburst  (m_axi_arburst [( 2*(i+1))-1 :  2*i]), // input [1 : 0] m_axi_arburst
        .m_axi_arvalid  (m_axi_arvalid [( 1*(i+1))-1 :  1*i]), // input m_axi_arvalid
        .m_axi_arready  (m_axi_arready [( 1*(i+1))-1 :  1*i]), // output m_axi_arready
        .m_axi_arlock   (m_axi_arlock  [( 1*(i+1))-1 :  1*i]),
        .m_axi_arcache  (m_axi_arcache [( 4*(i+1))-1 :  4*i]),
        .m_axi_arprot   (m_axi_arprot  [( 3*(i+1))-1 :  3*i]),
        .m_axi_arqos    (m_axi_arqos   [( 4*(i+1))-1 :  4*i]),
        .m_axi_arregion (m_axi_arregion[( 4*(i+1))-1 :  4*i]),
        .m_axi_aruser   (m_axi_aruser  [( 1*(i+1))-1 :  1*i]),
        
        // Read Data
        .m_axi_rid    (m_axi_rid   [( 1*(i+1))-1 :  1*i]), // output [0 : 0] m_axi_rid
        .m_axi_rdata  (m_axi_rdata [(64*(i+1))-1 : 64*i]), // output [63 : 0] m_axi_rdata
        .m_axi_rresp  (m_axi_rresp [( 2*(i+1))-1 :  2*i]), // output [1 : 0] m_axi_rresp
        .m_axi_rlast  (m_axi_rlast [( 1*(i+1))-1 :  1*i]), // output m_axi_rlast
        .m_axi_rvalid (m_axi_rvalid[( 1*(i+1))-1 :  1*i]), // output m_axi_rvalid
        .m_axi_rready (m_axi_rready[( 1*(i+1))-1 :  1*i]), // input m_axi_rready
        .m_axi_ruser  (),
        
        //
        // DMA interface for Write transactions
        //

        // Byte address for start of write transaction (64-bit aligned)
        .write_addr ({{(32-MEM_ADDR_W){1'b0}}, write_addr[( MEM_ADDR_W*(i+1))-1 : MEM_ADDR_W*i]}),
        
        // Count of 64-bit words to write, minus 1
        .write_count      (write_count     [( MEM_COUNT_W*(i+1))-1 : MEM_COUNT_W*i]),
        .write_ctrl_valid (write_ctrl_valid[(           1*(i+1))-1 :      1*i]),
        .write_ctrl_ready (write_ctrl_ready[(           1*(i+1))-1 :      1*i]),
        .write_data       (write_data      [(  MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .write_data_valid (write_data_valid[(           1*(i+1))-1 :      1*i]),
        .write_data_ready (write_data_ready[(           1*(i+1))-1 :      1*i]),
        
        //
        // DMA interface for Read transactions
        //

        // Byte address for start of read transaction (64-bit aligned)
        .read_addr ({{(32-MEM_ADDR_W){1'b0}}, read_addr[( MEM_ADDR_W*(i+1))-1 : MEM_ADDR_W*i]}),
        
        // Count of 64-bit words to read, minus 1
        .read_count      (read_count     [( MEM_COUNT_W*(i+1))-1 : MEM_COUNT_W*i]),
        
        .read_ctrl_valid (read_ctrl_valid[(          1*(i+1))-1 :      1*i]),
        .read_ctrl_ready (read_ctrl_ready[(          1*(i+1))-1 :      1*i]),
        .read_data       (read_data      [( MEM_DATA_W*(i+1))-1 : MEM_DATA_W*i]),
        .read_data_valid (read_data_valid[(          1*(i+1))-1 :      1*i]),
        .read_data_ready (read_data_ready[(          1*(i+1))-1 :      1*i]),
        
        //
        // Debug
        //
        .debug ()
      );

    end
  endgenerate

endmodule


`default_nettype wire
