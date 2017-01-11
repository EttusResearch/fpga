//
// Copyright 2016 Ettus Research LLC
//


`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 13

`include "sim_clks_rsts.vh"
`include "sim_exec_report.vh"
`include "sim_cvita_lib.svh"
`include "sim_axi4_lib.svh"
`include "sim_set_rb_lib.svh"

module ten_gig_eth_loopback_tb();
  `TEST_BENCH_INIT("ten_gig_eth_loopback_tb",`NUM_TEST_CASES,`NS_PER_TICK)

  // Define all clocks and resets
  `DEFINE_CLK(XG_CLK_P, 1000/156.25, 50)  //156.25MHz GT transceiver clock
  `DEFINE_RESET(GSR, 0, 100)              //100ns for GSR to deassert

  wire XG_CLK_N = ~XG_CLK_P;
  wire SFP_LN0_P, SFP_LN0_N, SFP_LN1_P, SFP_LN1_N;

  //localparam PACKET_MODE = 0;
  localparam PORTNUM = 8'd0;

  // Ten_gigE Loopback Topology:
  //
  // TB Simulus ====> |------------|       |----------------|
  //                  | XgigE MAC  | <===> | XgigE PCS/PMA  | <====>||
  // TB Checker <==== |------------|       |----------------|       || Loopback through
  //                                                                ||
  //            ====> |------------|       |----------------|       || perfect serial channel
  // Loopback   |     | XgigE MAC  | <===> | XgigE PCS/PMA  | <====>||
  //            <==== |------------|       |----------------|

  // Initialize DUT
  wire xgige_refclk, xgige_clk156, xgige_dclk;
  wire m_user_clk, s_user_clk;
  wire m_channel_up, s_channel_up;

  wire [63:0] m_xgmii_txd;
  wire [7:0]  m_xgmii_txc;
  wire [63:0] m_xgmii_rxd;
  wire [7:0]  m_xgmii_rxc;
  wire [63:0] s_xgmii_txd;
  wire [7:0]  s_xgmii_txc;
  wire [63:0] s_xgmii_rxd;
  wire [7:0]  s_xgmii_rxc;
  wire [7:0]  m_xgmii_status;
  wire [7:0]  s_xgmii_status;
  wire        m_xge_phy_resetdone;
  wire        s_xge_phy_resetdone;
  wire        m_mdc, m_mdio_in, m_mdio_out;
  wire        s_mdc, s_mdio_in, s_mdio_out;
  wire        sfpp_rxlos,sfpp_tx_fault,sfpp_tx_disable;


  wire [15:0] m_phy_status;
  wire [15:0] s_phy_status;
  wire [63:0] loop_tdata;
  wire        loop_tlast, loop_tvalid, loop_tready;

  wire [7:0]      wb_adr_i;
  wire            wb_cyc_i;
  wire [31:0]     wb_dat_i;
  wire            wb_stb_i;
  wire            wb_we_i;
  wire            wb_ack_o;
  wire [31:0]     wb_dat_o;
  wire            wb_int_o;


  reg independent_clock;
  assign m_channel_up = m_phy_status[0];
  assign s_channel_up = s_phy_status[0];
  //assign m_user_clk = xgige_refclk;
  //assign s_user_clk = xgige_refclk;
  assign m_user_clk = independent_clock;
  assign s_user_clk = independent_clock;

   ten_gige_phy_clk_gen xgige_clk_gen_i (
      .areset(GSR),
      .refclk_p(XG_CLK_P),
      .refclk_n(XG_CLK_N),
      .refclk(xgige_refclk),
      .clk156(xgige_clk156),
      .dclk(xgige_dclk)
   );

  cvita_master m_tx_chdr (.clk(m_user_clk));
  cvita_slave s_rx_chdr (.clk(s_user_clk));
  initial
  begin
    independent_clock <= 1'b0;
    forever
    begin
      independent_clock <= 1'b0;
      #2.5;
      independent_clock <= 1'b1;
      #2.5;
    end
  end

  assign sfpp_rxlos = 1'b0;
  assign sfpp_tx_fault = 1'b0;

  // Instantiate the 10GBASER/KR GT Common block
  ten_gig_eth_pcs_pma_gt_common # (
      .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE") ) //Does not affect hardware
  ten_gig_eth_pcs_pma_gt_common_block
    (
     .refclk(xgige_refclk),
     .qpllreset(qpllreset),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclksel(3'b001 /*3'b101*GTSOUTHREFCLK0*/)
    );

      ten_gige_phy ten_gige_phy_master_i
      (
         // Clocks and Reset
         .areset(GSR),                 // Asynchronous reset for entire core.
         .refclk(xgige_refclk),              // Transciever reference clock: 156.25MHz
         .clk156(xgige_clk156),              // Globally buffered core clock: 156.25MHz
         .dclk(xgige_dclk),                 // Management/DRP clock: 78.125MHz
         .sim_speedup_control(~GSR),
         // GMII Interface (client MAC <=> PCS)
         .xgmii_txd(m_xgmii_txd),          // Transmit data from client MAC.
         .xgmii_txc(m_xgmii_txc),          // Transmit control signal from client MAC.
         .xgmii_rxd(m_xgmii_rxd),          // Received Data to client MAC.
         .xgmii_rxc(m_xgmii_rxc),          // Received control signal to client MAC.
         // Tranceiver Interface
         .txp(SFP_LN0_P),                  // Differential +ve of serial transmission from PMA to PMD.
         .txn(SFP_LN0_N),                  // Differential -ve of serial transmission from PMA to PMD.
         .rxp(SFP_LN1_P),                  // Differential +ve for serial reception from PMD to PMA.
         .rxn(SFP_LN1_N),                  // Differential -ve for serial reception from PMD to PMA.
         // Management: MDIO Interface
         .mdc(m_mdc),                      // Management Data Clock
         .mdio_in(m_mdio_in),              // Management Data In
         .mdio_out(m_mdio_out),            // Management Data Out
         .mdio_tri(),                     // Management Data Tristate
         .prtad(5'd4),                    // MDIO address is 4
         // General IO's
         .core_status(m_xgmii_status),     // Core status
         .resetdone(m_xge_phy_resetdone),
         .signal_detect(~sfpp_rxlos),     //FIXME // Input from PMD to indicate presence of optical input. (Undocumented, but it seems Xilinx expect this to be inverted.)
         .tx_fault(sfpp_tx_fault),       //FIXME
         .tx_disable(/*sfpp_tx_disable*/),    //FIXME
         .qpllreset(qpllreset1),
         .qplllock(qplllock),
         .qplloutclk(qplloutclk),
         .qplloutrefclk(qplloutrefclk)

      );

      xge_mac_wrapper #(.PORTNUM(PORTNUM)) xge_mac_wrapper_master_i
      (
         // XGMII
         .xgmii_clk(xgige_clk156),
         .xgmii_txd(m_xgmii_txd),
         .xgmii_txc(m_xgmii_txc),
         .xgmii_rxd(m_xgmii_rxd),
         .xgmii_rxc(m_xgmii_rxc),
         // MDIO
         .mdc(m_mdc),
         .mdio_in(m_mdio_in),
         .mdio_out(m_mdio_out),
         // Wishbone I/F
         .wb_clk_i(m_user_clk),
         .wb_rst_i(GSR),
         .wb_adr_i(wb_adr_i),
         .wb_cyc_i(wb_cyc_i),
         .wb_dat_i(wb_dat_i),
         .wb_stb_i(wb_stb_i),
         .wb_we_i(wb_we_i),
         .wb_ack_o(wb_ack_o),
         .wb_dat_o(wb_dat_o),
         .wb_int_o(wb_int_o),
         // Client FIFO Interfaces
         .sys_clk(m_user_clk),
         .reset(GSR),
         .rx_tdata(s_rx_chdr.axis.tdata),
         .rx_tuser(),
         .rx_tlast(s_rx_chdr.axis.tlast),
         .rx_tvalid(s_rx_chdr.axis.tvalid),
         .rx_tready(s_rx_chdr.axis.tready),
         .tx_tdata(m_tx_chdr.axis.tdata),
         .tx_tuser(4'd4),                // Bit[3] (error) is ignored for now.
         .tx_tlast(m_tx_chdr.axis.tlast),
         .tx_tvalid(m_tx_chdr.axis.tvalid),
         .tx_tready(m_tx_chdr.axis.tready),
         // Other
         .phy_ready(m_xge_phy_resetdone),
         // Debug
         .debug_rx(),
         .debug_tx()
      );

      assign m_phy_status  = {8'h00, m_xgmii_status};

      ten_gige_phy ten_gige_phy_slave_i
      (
         // Clocks and Reset
         .areset(GSR),                 // Asynchronous reset for entire core.
         .refclk(xgige_refclk),              // Transciever reference clock: 156.25MHz
         .clk156(xgige_clk156),              // Globally buffered core clock: 156.25MHz
         .dclk(xgige_dclk),                 // Management/DRP clock: 78.125MHz
         .sim_speedup_control(~GSR),
         // GMII Interface (client MAC <=> PCS)
         .xgmii_txd(s_xgmii_txd),          // Transmit data from client MAC.
         .xgmii_txc(s_xgmii_txc),          // Transmit control signal from client MAC.
         .xgmii_rxd(s_xgmii_rxd),          // Received Data to client MAC.
         .xgmii_rxc(s_xgmii_rxc),          // Received control signal to client MAC.
         // Tranceiver Interface
         .txp(SFP_LN1_P),                       // Differential +ve of serial transmission from PMA to PMD.
         .txn(SFP_LN1_N),                       // Differential -ve of serial transmission from PMA to PMD.
         .rxp(SFP_LN0_P),                       // Differential +ve for serial reception from PMD to PMA.
         .rxn(SFP_LN0_N),                       // Differential -ve for serial reception from PMD to PMA.
         // Management: MDIO Interface
         .mdc(s_mdc),                      // Management Data Clock
         .mdio_in(s_mdio_in),              // Management Data In
         .mdio_out(s_mdio_out),            // Management Data Out
         .mdio_tri(),                     // Management Data Tristate
         .prtad(5'd4),                    // MDIO address is 4
         // General IO's
         .core_status(s_xgmii_status),     // Core status
         .resetdone(s_xge_phy_resetdone),
         .signal_detect(~sfpp_rxlos),     //FIXME // Input from PMD to indicate presence of optical input. (Undocumented, but it seems Xilinx expect this to be inverted.)
         .tx_fault(sfpp_tx_fault),       //FIXME
         .tx_disable(/*sfpp_tx_disable*/),    //FIXME
         .qpllreset(qpllreset2),
         .qplllock(qplllock),
         .qplloutclk(qplloutclk),
         .qplloutrefclk(qplloutrefclk)
      );

      xge_mac_wrapper #(.PORTNUM(PORTNUM)) xge_mac_wrapper_slave_i
      (
         // XGMII
         .xgmii_clk(xgige_clk156),
         .xgmii_txd(s_xgmii_txd),
         .xgmii_txc(s_xgmii_txc),
         .xgmii_rxd(s_xgmii_rxd),
         .xgmii_rxc(s_xgmii_rxc),
         // MDIO
         .mdc(s_mdc),
         .mdio_in(s_mdio_in),
         .mdio_out(s_mdio_out),
         // Wishbone I/F
         .wb_clk_i(s_user_clk),
         .wb_rst_i(GSR),
         .wb_adr_i(wb_adr_i),
         .wb_cyc_i(wb_cyc_i),
         .wb_dat_i(wb_dat_i),
         .wb_stb_i(wb_stb_i),
         .wb_we_i(wb_we_i),
         .wb_ack_o(wb_ack_o),
         .wb_dat_o(wb_dat_o),
         .wb_int_o(wb_int_o),
         // Client FIFO Interfaces
         .sys_clk(s_user_clk),
         .reset(GSR),
         .rx_tdata(loop_tdata),
         .rx_tuser(),
         .rx_tlast(loop_tlast),
         .rx_tvalid(loop_tvalid),
         .rx_tready(loop_tready),
         .tx_tdata(loop_tdata),
         .tx_tuser(4'd4),                // Bit[3] (error) is ignored for now.
         .tx_tlast(loop_tlast),
         .tx_tvalid(loop_tvalid),
         .tx_tready(loop_tready),
         // Other
         .phy_ready(s_xge_phy_resetdone),
         // Debug
         .debug_rx(),
         .debug_tx()
      );

      assign s_phy_status  = {8'h00, s_xgmii_status};

  //Testbench variables
  cvita_hdr_t   header, header_out;
  cvita_stats_t stats;
  logic [63:0]  crc_cache;

  //------------------------------------------
  //Main thread for testbench execution
  //------------------------------------------
  initial begin : tb_main
    `TEST_CASE_START("Wait for reset");
    while (GSR) @(posedge XG_CLK_P);
    `TEST_CASE_DONE((~GSR));

    m_tx_chdr.push_bubble();

    `TEST_CASE_START("Wait for master channel to come up");
    while (m_channel_up !== 1'b1) @(posedge m_user_clk);
    `TEST_CASE_DONE(1'b1);

    `TEST_CASE_START("Wait for slave channel to come up");
    while (s_channel_up !== 1'b1) @(posedge s_user_clk);
    `TEST_CASE_DONE(1'b1);

   // `TEST_CASE_START("Run PRBS15 BIST");
   // s_bist_loopback <= PACKET_MODE;
   // @(posedge m_user_clk);
   // m_bist_gen <= 1'b1;
   // m_bist_check <= 1'b1;
   // @(posedge m_user_clk);
   // while (m_bist_locked !== 1'b1) @(posedge m_user_clk);
   // repeat (512) @(posedge m_user_clk);
   // `ASSERT_ERROR(m_bist_samps>256, "BIST: Num samples incorrect");
   // `ASSERT_ERROR(m_bist_errors===36'd0, "BIST: Errors!");
   // @(posedge m_user_clk);
   // m_bist_gen <= 1'b0;
   // repeat (256) @(posedge m_user_clk);
   // m_bist_check <= 1'b0;
   // `TEST_CASE_DONE(1'b1);

   repeat(2000) @(posedge m_user_clk);

    header = '{
      pkt_type:DATA, has_time:0, eob:0, seqnum:12'h666,
      length:0, src_sid:$random, dst_sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Fill up empty FIFO then drain (short packet)");
      s_rx_chdr.axis.tready = 0;
      m_tx_chdr.push_ramp_pkt(16, 64'd0, 64'h100, header);
      s_rx_chdr.axis.tready = 1;
      s_rx_chdr.wait_for_pkt_get_info(header_out, stats);
      `ASSERT_ERROR(stats.count==16,            "Bad packet: Length mismatch");
      `ASSERT_ERROR(header.dst_sid==header_out.dst_sid, "Bad packet: Wrong SID");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Fill up empty FIFO then drain (long packet)");
      s_rx_chdr.axis.tready = 0;
      m_tx_chdr.push_ramp_pkt(256, 64'd0, 64'h100, header);
      s_rx_chdr.axis.tready = 1;
      s_rx_chdr.wait_for_pkt_get_info(header_out, stats);
      `ASSERT_ERROR(stats.count==256,           "Bad packet: Length mismatch");
      `ASSERT_ERROR(header.dst_sid==header_out.dst_sid, "Bad packet: Wrong SID");
    `TEST_CASE_DONE(1);

    header = '{
      pkt_type:DATA, has_time:1, eob:0, seqnum:12'h666,
      length:0, src_sid:$random, dst_sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Concurrent read and write (single packet)");
      s_rx_chdr.axis.tready = 1;
      fork
        begin
          m_tx_chdr.push_ramp_pkt(1000, 64'd0, 64'h100, header);
        end
        begin
          s_rx_chdr.wait_for_pkt_get_info(header_out, stats);
        end
      join
    crc_cache = stats.crc;    //Cache CRC for future test cases
    `ASSERT_ERROR(stats.count==1000, "Bad packet: Length mismatch");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Concurrent read and write (multiple packets)");
      s_rx_chdr.axis.tready = 1;
      fork
        begin
          repeat (20) begin
            m_tx_chdr.push_ramp_pkt(20, 64'd0, 64'h100, header);
            m_tx_chdr.push_bubble();
          end
        end
        begin
          repeat (20) begin
            s_rx_chdr.wait_for_pkt_get_info(header_out, stats);
            `ASSERT_ERROR(stats.count==20,      "Bad packet: Length mismatch");
            `ASSERT_ERROR(crc_cache==stats.crc, "Bad packet: Wrong CRC");
          end
        end
      join
    `TEST_CASE_DONE(1);

    //`TEST_CASE_START("Validate no drops (master)");
    //`TEST_CASE_DONE((m_overruns === 32'd0));

    //`TEST_CASE_START("Validate no drops (slave)");
    //`TEST_CASE_DONE((s_overruns === 32'd0));

    //s_bist_loopback <= 1'b1;

    //`TEST_CASE_START("Run PRBS15 BIST (Loopback Mode)");
    //@(posedge m_user_clk);
    //m_bist_gen <= 1'b1;
    //m_bist_rate <= 5'd4;
    //m_bist_check <= 1'b1;
    //@(posedge m_user_clk);
    //while (m_bist_locked !== 1'b1) @(posedge m_user_clk);
    //repeat (512) @(posedge m_user_clk);
    //`ASSERT_ERROR(m_bist_samps>256, "BIST: Num samples incorrect");
    //`ASSERT_ERROR(m_bist_errors===36'd0, "BIST: Errors!");
    //@(posedge m_user_clk);
    //m_bist_gen <= 1'b0;
    //repeat (256) @(posedge m_user_clk);
    //m_bist_check <= 1'b0;
    //`TEST_CASE_DONE(1'b1);

    //s_bist_loopback <= 1'b0;

    //`TEST_CASE_START("Validate no drops (master)");
    //`TEST_CASE_DONE((m_overruns === 32'd0));

    //`TEST_CASE_START("Validate no drops (slave)");
    //`TEST_CASE_DONE((s_overruns === 32'd0));

  end

endmodule
