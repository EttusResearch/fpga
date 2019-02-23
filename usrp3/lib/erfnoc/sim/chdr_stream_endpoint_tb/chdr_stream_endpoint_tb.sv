//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_stream_endpoint_tb
//

`default_nettype none

import PkgTestExec::*;
import PkgChdrUtils::*;
import PkgChdrBfm::*;

module chdr_stream_endpoint_tb;

  // ----------------------------------------
  // Global settings
  // ----------------------------------------
  // Simulation Timing
  timeunit 1ns;
  timeprecision 1ps;

  // Clocks and resets
  bit rfnoc_chdr_clk, rfnoc_chdr_rst;
  bit rfnoc_ctrl_clk, rfnoc_ctrl_rst;
  sim_clock_gen #(6.0)  rfnoc_chdr_clk_gen (rfnoc_chdr_clk, rfnoc_chdr_rst); // 166.6 MHz
  sim_clock_gen #(20.0) rfnoc_ctrl_clk_gen (rfnoc_ctrl_clk, rfnoc_ctrl_rst); // 50 MHz

  // Parameters
  localparam bit     VERBOSE           = 0;
  localparam integer NUM_PKTS_PER_TEST = 100;
  localparam integer FAST_STALL_PROB   = 0;
  localparam integer SLOW_STALL_PROB   = 33;

  localparam integer CHDR_W   = 64;
  localparam integer MTU      = 7;
  localparam [15:0]  PROTOVER = {8'd1, 8'd0};
  localparam [15:0]  EPID_TB  = 16'h1001;
  localparam [15:0]  EPID_A   = 16'h1002;
  localparam [15:0]  EPID_B   = 16'h1003;
  localparam [9:0]   PORT_TB  = 10'd0;
  localparam [9:0]   PORT_A   = 10'd1;
  localparam [9:0]   PORT_B   = 10'd2;

  // ----------------------------------------
  // DUT (and Crossbar) Instantiations
  // ----------------------------------------
  wire [CHDR_W-1:0] c2a_chdr_tdata , a2c_chdr_tdata ;
  wire              c2a_chdr_tlast , a2c_chdr_tlast ;
  wire              c2a_chdr_tvalid, a2c_chdr_tvalid;
  wire              c2a_chdr_tready, a2c_chdr_tready;
  wire [CHDR_W-1:0] c2b_chdr_tdata , b2c_chdr_tdata ;
  wire              c2b_chdr_tlast , b2c_chdr_tlast ;
  wire              c2b_chdr_tvalid, b2c_chdr_tvalid;
  wire              c2b_chdr_tready, b2c_chdr_tready;

  wire [31:0] a_ctrl_in_tdata, a_ctrl_out_tdata, b_ctrl_in_tdata, b_ctrl_out_tdata;
  wire        a_ctrl_loop_tlast , b_ctrl_loop_tlast ;
  wire        a_ctrl_loop_tvalid, b_ctrl_loop_tvalid;
  wire        a_ctrl_loop_tready, b_ctrl_loop_tready;

  AxiStreamIf #(CHDR_W) m_tb_chdr (rfnoc_chdr_clk, rfnoc_chdr_rst);
  AxiStreamIf #(CHDR_W) s_tb_chdr (rfnoc_chdr_clk, rfnoc_chdr_rst);

  AxiStreamIf #(CHDR_W) m_a_data  (rfnoc_chdr_clk, rfnoc_chdr_rst);
  AxiStreamIf #(CHDR_W) s_a_data  (rfnoc_chdr_clk, rfnoc_chdr_rst);
  AxiStreamIf #(CHDR_W) m_b_data  (rfnoc_chdr_clk, rfnoc_chdr_rst);
  AxiStreamIf #(CHDR_W) s_b_data  (rfnoc_chdr_clk, rfnoc_chdr_rst);

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (1),
    .AXIS_DATA_EN       (1),
    .INST_NUM           (0),
    .CTRL_XBAR_PORT     (PORT_A),
    .INGRESS_BUFF_SIZE  (MTU+1),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1),
    .SIM_SPEEDUP        (1)
  ) sep_a (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk        ),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst        ),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk        ),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst        ),
    .s_axis_chdr_tdata  (c2a_chdr_tdata        ),
    .s_axis_chdr_tlast  (c2a_chdr_tlast        ),
    .s_axis_chdr_tvalid (c2a_chdr_tvalid       ),
    .s_axis_chdr_tready (c2a_chdr_tready       ),
    .m_axis_chdr_tdata  (a2c_chdr_tdata        ),
    .m_axis_chdr_tlast  (a2c_chdr_tlast        ),
    .m_axis_chdr_tvalid (a2c_chdr_tvalid       ),
    .m_axis_chdr_tready (a2c_chdr_tready       ),
    .s_axis_data_tdata  (m_a_data.slave.tdata  ),
    .s_axis_data_tlast  (m_a_data.slave.tlast  ),
    .s_axis_data_tvalid (m_a_data.slave.tvalid ),
    .s_axis_data_tready (m_a_data.slave.tready ),
    .m_axis_data_tdata  (s_a_data.master.tdata ),
    .m_axis_data_tlast  (s_a_data.master.tlast ),
    .m_axis_data_tvalid (s_a_data.master.tvalid),
    .m_axis_data_tready (s_a_data.master.tready),
    .s_axis_ctrl_tdata  (a_ctrl_out_tdata      ),
    .s_axis_ctrl_tlast  (a_ctrl_loop_tlast     ),
    .s_axis_ctrl_tvalid (a_ctrl_loop_tvalid    ),
    .s_axis_ctrl_tready (a_ctrl_loop_tready    ),
    .m_axis_ctrl_tdata  (a_ctrl_in_tdata       ),
    .m_axis_ctrl_tlast  (a_ctrl_loop_tlast     ),
    .m_axis_ctrl_tvalid (a_ctrl_loop_tvalid    ),
    .m_axis_ctrl_tready (a_ctrl_loop_tready    ),
    .strm_seq_err_stb   (                      ),
    .strm_data_err_stb  (                      ),
    .strm_route_err_stb (                      ),
    .signal_data_err    (1'b0                  )
  );

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (1),
    .AXIS_DATA_EN       (1),
    .INST_NUM           (1),
    .CTRL_XBAR_PORT     (PORT_B),
    .INGRESS_BUFF_SIZE  (MTU+1),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1),
    .SIM_SPEEDUP        (1)
  ) sep_b (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk        ),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst        ),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk        ),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst        ),
    .s_axis_chdr_tdata  (c2b_chdr_tdata        ),
    .s_axis_chdr_tlast  (c2b_chdr_tlast        ),
    .s_axis_chdr_tvalid (c2b_chdr_tvalid       ),
    .s_axis_chdr_tready (c2b_chdr_tready       ),
    .m_axis_chdr_tdata  (b2c_chdr_tdata        ),
    .m_axis_chdr_tlast  (b2c_chdr_tlast        ),
    .m_axis_chdr_tvalid (b2c_chdr_tvalid       ),
    .m_axis_chdr_tready (b2c_chdr_tready       ),
    .s_axis_data_tdata  (m_b_data.slave.tdata  ),
    .s_axis_data_tlast  (m_b_data.slave.tlast  ),
    .s_axis_data_tvalid (m_b_data.slave.tvalid ),
    .s_axis_data_tready (m_b_data.slave.tready ),
    .m_axis_data_tdata  (s_b_data.master.tdata ),
    .m_axis_data_tlast  (s_b_data.master.tlast ),
    .m_axis_data_tvalid (s_b_data.master.tvalid),
    .m_axis_data_tready (s_b_data.master.tready),
    .s_axis_ctrl_tdata  (b_ctrl_out_tdata      ),
    .s_axis_ctrl_tlast  (b_ctrl_loop_tlast     ),
    .s_axis_ctrl_tvalid (b_ctrl_loop_tvalid    ),
    .s_axis_ctrl_tready (b_ctrl_loop_tready    ),
    .m_axis_ctrl_tdata  (b_ctrl_in_tdata       ),
    .m_axis_ctrl_tlast  (b_ctrl_loop_tlast     ),
    .m_axis_ctrl_tvalid (b_ctrl_loop_tvalid    ),
    .m_axis_ctrl_tready (b_ctrl_loop_tready    ),
    .strm_seq_err_stb   (                      ),
    .strm_data_err_stb  (                      ),
    .strm_route_err_stb (                      ),
    .signal_data_err    (1'b0                  )
  );

  chdr_crossbar_nxn #(
    .CHDR_W         (CHDR_W),
    .NPORTS         (3),
    .DEFAULT_PORT   (0),
    .MTU            (MTU),
    .ROUTE_TBL_SIZE (6),
    .MUX_ALLOC      ("ROUND-ROBIN"),
    .OPTIMIZE       ("AREA"),
    .MGMT_PORT_MASK (3'b001),
    .EXT_RTCFG_PORT (0),
    .PROTOVER       (PROTOVER)
  ) xbar_c (
    .clk            (rfnoc_chdr_clk),
    .reset          (rfnoc_chdr_rst),
    .s_axis_tdata   ({b2c_chdr_tdata,  a2c_chdr_tdata,  m_tb_chdr.slave.tdata  }),
    .s_axis_tlast   ({b2c_chdr_tlast,  a2c_chdr_tlast,  m_tb_chdr.slave.tlast  }),
    .s_axis_tvalid  ({b2c_chdr_tvalid, a2c_chdr_tvalid, m_tb_chdr.slave.tvalid }),
    .s_axis_tready  ({b2c_chdr_tready, a2c_chdr_tready, m_tb_chdr.slave.tready }),
    .m_axis_tdata   ({c2b_chdr_tdata,  c2a_chdr_tdata,  s_tb_chdr.master.tdata }),
    .m_axis_tlast   ({c2b_chdr_tlast,  c2a_chdr_tlast,  s_tb_chdr.master.tlast }),
    .m_axis_tvalid  ({c2b_chdr_tvalid, c2a_chdr_tvalid, s_tb_chdr.master.tvalid}),
    .m_axis_tready  ({c2b_chdr_tready, c2a_chdr_tready, s_tb_chdr.master.tready}),
    .ext_rtcfg_stb  ('0),
    .ext_rtcfg_addr ('0),
    .ext_rtcfg_data ('0),
    .ext_rtcfg_ack  ()
  );

  // ----------------------------------------
  // BFMs and Test Models
  // ----------------------------------------
  TestExec test;

  ChdrBfm #(CHDR_W) a_data_bfm = new(m_a_data, s_a_data);
  ChdrBfm #(CHDR_W) b_data_bfm = new(m_b_data, s_b_data);
  ChdrBfm #(CHDR_W) tb_chdr_bfm = new(m_tb_chdr, s_tb_chdr);

  // Simple responders for AXIS-Ctrl transactions
  reg a_first = 1'b1, b_first = 1'b1;
  always @(posedge rfnoc_ctrl_clk) begin
    if (rfnoc_ctrl_rst) begin
      a_first <= 1'd1;
      b_first <= 1'd1;
    end else begin
      if (a_ctrl_loop_tvalid & a_ctrl_loop_tready)
        a_first <= a_ctrl_loop_tlast;
      if (b_ctrl_loop_tvalid & b_ctrl_loop_tready)
        b_first <= b_ctrl_loop_tlast;
    end
  end
  // Respond with an ACK and the source and destination ports swapped
  assign a_ctrl_out_tdata = 
    a_first ? {1'b1, a_ctrl_in_tdata[30:20], a_ctrl_in_tdata[9:0], a_ctrl_in_tdata[19:10]} : a_ctrl_in_tdata;
  assign b_ctrl_out_tdata = 
    b_first ? {1'b1, b_ctrl_in_tdata[30:20], b_ctrl_in_tdata[9:0], b_ctrl_in_tdata[19:10]} : b_ctrl_in_tdata;

  // ----------------------------------------
  // Test Utilities
  // ----------------------------------------
  task send_recv_mgmt_packet(
    input  chdr_header_t tx_mgmt_hdr,
    input  chdr_mgmt_t   tx_mgmt_pl,
    output chdr_header_t rx_mgmt_hdr,
    output chdr_mgmt_t   rx_mgmt_pl
  );
    automatic timeout_t mgmt_timeout;
    automatic ChdrPacket #(CHDR_W) tx_chdr = new(), rx_chdr;
    tx_chdr.write_mgmt(tx_mgmt_hdr, tx_mgmt_pl);
    test.start_timeout(mgmt_timeout, 2us, "Waiting for management transaction");
    if (VERBOSE) begin $write("Tx"); tx_chdr.print(); end
    tb_chdr_bfm.put_chdr(tx_chdr.copy());
    tb_chdr_bfm.get_chdr(rx_chdr);
    test.end_timeout(mgmt_timeout);
    rx_chdr.read_mgmt(rx_mgmt_hdr, rx_mgmt_pl);
    if (VERBOSE) begin $write("Rx"); rx_chdr.print(); end
  endtask


  logic [5:0] cached_ctrl_seqnum = 0;
  task send_recv_ctrl_packets(
    input [15:0] dst_epid,
    input [15:0] num_pkts,
    input [15:0] seq_num_start
  );
    for (int n = 0; n < num_pkts; n=n+1) begin
      automatic timeout_t ctrl_timeout;
      automatic ChdrPacket #(CHDR_W) tx_chdr = new(), rx_chdr, exp_chdr = new();
      automatic chdr_header_t chdr_hdr;
      automatic chdr_ctrl_header_t ctrl_hdr, exp_ctrl_hdr;
      automatic ctrl_op_word_t ctrl_op;
      automatic ctrl_word_t ctrl_data[$];
      automatic chdr_word_t ctrl_ts;
  
      ctrl_data.delete();
      for (int i = 0; i < $urandom_range(15,1); i++)
        ctrl_data[i] = $urandom();
      ctrl_hdr = '{
        default  : '0,
        src_epid : EPID_TB,
        is_ack   : 1'b0,
        has_time : $urandom_range(1),
        seq_num  : cached_ctrl_seqnum++,
        num_data : ctrl_data.size(),
        src_port : $urandom(),
        dst_port : $urandom()
      };
      ctrl_ts = $urandom();
      ctrl_op = '{
        default      : '0,
        op_code      : ctrl_opcode_t'($urandom_range(9)),
        byte_enable  : $urandom_range(15),
        address      : $urandom()
      };
      chdr_hdr = '{
        dst_epid  : dst_epid,
        seq_num   : seq_num_start + n[15:0],
        pkt_type  : CHDR_CONTROL,
        default   : 0
      };
      tx_chdr.write_ctrl(chdr_hdr, ctrl_hdr, ctrl_op, ctrl_data, ctrl_ts);

      test.start_timeout(ctrl_timeout, 2us, "Waiting for management transaction");
      if (VERBOSE) begin $write("Tx"); tx_chdr.print(); end
      tb_chdr_bfm.put_chdr(tx_chdr.copy());
      tb_chdr_bfm.get_chdr(rx_chdr);
      test.end_timeout(ctrl_timeout);
      if (VERBOSE) begin $write("Rx"); rx_chdr.print(); end

      exp_ctrl_hdr = ctrl_hdr;
      exp_ctrl_hdr.dst_port = ctrl_hdr.src_port;
      exp_ctrl_hdr.src_port = ctrl_hdr.dst_port;
      exp_ctrl_hdr.src_epid = dst_epid;
      exp_ctrl_hdr.is_ack = 1'b1;

      exp_chdr.write_ctrl(chdr_hdr, exp_ctrl_hdr, ctrl_op, ctrl_data, ctrl_ts);
      exp_chdr.header.dst_epid = EPID_TB;


      if (VERBOSE) begin $write("ExpRx"); exp_chdr.print(); end

      // Validate contents
      test.assert_error(exp_chdr.equal(rx_chdr),
        "Received CHDR control packet was incorrect");
    end
  endtask


  task send_recv_data_packets(
    input [15:0] src_epid,
    input [15:0] dst_epid,
    input [15:0] num_pkts,
    input [15:0] seq_num_start
  );
    fork
      begin: tx_loop
        for (int txi = 0; txi < num_pkts; txi=txi+1) begin
          automatic timeout_t tx_timeout;
          automatic ChdrPacket #(CHDR_W) tx_chdr = new();
          automatic chdr_header_t tx_hdr;
          automatic chdr_word_t tx_ts;
          automatic chdr_word_t tx_mdata[$];
          automatic chdr_word_t tx_data[$];
          // Fill data in the packet
          tx_hdr = '{
            dst_epid  : dst_epid,
            seq_num   : txi[15:0],
            pkt_type  : (txi%4==0) ? CHDR_DATA_WITH_TS : CHDR_DATA_NO_TS,
            num_mdata : $urandom_range(5),
            default   : 0
          };
          tx_ts = txi;
          tx_mdata.delete();
          for (int i = 0; i < tx_hdr.num_mdata; i++)
            tx_mdata[i] = $urandom();
          tx_data.delete();
          for (int i = 0; i < $urandom_range((1<<MTU)-10); i++)
            tx_data[i] = {txi << 16, i[15:0]};
          tx_chdr.write_raw(tx_hdr, tx_data, tx_mdata, tx_ts);
          if (VERBOSE) begin $write("%s_Tx_",(src_epid == EPID_A)?"A":"B"); tx_chdr.print(); end
          // Send the packet
          test.start_timeout(tx_timeout, 2us, "Waiting to send data packet");
          if (src_epid == EPID_A)
            a_data_bfm.put_chdr(tx_chdr.copy());
          else
            b_data_bfm.put_chdr(tx_chdr.copy());
          test.end_timeout(tx_timeout);
        end
      end
      begin: rx_loop
        for (int rxi = 0; rxi < num_pkts; rxi=rxi+1) begin
          automatic timeout_t rx_timeout;
          automatic ChdrPacket #(CHDR_W) rx_chdr;
          // Receive a packet
          test.start_timeout(rx_timeout, 2us, "Waiting to recv data packet");
          if (dst_epid == EPID_A)
            a_data_bfm.get_chdr(rx_chdr);
          else
            b_data_bfm.get_chdr(rx_chdr);
          test.end_timeout(rx_timeout);
          // Validate the packet
          if (VERBOSE) begin $write("%s_Rx_",(dst_epid == EPID_A)?"A":"B"); rx_chdr.print(); end
          test.assert_error(rx_chdr.header.dst_epid == dst_epid, "Data Pkt: dst_epid was incorrect");
          test.assert_error(rx_chdr.header.seq_num  == rxi + seq_num_start, "Data Pkt: seq_num was incorrect");
          if (rx_chdr.header.pkt_type == CHDR_DATA_WITH_TS)
            test.assert_error(rx_chdr.timestamp  == rxi, "Data Pkt: timestamp was incorrect");
          foreach (rx_chdr.data[i]) begin
            test.assert_error(rx_chdr.data[i] == {rxi << 16, i[15:0]}, "Data Pkt: payload was incorrect");
          end
        end
      end
    join
  endtask

  // ----------------------------------------
  // Test Process
  // ----------------------------------------
  initial begin

    // Shared Variables
    // ----------------------------------------
    timeout_t    timeout;
    string       tc_label;
    bit          stop_responder = 0;
    integer      cached_seqnum = 0;

    // Initialize
    // ----------------------------------------
    test = new("chdr_stream_endpoint_tb");
    test.start_tb();

    // Start the BFMs
    a_data_bfm.run();
    b_data_bfm.run();
    tb_chdr_bfm.run();

    tb_chdr_bfm.set_master_stall_prob(0);
    tb_chdr_bfm.set_slave_stall_prob(0);

    // Reset
    // ----------------------------------------
    rfnoc_ctrl_clk_gen.reset();
    rfnoc_chdr_clk_gen.reset();

    test.start_test("Wait for reset");
    test.start_timeout(timeout, 1us, "Waiting for reset");
    while (rfnoc_ctrl_rst) @(posedge rfnoc_ctrl_clk);
    while (rfnoc_chdr_rst) @(posedge rfnoc_chdr_clk);
    test.end_timeout(timeout);
    test.assert_error(!rfnoc_chdr_rst && !rfnoc_ctrl_rst, "Reset did not deassert");
    test.end_test();

    // Discover Topology
    // ----------------------------------------
    test.start_test("Discover Topology");
    begin
      automatic chdr_header_t tx_mgmt_hdr, rx_mgmt_hdr;
      automatic chdr_mgmt_t tx_mgmt_pl, rx_mgmt_pl;
      automatic chdr_mgmt_op_t exp_mgmt_op;

      // *Status* We know nothing about the network. Need to discover stuff.

      // Generic management header
      tx_mgmt_pl.header = '{
        default:'0, prot_ver:PROTOVER, chdr_width:translate_chdr_w(CHDR_W), src_epid:EPID_TB
      };
      // Send a node info request to the crossbar
      tx_mgmt_pl.header.num_hops = 2;
      tx_mgmt_pl.ops.delete();
      tx_mgmt_pl.ops[0] = '{  // Hop 1: Send node info 
        op_payload:48'h0, op_code:MGMT_OP_INFO_REQ, ops_pending:8'd1};
      tx_mgmt_pl.ops[1] = '{  // Hop 1: Return 
        op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
      tx_mgmt_pl.ops[2] = '{  // Hop 2: Nop for return
        op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
      tx_mgmt_hdr = '{
        pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:16'h0, default:'0};

      // Send the packet and check the response
      send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
      test.assert_error(rx_mgmt_pl.header.num_hops == 1,
        "Discover XB: Mgmt header was incorrect");
      exp_mgmt_op = '{op_payload:{10'h0, 10'd3 /*ports*/, 10'd3 /*ports*/, 10'd0 /*inst*/, 8'd1 /*type*/},
        op_code:MGMT_OP_INFO_RESP, ops_pending:8'd0};
      test.assert_error(rx_mgmt_pl.ops[1] == exp_mgmt_op,
        "Discover XB: Mgmt response ops were incorrect");

      // *Status* We just discovered a crossbar with 3 ports! 

      // Configure the crossbar routing table with our (TB) address
      //  then send node info request on the other two ports
      tx_mgmt_pl.header.num_hops = 3;
      tx_mgmt_pl.ops.delete();
      tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Config router to return packet to dest
        op_payload:{22'h0, PORT_TB, EPID_TB}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd1};
      tx_mgmt_pl.ops[1] = '{  // Hop 1: Crossbar: Config router 
        op_payload:{38'h0, PORT_A}, op_code:MGMT_OP_SEL_DEST, ops_pending:8'd0};
      tx_mgmt_pl.ops[2] = '{  // Hop 2: Stream Endpoint: Send node info 
        op_payload:48'h0, op_code:MGMT_OP_INFO_REQ, ops_pending:8'd1};
      tx_mgmt_pl.ops[3] = '{  // Hop 2: Return 
        op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
      tx_mgmt_pl.ops[4] = '{  // Hop 3: TB: Nop for return
        op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
      tx_mgmt_hdr = '{
        pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:16'h0, default:'0};

      // Send the packet and check the response
      send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
      test.assert_error(rx_mgmt_pl.header.num_hops == 1,
        "Discover SEP A: Mgmt header was incorrect");
      exp_mgmt_op = '{op_payload:{10'h0, 10'd0 /*ports*/, 10'd1 /*ports*/, 10'd0 /*inst*/, 8'd2 /*type*/},
        op_code:MGMT_OP_INFO_RESP, ops_pending:8'd0};
      test.assert_error(rx_mgmt_pl.ops[1] == exp_mgmt_op,
        "Discover SEP A: Mgmt response ops were incorrect");

      // *Status* We just discovered a stream endpoint on crossbar port 1

      // Send node info request on the last port
      tx_mgmt_pl.header.num_hops = 3;
      tx_mgmt_pl.ops.delete();
      tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Config router 
        op_payload:{38'h0, PORT_B}, op_code:MGMT_OP_SEL_DEST, ops_pending:8'd0};
      tx_mgmt_pl.ops[1] = '{  // Hop 2: Stream Endpoint: Send node info 
        op_payload:48'h0, op_code:MGMT_OP_INFO_REQ, ops_pending:8'd1};
      tx_mgmt_pl.ops[2] = '{  // Hop 2: Return 
        op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
      tx_mgmt_pl.ops[3] = '{  // Hop 3: TB: Nop for return
        op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
      tx_mgmt_hdr = '{
        pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:16'h0, default:'0};

      // Send the packet and check the response
      send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
      test.assert_error(rx_mgmt_pl.header.num_hops == 1,
        "Discover SEP B: Mgmt header was incorrect");
      exp_mgmt_op = '{op_payload:{10'h0, 10'd0 /*ports*/, 10'd1 /*ports*/, 10'd1 /*inst*/, 8'd2 /*type*/},
        op_code:MGMT_OP_INFO_RESP, ops_pending:8'd0};
      test.assert_error(rx_mgmt_pl.ops[1] == exp_mgmt_op,
        "Discover SEP B: Mgmt response ops were incorrect");

      // *Status* We just discovered a stream endpoint on crossbar port 2
    end
    test.end_test();

    // Configure Routes to Stream Endpoints A and B
    // ----------------------------------------
    test.start_test("Configure Routes");
    begin
      automatic chdr_header_t tx_mgmt_hdr, rx_mgmt_hdr;
      automatic chdr_mgmt_t tx_mgmt_pl, rx_mgmt_pl;
      automatic chdr_mgmt_op_t exp_mgmt_op;

      // Generic management header
      tx_mgmt_pl.header = '{
        default:'0, prot_ver:PROTOVER, chdr_width:translate_chdr_w(CHDR_W), src_epid:EPID_TB
      };
      // Send a node info request to the crossbar
      tx_mgmt_pl.header.num_hops = 2;
      tx_mgmt_pl.ops.delete();

      tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Config path to EP A
        op_payload:{22'h0, PORT_A, EPID_A}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd2};
      tx_mgmt_pl.ops[1] = '{  // Hop 1: Crossbar: Config path to EP B 
        op_payload:{22'h0, PORT_B, EPID_B}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd1};
      tx_mgmt_pl.ops[2] = '{  // Hop 1: Request node info to make the packet come back 
        op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
      tx_mgmt_pl.ops[3] = '{  // Hop 2: Nop for return
        op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
      tx_mgmt_hdr = '{
        pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:16'h0, default:'0};

      // Send the packet and check the response
      send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
      test.assert_error(rx_mgmt_pl.header.num_hops == 1,
        "Config Routes: Mgmt header was incorrect");
      exp_mgmt_op = '{op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
      test.assert_error(rx_mgmt_pl.ops[0] == exp_mgmt_op,
        "Config Routes: Mgmt response ops were incorrect");
    end
    test.end_test();

    // Configure Stream Endpoints
    // ----------------------------------------
    test.start_test("Configure Stream Endpoints");
    begin
      automatic chdr_header_t tx_mgmt_hdr, rx_mgmt_hdr;
      automatic chdr_mgmt_t tx_mgmt_pl, rx_mgmt_pl;
      automatic chdr_mgmt_op_t exp_mgmt_op;

      logic [15:0] epids[2] = {EPID_A, EPID_B};
      foreach (epids[i]) begin
        // Generic management header
        tx_mgmt_pl.header = '{
          default:'0, prot_ver:PROTOVER, chdr_width:translate_chdr_w(CHDR_W), src_epid:EPID_TB
        };
        // Send a node info request to the crossbar
        tx_mgmt_pl.header.num_hops = 3;
        tx_mgmt_pl.ops.delete();

        tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Nop
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_pl.ops[1] = '{  // Hop 2: Reset
          op_payload:{30'h0, 2'b11, sep_a.REG_RESET_AND_FLUSH}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd4};
        tx_mgmt_pl.ops[2] = '{  // Hop 2: Write EPID
          op_payload:{16'h0, epids[i], sep_a.REG_EPID_SELF}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd3};
        tx_mgmt_pl.ops[3] = '{  // Hop 2: Read EPID
          op_payload:{32'h0, sep_a.REG_EPID_SELF}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd2};
        tx_mgmt_pl.ops[4] = '{  // Hop 2: Read EPID
          op_payload:{32'h0, sep_a.REG_OSTRM_CTRL_STATUS}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd1};
        tx_mgmt_pl.ops[5] = '{  // Hop 2: Stream Endpoint: Return 
          op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
        tx_mgmt_pl.ops[6] = '{  // Hop 3: Nop for return
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_hdr = '{
          pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:epids[i], default:'0};
  
        // Send the packet and check the response
        send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
        test.assert_error(rx_mgmt_pl.header.num_hops == 1,
          "Config SEP: Mgmt header was incorrect");
        exp_mgmt_op = '{op_payload:{16'h0, epids[i], sep_a.REG_EPID_SELF},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd1};
        test.assert_error(rx_mgmt_pl.ops[1] == exp_mgmt_op,
          "Config SEP: Mgmt response ops were incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_CTRL_STATUS},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd0};
        test.assert_error(rx_mgmt_pl.ops[2] == exp_mgmt_op,
          "Config SEP: Mgmt response ops were incorrect");
      end
    end
    test.end_test();

    // Setup a stream between Endpoint A and B
    // ----------------------------------------
    test.start_test("Setup bidirectional stream between endpoints A and B");
    begin
      automatic chdr_header_t tx_mgmt_hdr, rx_mgmt_hdr;
      automatic chdr_mgmt_t tx_mgmt_pl, rx_mgmt_pl;
      automatic chdr_mgmt_op_t exp_mgmt_op;

      logic [15:0] epids[2] = {EPID_A, EPID_B};
      foreach (epids[i]) begin
        // Generic management header
        tx_mgmt_pl.header = '{
          default:'0, prot_ver:PROTOVER, chdr_width:translate_chdr_w(CHDR_W), src_epid:EPID_TB
        };
        // Configure FC on streams
        tx_mgmt_pl.header.num_hops = 3;
        tx_mgmt_pl.ops.delete();

        tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Nop
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_pl.ops[1] = '{  // Hop 2: Write destination EPID
          op_payload:{16'h0, epids[1-i], sep_a.REG_OSTRM_DST_EPID}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd6};
        tx_mgmt_pl.ops[2] = '{  // Hop 2: Configure flow ack control freq
          op_payload:{32'd50, sep_a.REG_OSTRM_FC_FREQ_BYTES_LO}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd5};
        tx_mgmt_pl.ops[3] = '{  // Hop 2: Configure flow ack control freq
          op_payload:{32'd0, sep_a.REG_OSTRM_FC_FREQ_BYTES_HI}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd4};
        tx_mgmt_pl.ops[4] = '{  // Hop 2: Configure flow ack control freq
          op_payload:{32'd1000, sep_a.REG_OSTRM_FC_FREQ_PKTS}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd3};
        tx_mgmt_pl.ops[5] = '{  // Hop 2: Configure flow headroom
          op_payload:{32'd0, sep_a.REG_OSTRM_FC_HEADROOM}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd2};
        tx_mgmt_pl.ops[6] = '{  // Hop 2: Configure lossy and start config
          op_payload:{32'd3, sep_a.REG_OSTRM_CTRL_STATUS}, op_code:MGMT_OP_CFG_WR_REQ, ops_pending:8'd1};
        tx_mgmt_pl.ops[7] = '{  // Hop 2: Stream Endpoint: Return 
          op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
        tx_mgmt_pl.ops[8] = '{  // Hop 3: Nop for return
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_hdr = '{
          pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:epids[i], default:'0};

        // Send the packet and check the response
        send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);

        // Wait for some time for node to flush and reset
        // Typically we would poll in SW but we just wait to keep the code simple
        repeat (256) @(posedge rfnoc_chdr_clk);

        // Read back FC status
        tx_mgmt_pl.header.num_hops = 3;
        tx_mgmt_pl.ops.delete();

        tx_mgmt_pl.ops[0] = '{  // Hop 1: Crossbar: Nop
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_pl.ops[1] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_CTRL_STATUS}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd8};
        tx_mgmt_pl.ops[2] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_BYTES_LO}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd7};
        tx_mgmt_pl.ops[3] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_BYTES_HI}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd6};
        tx_mgmt_pl.ops[4] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_PKTS_LO}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd5};
        tx_mgmt_pl.ops[5] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_PKTS_HI}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd4};
        tx_mgmt_pl.ops[6] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_SEQ_ERR_CNT}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd3};
        tx_mgmt_pl.ops[7] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_DATA_ERR_CNT}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd2};
        tx_mgmt_pl.ops[8] = '{  // Hop 2: Read status
          op_payload:{32'h0, sep_a.REG_OSTRM_ROUTE_ERR_CNT}, op_code:MGMT_OP_CFG_RD_REQ, ops_pending:8'd1};
        tx_mgmt_pl.ops[9] = '{  // Hop 2: Stream Endpoint: Return 
          op_payload:48'h0, op_code:MGMT_OP_RETURN, ops_pending:8'd0};
        tx_mgmt_pl.ops[10] = '{  // Hop 3: Nop for return
          op_payload:48'h0, op_code:MGMT_OP_NOP, ops_pending:8'd0};
        tx_mgmt_hdr = '{
          pkt_type:CHDR_MANAGEMENT, seq_num:cached_seqnum++, dst_epid:epids[i], default:'0};

        // Send the packet and check the response
        send_recv_mgmt_packet(tx_mgmt_hdr, tx_mgmt_pl, rx_mgmt_hdr, rx_mgmt_pl);
        test.assert_error(rx_mgmt_pl.header.num_hops == 1,
          "Config SEP: Mgmt header was incorrect");
        exp_mgmt_op = '{op_payload:{32'h80000002, sep_a.REG_OSTRM_CTRL_STATUS},   // FC on, no errors and lossy
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd7};
        test.assert_error(rx_mgmt_pl.ops[1] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{((1<<(MTU+1))*(CHDR_W/8)-1), sep_a.REG_OSTRM_BUFF_CAP_BYTES_LO},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd6};
        test.assert_error(rx_mgmt_pl.ops[2] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_BYTES_HI},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd5};
        test.assert_error(rx_mgmt_pl.ops[3] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h00ffffff, sep_a.REG_OSTRM_BUFF_CAP_PKTS_LO},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd4};
        test.assert_error(rx_mgmt_pl.ops[4] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_BUFF_CAP_PKTS_HI},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd3};
        test.assert_error(rx_mgmt_pl.ops[5] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_SEQ_ERR_CNT},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd2};
        test.assert_error(rx_mgmt_pl.ops[6] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_DATA_ERR_CNT},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd1};
        test.assert_error(rx_mgmt_pl.ops[7] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
        exp_mgmt_op = '{op_payload:{32'h0, sep_a.REG_OSTRM_ROUTE_ERR_CNT},
          op_code:MGMT_OP_CFG_RD_RESP, ops_pending:8'd0};
        test.assert_error(rx_mgmt_pl.ops[8] == exp_mgmt_op, "Config SEP: Mgmt response was incorrect");
      end
    end
    test.end_test();

    // Control transactions to Endpoint A
    // ----------------------------------------
    cached_seqnum = 0;
    for (int cfg = 0; cfg < 4; cfg++) begin
      automatic logic mst_cfg = cfg[0];
      automatic logic slv_cfg = cfg[1];
      $sformat(tc_label, "Control Transactions to A (%s Master, %s Slave)",
        (mst_cfg?"Slow":"Fast"), (slv_cfg?"Slow":"Fast"));
      test.start_test(tc_label);
      begin
        send_recv_ctrl_packets(EPID_A, NUM_PKTS_PER_TEST, cached_seqnum);
      end
      test.end_test();
      cached_seqnum += NUM_PKTS_PER_TEST;
    end

    // Control transactions to Endpoint B
    // ----------------------------------------
    cached_seqnum = 0;
    for (int cfg = 0; cfg < 4; cfg++) begin
      automatic logic mst_cfg = cfg[0];
      automatic logic slv_cfg = cfg[1];
      $sformat(tc_label, "Control Transactions to B (%s Master, %s Slave)",
        (mst_cfg?"Slow":"Fast"), (slv_cfg?"Slow":"Fast"));
      test.start_test(tc_label);
      begin
        send_recv_ctrl_packets(EPID_B, NUM_PKTS_PER_TEST, cached_seqnum);
      end
      test.end_test();
      cached_seqnum += NUM_PKTS_PER_TEST;
    end


    // Stream data from A to B
    // ----------------------------------------
    cached_seqnum = 0;
    for (int cfg = 0; cfg < 4; cfg++) begin
      automatic logic mst_cfg = cfg[0];
      automatic logic slv_cfg = cfg[1];
      $sformat(tc_label, "Stream Data Packets from A to B (%s Master, %s Slave)",
        (mst_cfg?"Slow":"Fast"), (slv_cfg?"Slow":"Fast"));
      test.start_test(tc_label);
      begin
        a_data_bfm.set_master_stall_prob(mst_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
        b_data_bfm.set_slave_stall_prob (slv_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
        send_recv_data_packets(EPID_A, EPID_B, NUM_PKTS_PER_TEST, cached_seqnum);
      end
      test.end_test();
      cached_seqnum += NUM_PKTS_PER_TEST;
    end

    // Stream data from B to A
    // ----------------------------------------
    cached_seqnum = 0;
    for (int cfg = 0; cfg < 4; cfg++) begin
      automatic logic mst_cfg = cfg[0];
      automatic logic slv_cfg = cfg[1];
      $sformat(tc_label, "Stream Data Packets from B to A (%s Master, %s Slave)",
        (mst_cfg?"Slow":"Fast"), (slv_cfg?"Slow":"Fast"));
      test.start_test(tc_label);
      begin
        b_data_bfm.set_master_stall_prob(mst_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
        a_data_bfm.set_slave_stall_prob (slv_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
        send_recv_data_packets(EPID_B, EPID_A, NUM_PKTS_PER_TEST, cached_seqnum);
      end
      test.end_test();
      cached_seqnum += NUM_PKTS_PER_TEST;
    end

//    // Stream data between A <=> B simultaneously
//    // ----------------------------------------
//    for (int cfg = 0; cfg < 4; cfg++) begin
//      automatic logic mst_cfg = cfg[0];
//      automatic logic slv_cfg = cfg[1];
//      $sformat(tc_label, "Stream Data Packets between A <=> B simultaneously (%s Master, %s Slave)",
//        (mst_cfg?"Slow":"Fast"), (slv_cfg?"Slow":"Fast"));
//      test.start_test(tc_label);
//      begin
//        a_data_bfm.set_master_stall_prob(mst_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
//        b_data_bfm.set_master_stall_prob(mst_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
//        a_data_bfm.set_slave_stall_prob (slv_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
//        b_data_bfm.set_slave_stall_prob (slv_cfg?SLOW_STALL_PROB:FAST_STALL_PROB);
//        fork
//          send_recv_data_packets(EPID_B, EPID_A, NUM_PKTS_PER_TEST, cached_seqnum);
//          send_recv_data_packets(EPID_A, EPID_B, NUM_PKTS_PER_TEST, cached_seqnum);
//        join
//      end
//      test.end_test();
//      cached_seqnum += NUM_PKTS_PER_TEST;
//    end

    // Finish Up
    // ----------------------------------------
    // Display final statistics and results
    test.end_tb();
  end

endmodule
