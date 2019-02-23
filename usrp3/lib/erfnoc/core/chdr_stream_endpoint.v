//
// Copyright 2018-2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_stream_endpoint
// Description:
//   The implementation of a stream endpoint. This module serves as
//   an endpoint for a bidirectional stream. It implement a control
//   and a data path, both of which can be individually enabled using
//   parameters. The control path contains a bidirectional CHDR to 
//   AXIS-Control converter. The data path has a stream input and
//   output port.
//
// Parameters:
//   - PROTOVER: RFNoC protocol version {8'd<major>, 8'd<minor>}
//   - CHDR_W: Width of the CHDR bus in bits
//   - AXIS_CTRL_EN: Enable control traffic (axis_ctrl port)
//   - AXIS_DATA_EN: Enable data traffic (axis_data port)
//   - INST_NUM: The instance number of this module
//   - CTRL_XBAR_PORT: The port index on the control crossbar that
//                     this module's control path will connect to
//   - INGRESS_BUFF_SIZE: Buffer size in log2 of the number of words
//                        in the ingress buffer for the stream
//   - REPORT_STRM_ERRS: Report data stream errors upstream
//
// Signals:
//   - *_axis_chdr_* : Input/output CHDR stream (AXI-Stream)
//   - *_axis_ctrl_* : Input/output AXIS-Control stream (AXI-Stream)
//   - *_axis_data_* : Input/output CHDR Data stream (AXI-Stream)
//   - strm_*_err_stb: The stream encountered an error
//   - signal_*_err  : Notify upstream that we encountered an error

module chdr_stream_endpoint #(
  parameter [15:0] PROTOVER          = {8'd1, 8'd0},
  parameter        CHDR_W            = 64,
  parameter [0:0]  AXIS_CTRL_EN      = 1,
  parameter [0:0]  AXIS_DATA_EN      = 1,
  parameter [9:0]  INST_NUM          = 0,
  parameter [9:0]  CTRL_XBAR_PORT    = 0,
  parameter        INGRESS_BUFF_SIZE = 12,
  parameter        MTU               = 10,
  parameter [0:0]  REPORT_STRM_ERRS  = 1
)(
  // Clock, reset and settings
  input  wire              rfnoc_chdr_clk,
  input  wire              rfnoc_chdr_rst,
  input  wire              rfnoc_ctrl_clk,
  input  wire              rfnoc_ctrl_rst,
  // CHDR in (AXI-Stream)
  input  wire [CHDR_W-1:0] s_axis_chdr_tdata,
  input  wire              s_axis_chdr_tlast,
  input  wire              s_axis_chdr_tvalid,
  output wire              s_axis_chdr_tready,
  // CHDR out (AXI-Stream)             
  output wire [CHDR_W-1:0] m_axis_chdr_tdata,
  output wire              m_axis_chdr_tlast,
  output wire              m_axis_chdr_tvalid,
  input  wire              m_axis_chdr_tready,
  // Flow controlled data in (AXI-Stream)
  input  wire [CHDR_W-1:0] s_axis_data_tdata,
  input  wire              s_axis_data_tlast,
  input  wire              s_axis_data_tvalid,
  output wire              s_axis_data_tready,
  // Flow controlled data out (AXI-Stream)
  output wire [CHDR_W-1:0] m_axis_data_tdata,
  output wire              m_axis_data_tlast,
  output wire              m_axis_data_tvalid,
  input  wire              m_axis_data_tready,
  // Control in (AXI-Stream)
  input  wire [31:0]       s_axis_ctrl_tdata,
  input  wire              s_axis_ctrl_tlast,
  input  wire              s_axis_ctrl_tvalid,
  output wire              s_axis_ctrl_tready,
  // Control out (AXI-Stream)
  output wire [31:0]       m_axis_ctrl_tdata,
  output wire              m_axis_ctrl_tlast,
  output wire              m_axis_ctrl_tvalid,
  input  wire              m_axis_ctrl_tready,
  // Stream status specfic
  output wire              strm_seq_err_stb,
  output wire              strm_data_err_stb,
  output wire              strm_route_err_stb,
  input  wire              signal_data_err
);

  // ---------------------------------------------------
  //  RFNoC Includes
  // ---------------------------------------------------
  `include "rfnoc_chdr_utils.vh"
  `include "rfnoc_chdr_internal_utils.vh"

  // ---------------------------------------------------
  //  Filter packets by type 
  // ---------------------------------------------------
  wire [CHDR_W-1:0] chdr_i_tdata, chdr_i_header;
  wire              chdr_i_tlast, chdr_i_tvalid, chdr_i_tready;

  wire              ctrlport_req_wr, ctrlport_req_rd;
  reg               ctrlport_resp_ack = 1'b0;
  wire [15:0]       ctrlport_req_addr;
  wire [31:0]       ctrlport_req_data;
  reg  [31:0]       ctrlport_resp_data;

  // Handle management packets here
  chdr_mgmt_pkt_handler #(
    .PROTOVER(PROTOVER), .CHDR_W(CHDR_W),
    .NODE_INFO(chdr_mgmt_build_node_info(0,1,INST_NUM,NODE_TYPE_STREAM_EP))
  ) mgmt_ep_i (
    .clk(rfnoc_chdr_clk), .rst(rfnoc_chdr_rst),
    .s_axis_chdr_tdata(s_axis_chdr_tdata), .s_axis_chdr_tlast(s_axis_chdr_tlast),
    .s_axis_chdr_tvalid(s_axis_chdr_tvalid), .s_axis_chdr_tready(s_axis_chdr_tready),
    .m_axis_chdr_tdata(chdr_i_tdata), .m_axis_chdr_tlast(chdr_i_tlast),
    .m_axis_chdr_tdest(/* unused */), .m_axis_chdr_tid(/* unused */),
    .m_axis_chdr_tvalid(chdr_i_tvalid), .m_axis_chdr_tready(chdr_i_tready),
    .ctrlport_req_wr(ctrlport_req_wr), .ctrlport_req_rd(ctrlport_req_rd),
    .ctrlport_req_addr(ctrlport_req_addr), .ctrlport_req_data(ctrlport_req_data),
    .ctrlport_resp_ack(ctrlport_resp_ack), .ctrlport_resp_data(ctrlport_resp_data),
    .op_stb(/* unused */), .op_dst_epid(/* unused */), .op_src_epid(/* unused */)
  );

  wire [CHDR_W-1:0] ctrl_i_tdata,  ctrl_o_tdata;
  wire              ctrl_i_tlast,  ctrl_o_tlast;
  wire              ctrl_i_tvalid, ctrl_o_tvalid;
  wire              ctrl_i_tready, ctrl_o_tready;

  wire [CHDR_W-1:0] data_i_tdata,  data_o_tdata;
  wire              data_i_tlast,  data_o_tlast;
  wire              data_i_tvalid, data_o_tvalid;
  wire              data_i_tready, data_o_tready;

  wire [CHDR_W-1:0] strs_i_tdata,  strs_o_tdata;
  wire              strs_i_tlast,  strs_o_tlast;
  wire              strs_i_tvalid, strs_o_tvalid;
  wire              strs_i_tready, strs_o_tready;

  wire [CHDR_W-1:0] mgmt_loopback_tdata;
  wire              mgmt_loopback_tlast;
  wire              mgmt_loopback_tvalid;
  wire              mgmt_loopback_tready;

  function [1:0] compute_demux_dest;
    input [63:0] hdr;
    if (chdr_get_pkt_type(hdr) == CHDR_PKT_TYPE_CTRL)
      // Control
      compute_demux_dest = 2'd2;
    else if (chdr_get_pkt_type(hdr) == CHDR_PKT_TYPE_STRC ||
             chdr_get_pkt_type(hdr) == CHDR_PKT_TYPE_DATA ||
             chdr_get_pkt_type(hdr) == CHDR_PKT_TYPE_DATA_TS)
      // Data and stream command
      compute_demux_dest = 2'd1;
    else if (chdr_get_pkt_type(hdr) == CHDR_PKT_TYPE_STRS)
      // Stream status
      compute_demux_dest = 2'd0;
    else
      // Management (all packets must return to sender)
      compute_demux_dest = 2'd3;
  endfunction

  axi_demux #(
    .WIDTH(CHDR_W), .SIZE(4), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0)
  ) mgmt_demux_i (
    .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst), .clear(1'b0),
    .header(chdr_i_header), .dest(compute_demux_dest(chdr_i_header[63:0])),
    .i_tdata (chdr_i_tdata ),
    .i_tlast (chdr_i_tlast ),
    .i_tvalid(chdr_i_tvalid),
    .i_tready(chdr_i_tready),
    .o_tdata ({mgmt_loopback_tdata,  ctrl_i_tdata,  data_i_tdata,  strs_i_tdata }),
    .o_tlast ({mgmt_loopback_tlast,  ctrl_i_tlast,  data_i_tlast,  strs_i_tlast }),
    .o_tvalid({mgmt_loopback_tvalid, ctrl_i_tvalid, data_i_tvalid, strs_i_tvalid}),
    .o_tready({mgmt_loopback_tready, ctrl_i_tready, data_i_tready, strs_i_tready})
  );

  axi_mux #(
    .WIDTH(CHDR_W), .SIZE(4), .PRIO(1), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1)
  ) mgmt_mux_i (
    .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst), .clear(1'b0),
    .i_tdata ({mgmt_loopback_tdata,  data_o_tdata,  strs_o_tdata,  ctrl_o_tdata }),
    .i_tlast ({mgmt_loopback_tlast,  data_o_tlast,  strs_o_tlast,  ctrl_o_tlast }),
    .i_tvalid({mgmt_loopback_tvalid, data_o_tvalid, strs_o_tvalid, ctrl_o_tvalid}),
    .i_tready({mgmt_loopback_tready, data_o_tready, strs_o_tready, ctrl_o_tready}),
    .o_tdata (m_axis_chdr_tdata ),
    .o_tlast (m_axis_chdr_tlast ),
    .o_tvalid(m_axis_chdr_tvalid),
    .o_tready(m_axis_chdr_tready)
  );

  // ============================== REGISTERS ============================== 
  // * REG_EPID_SELF (Read-Write):
  //   The endpoint ID of this stream endpoint
  //   - [15:0]: Endpoint ID
  // * REG_RESET_AND_FLUSH (Write-Only):
  //   Reset and flush register
  //   - [0]: Flush data path
  //   - [1]: Flush control path
  // * REG_OSTRM_CTRL_STATUS (Read-Write):
  //   Control and status register
  //   - [0]: Configuration start (strobe)
  //   - [1]: Is this transport lossy?
  // * REG_OSTRM_DST_EPID (Write-Only):
  //   The endpoint ID of a downstream stream endpoint
  //   - [15:0]: Endpoint ID
  // * REG_OSTRM_FC_FREQ_BYTES_LO, REG_OSTRM_FC_FREQ_BYTES_HI (Write-Only):
  //   Number of bytes between flow control status messages
  // * REG_OSTRM_FC_FREQ_PKTS (Write-Only):
  //   Number of packets between flow control status messages
  // * REG_OSTRM_FC_HEADROOM (Write-Only):
  //   Flow control headroom register
  //   - [15:0]: Bytes of headroom
  //   - [23:16]: Packets of headroom
  // * REG_OSTRM_BUFF_CAP_BYTES_LO, REG_OSTRM_BUFF_CAP_BYTES_HI (Read-Only):
  //   Number of bytes in the downstream buffer
  // * REG_OSTRM_BUFF_CAP_PKTS_LO, REG_OSTRM_BUFF_CAP_PKTS_HI (Read-Only):
  //   Number of packets in the downstream buffer
  // * REG_OSTRM_SEQ_ERR_CNT (Read-Only):
  //   Number of sequence errors since initialization
  // * REG_OSTRM_DATA_ERR_CNT (Read-Only):
  //   Number of data integrity errors since initialization
  // * REG_OSTRM_ROUTE_ERR_CNT (Read-Only):
  //   Number of routing errors since initialization
  // ======================================================================= 

  localparam [15:0] REG_EPID_SELF               = 16'h00;   //RW
  localparam [15:0] REG_RESET_AND_FLUSH         = 16'h04;   //W
  localparam [15:0] REG_OSTRM_CTRL_STATUS       = 16'h08;   //RW
  localparam [15:0] REG_OSTRM_DST_EPID          = 16'h0C;   //W
  localparam [15:0] REG_OSTRM_FC_FREQ_BYTES_LO  = 16'h10;   //W
  localparam [15:0] REG_OSTRM_FC_FREQ_BYTES_HI  = 16'h14;   //W
  localparam [15:0] REG_OSTRM_FC_FREQ_PKTS      = 16'h18;   //W
  localparam [15:0] REG_OSTRM_FC_HEADROOM       = 16'h1C;   //W
  localparam [15:0] REG_OSTRM_BUFF_CAP_BYTES_LO = 16'h20;   //R
  localparam [15:0] REG_OSTRM_BUFF_CAP_BYTES_HI = 16'h24;   //R
  localparam [15:0] REG_OSTRM_BUFF_CAP_PKTS_LO  = 16'h28;   //R
  localparam [15:0] REG_OSTRM_BUFF_CAP_PKTS_HI  = 16'h2C;   //R
  localparam [15:0] REG_OSTRM_SEQ_ERR_CNT       = 16'h30;   //R
  localparam [15:0] REG_OSTRM_DATA_ERR_CNT      = 16'h34;   //R
  localparam [15:0] REG_OSTRM_ROUTE_ERR_CNT     = 16'h38;   //R

  // Configurable registers
  reg  [15:0] reg_epid_self          = 16'h0;
  reg         reg_ctrlpath_reset     = 1'b0;
  reg         reg_datapath_reset     = 1'b0;
  reg         reg_ostrm_cfg_start    = 1'b0;
  wire        reg_ostrm_cfg_pending;
  wire        reg_ostrm_cfg_failed;
  reg         reg_ostrm_cfg_lossy_xport = 1'b0;
  reg  [15:0] reg_ostrm_dst_epid     = 16'h0;
  reg  [39:0] reg_fc_freq_bytes      = 40'h0;
  reg  [23:0] reg_fc_freq_pkts       = 24'h0;
  reg  [15:0] reg_fc_headroom_bytes  = 16'd0;
  reg  [7:0]  reg_fc_headroom_pkts   = 8'd0;
  wire        reg_fc_enabled;
  wire [63:0] reg_buff_cap_bytes;
  wire [39:0] reg_buff_cap_pkts;
  wire [31:0] reg_seq_err_cnt;
  wire [31:0] reg_data_err_cnt;
  wire [31:0] reg_route_err_cnt;

  always @(posedge rfnoc_chdr_clk) begin
    if (rfnoc_chdr_rst) begin
      ctrlport_resp_ack <= 1'b0;
    end else begin
      // All transactions finish in 1 cycle
      ctrlport_resp_ack <= ctrlport_req_wr | ctrlport_req_rd;
      // Handle register writes
      if (ctrlport_req_wr) begin
        case(ctrlport_req_addr)
          REG_EPID_SELF:
            reg_epid_self <= ctrlport_req_data[15:0];
          REG_RESET_AND_FLUSH:
            {reg_ctrlpath_reset, reg_datapath_reset} <= ctrlport_req_data[1:0];
          REG_OSTRM_CTRL_STATUS:
            {reg_ostrm_cfg_lossy_xport, reg_ostrm_cfg_start} <= ctrlport_req_data[1:0];
          REG_OSTRM_DST_EPID:
            reg_ostrm_dst_epid <= ctrlport_req_data[15:0];
          REG_OSTRM_FC_FREQ_BYTES_LO:
            reg_fc_freq_bytes[31:0] <= ctrlport_req_data[31:0];
          REG_OSTRM_FC_FREQ_BYTES_HI:
            reg_fc_freq_bytes[39:32] <= ctrlport_req_data[7:0];
          REG_OSTRM_FC_FREQ_PKTS:
            reg_fc_freq_pkts <= ctrlport_req_data[23:0];
          REG_OSTRM_FC_HEADROOM:
            {reg_fc_headroom_pkts, reg_fc_headroom_bytes} <= ctrlport_req_data[23:0];
        endcase
      end else begin
        // Strobed registers
        reg_ostrm_cfg_start <= 1'b0;
        reg_ctrlpath_reset  <= 1'b0;
        reg_datapath_reset  <= 1'b0;
      end
      // Handle register reads
      if (ctrlport_req_rd) begin
        case(ctrlport_req_addr)
          REG_EPID_SELF:
            ctrlport_resp_data <= {16'h0, reg_epid_self};
          REG_OSTRM_CTRL_STATUS:
            ctrlport_resp_data <= {
              reg_fc_enabled, reg_ostrm_cfg_failed, reg_ostrm_cfg_pending, 1'b0,
              26'h0, reg_ostrm_cfg_lossy_xport, 1'b0};
          REG_OSTRM_BUFF_CAP_BYTES_LO:
            ctrlport_resp_data <= reg_buff_cap_bytes[31:0];
          REG_OSTRM_BUFF_CAP_BYTES_HI:
            ctrlport_resp_data <= reg_buff_cap_bytes[63:32];
          REG_OSTRM_BUFF_CAP_PKTS_LO:
            ctrlport_resp_data <= reg_buff_cap_pkts[31:0];
          REG_OSTRM_BUFF_CAP_PKTS_HI:
            ctrlport_resp_data <= {24'h0, reg_buff_cap_pkts[39:32]};
          REG_OSTRM_SEQ_ERR_CNT:
            ctrlport_resp_data <= reg_seq_err_cnt;
          REG_OSTRM_DATA_ERR_CNT:
            ctrlport_resp_data <= reg_data_err_cnt;
          REG_OSTRM_ROUTE_ERR_CNT:
            ctrlport_resp_data <= reg_route_err_cnt;
          default:
            ctrlport_resp_data <= 32'h0;
        endcase
      end
    end
  end

  // ---------------------------------------------------
  //  Data and Flow Control Path 
  // ---------------------------------------------------
  generate if (AXIS_DATA_EN) begin
    localparam INPUT_FLUSH_TIMEOUT_W = 14;

    wire [CHDR_W-1:0] axis_data_i_tdata,  axis_data_o_tdata;
    wire              axis_data_i_tlast,  axis_data_o_tlast;
    wire              axis_data_i_tvalid, axis_data_o_tvalid;
    wire              axis_data_i_tready, axis_data_o_tready;
  
    chdr_stream_input #(
      .CHDR_W(CHDR_W), .BUFF_SIZE(INGRESS_BUFF_SIZE),
      .FLUSH_TIMEOUT_W(INPUT_FLUSH_TIMEOUT_W),
      .MONITOR_EN(0), .SIGNAL_ERRS(REPORT_STRM_ERRS)
    ) strm_input_i (
      .clk                  (rfnoc_chdr_clk),
      .rst                  (rfnoc_chdr_rst | reg_datapath_reset),
      .s_axis_chdr_tdata    (data_i_tdata),
      .s_axis_chdr_tlast    (data_i_tlast),
      .s_axis_chdr_tvalid   (data_i_tvalid),
      .s_axis_chdr_tready   (data_i_tready),
      .m_axis_data_tdata    (axis_data_o_tdata),
      .m_axis_data_tlast    (axis_data_o_tlast),
      .m_axis_data_tvalid   (axis_data_o_tvalid),
      .m_axis_data_tready   (axis_data_o_tready),
      .m_axis_strs_tdata    (strs_o_tdata),
      .m_axis_strs_tlast    (strs_o_tlast),
      .m_axis_strs_tvalid   (strs_o_tvalid),
      .m_axis_strs_tready   (strs_o_tready),
      .data_err_stb         (signal_data_err)
    );

    chdr_stream_output #(
      .CHDR_W(CHDR_W), .MTU(MTU)
    ) strm_output_i (
      .clk                  (rfnoc_chdr_clk),
      .rst                  (rfnoc_chdr_rst | reg_datapath_reset),
      .m_axis_chdr_tdata    (data_o_tdata),
      .m_axis_chdr_tlast    (data_o_tlast),
      .m_axis_chdr_tvalid   (data_o_tvalid),
      .m_axis_chdr_tready   (data_o_tready),
      .s_axis_data_tdata    (axis_data_i_tdata),
      .s_axis_data_tlast    (axis_data_i_tlast),
      .s_axis_data_tvalid   (axis_data_i_tvalid),
      .s_axis_data_tready   (axis_data_i_tready),
      .s_axis_strs_tdata    (strs_i_tdata),
      .s_axis_strs_tlast    (strs_i_tlast),
      .s_axis_strs_tvalid   (strs_i_tvalid),
      .s_axis_strs_tready   (strs_i_tready),
      .cfg_start            (reg_ostrm_cfg_start),
      .cfg_pending          (reg_ostrm_cfg_pending),
      .cfg_failed           (reg_ostrm_cfg_failed),
      .cfg_lossy_xport      (reg_ostrm_cfg_lossy_xport),
      .cfg_dst_epid         (reg_ostrm_dst_epid),
      .cfg_this_epid        (reg_epid_self),
      .cfg_fc_freq_bytes    (reg_fc_freq_bytes),
      .cfg_fc_freq_pkts     (reg_fc_freq_pkts),
      .cfg_fc_headroom_bytes(reg_fc_headroom_bytes),
      .cfg_fc_headroom_pkts (reg_fc_headroom_pkts),
      .fc_enabled           (reg_fc_enabled),
      .capacity_bytes       (reg_buff_cap_bytes),
      .capacity_pkts        (reg_buff_cap_pkts),
      .seq_err_stb          (strm_seq_err_stb),
      .seq_err_cnt          (reg_seq_err_cnt),
      .data_err_stb         (strm_data_err_stb),
      .data_err_cnt         (reg_data_err_cnt),
      .route_err_stb        (strm_route_err_stb),
      .route_err_cnt        (reg_route_err_cnt)
    );

    axi_fifo #(.WIDTH(CHDR_W+1), .SIZE(1)) axis_m_reg_i (
      .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst | reg_datapath_reset), .clear(1'b0),
      .i_tdata({axis_data_o_tlast, axis_data_o_tdata}),
      .i_tvalid(axis_data_o_tvalid), .i_tready(axis_data_o_tready),
      .o_tdata({m_axis_data_tlast, m_axis_data_tdata}),
      .o_tvalid(m_axis_data_tvalid), .o_tready(m_axis_data_tready),
      .space(), .occupied()
    );
  
    axi_fifo #(.WIDTH(CHDR_W+1), .SIZE(1)) axis_s_reg_i (
      .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst | reg_datapath_reset), .clear(1'b0),
      .i_tdata({s_axis_data_tlast, s_axis_data_tdata}),
      .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
      .o_tdata({axis_data_i_tlast, axis_data_i_tdata}),
      .o_tvalid(axis_data_i_tvalid), .o_tready(axis_data_i_tready),
      .space(), .occupied()
    );
  end else begin    // if (AXIS_DATA_EN)
    assign data_i_tready = 1'b1;
    assign data_o_tdata  = {CHDR_W{1'b0}};
    assign data_o_tlast  = 1'b0;
    assign data_o_tvalid = 1'b0;

    assign strs_i_tready = 1'b1;
    assign strs_o_tdata  = {CHDR_W{1'b0}};
    assign strs_o_tlast  = 1'b0;
    assign strs_o_tvalid = 1'b0;

    assign s_axis_data_tready = 1'b1;
    assign m_axis_data_tdata  = {CHDR_W{1'b0}};
    assign m_axis_data_tlast  = 1'b0;
    assign m_axis_data_tvalid = 1'b0;
  end endgenerate

  // ---------------------------------------------------
  //  Control Path 
  // ---------------------------------------------------
  generate if (AXIS_CTRL_EN) begin
    // Convert from a CHDR control packet to an AXIS control packet
    chdr_to_axis_ctrl #(
      .CHDR_W(CHDR_W), .THIS_PORTID(CTRL_XBAR_PORT)
    ) chdr_ctrl_adapter_i (
      .rfnoc_chdr_clk     (rfnoc_chdr_clk),
      .rfnoc_chdr_rst     (rfnoc_chdr_rst | reg_ctrlpath_reset),
      .this_epid          (reg_epid_self),
      .s_rfnoc_chdr_tdata (ctrl_i_tdata),
      .s_rfnoc_chdr_tlast (ctrl_i_tlast),
      .s_rfnoc_chdr_tvalid(ctrl_i_tvalid),
      .s_rfnoc_chdr_tready(ctrl_i_tready),
      .m_rfnoc_chdr_tdata (ctrl_o_tdata),
      .m_rfnoc_chdr_tlast (ctrl_o_tlast),
      .m_rfnoc_chdr_tvalid(ctrl_o_tvalid),
      .m_rfnoc_chdr_tready(ctrl_o_tready),
      .rfnoc_ctrl_clk     (rfnoc_ctrl_clk),
      .rfnoc_ctrl_rst     (rfnoc_ctrl_rst),
      .s_rfnoc_ctrl_tdata (s_axis_ctrl_tdata),
      .s_rfnoc_ctrl_tlast (s_axis_ctrl_tlast),
      .s_rfnoc_ctrl_tvalid(s_axis_ctrl_tvalid),
      .s_rfnoc_ctrl_tready(s_axis_ctrl_tready),
      .m_rfnoc_ctrl_tdata (m_axis_ctrl_tdata),
      .m_rfnoc_ctrl_tlast (m_axis_ctrl_tlast),
      .m_rfnoc_ctrl_tvalid(m_axis_ctrl_tvalid),
      .m_rfnoc_ctrl_tready(m_axis_ctrl_tready)
    );
  end else begin    // if (AXIS_CTRL_EN)
    assign ctrl_i_tready = 1'b1;
    assign ctrl_o_tdata  = {CHDR_W{1'b0}};
    assign ctrl_o_tlast  = 1'b0;
    assign ctrl_o_tvalid = 1'b0;

    assign s_axis_ctrl_tready = 1'b1;
    assign m_axis_ctrl_tdata  = 32'h0;
    assign m_axis_ctrl_tlast  = 1'b0;
    assign m_axis_ctrl_tvalid = 1'b0;
  end endgenerate

endmodule // chdr_stream_endpoint

