//
// Copyright 2016 Ettus Research LLC
//

module x300_sfpp_io_core #(
   parameter PROTOCOL = "10GbE",    // Must be {10GbE, 1GbE, Aurora}
   parameter PORTNUM  = 8'd0
)(
   input             areset,
   input             bus_rst,
   input             bus_rst_div2,

   input             gt_refclk,
   input             gb_refclk,
   input             misc_clk,
   input             bus_clk,
   input             bus_clk_div2,

   output            txp,
   output            txn,
   input             rxp,
   input             rxn,

   input             sfpp_rxlos,
   input             sfpp_tx_fault,
   output            sfpp_tx_disable,
   
   input  [63:0]     s_axis_tdata,
   input  [3:0]      s_axis_tuser,
   input             s_axis_tlast,
   input             s_axis_tvalid,
   output            s_axis_tready,
   
   output [63:0]     m_axis_tdata,
   output [3:0]      m_axis_tuser,
   output            m_axis_tlast,
   output            m_axis_tvalid,
   input             m_axis_tready,

   input  [7:0]      wb_adr_i,
   input             wb_cyc_i,
   input  [31:0]     wb_dat_i,
   input             wb_stb_i,
   input             wb_we_i, 
   output            wb_ack_o,
   output [31:0]     wb_dat_o,
   output            wb_int_o,

   output [15:0]     phy_status
);

   wire mdc, mdio_in, mdio_out;

generate
   if (PROTOCOL == "10GbE") begin
      //-----------------------------------------------------------------
      // 10 Gigabit Ethernet
      //-----------------------------------------------------------------
      wire [63:0] xgmii_txd;
      wire [7:0]  xgmii_txc;
      wire [63:0] xgmii_rxd;
      wire [7:0]  xgmii_rxc;
      wire [7:0]  xgmii_status;
      wire        xge_phy_resetdone;
   
      ten_gige_phy ten_gige_phy_i
      (
         // Clocks and Reset
         .areset(areset),                 // Asynchronous reset for entire core.
         .refclk(gt_refclk),              // Transciever reference clock: 156.25MHz
         .clk156(gb_refclk),              // Globally buffered core clock: 156.25MHz
         .dclk(misc_clk),                 // Management/DRP clock: 78.125MHz
         .sim_speedup_control(1'b0),
         // GMII Interface (client MAC <=> PCS)
         .xgmii_txd(xgmii_txd),          // Transmit data from client MAC.
         .xgmii_txc(xgmii_txc),          // Transmit control signal from client MAC.
         .xgmii_rxd(xgmii_rxd),          // Received Data to client MAC.
         .xgmii_rxc(xgmii_rxc),          // Received control signal to client MAC.
         // Tranceiver Interface
         .txp(txp),                       // Differential +ve of serial transmission from PMA to PMD.
         .txn(txn),                       // Differential -ve of serial transmission from PMA to PMD.
         .rxp(rxp),                       // Differential +ve for serial reception from PMD to PMA.
         .rxn(rxn),                       // Differential -ve for serial reception from PMD to PMA.
         // Management: MDIO Interface
         .mdc(mdc),                      // Management Data Clock
         .mdio_in(mdio_in),              // Management Data In
         .mdio_out(mdio_out),            // Management Data Out
         .mdio_tri(),                     // Management Data Tristate
         .prtad(5'd4),                    // MDIO address is 4
         // General IO's
         .core_status(xgmii_status),     // Core status
         .resetdone(xge_phy_resetdone),
         .signal_detect(~sfpp_rxlos),     // Input from PMD to indicate presence of optical input. (Undocumented, but it seems Xilinx expect this to be inverted.)
         .tx_fault(sfpp_tx_fault),
         .tx_disable(sfpp_tx_disable)
      );
      
      xge_mac_wrapper #(.PORTNUM(PORTNUM)) xge_mac_wrapper_i
      (
         // XGMII
         .xgmii_clk(gb_refclk),
         .xgmii_txd(xgmii_txd),
         .xgmii_txc(xgmii_txc),
         .xgmii_rxd(xgmii_rxd),
         .xgmii_rxc(xgmii_rxc),
         // MDIO
         .mdc(mdc),
         .mdio_in(mdio_in),
         .mdio_out(mdio_out),
         // Wishbone I/F
         .wb_clk_i(bus_clk_div2),      
         .wb_rst_i(bus_rst_div2),      
         .wb_adr_i(wb_adr_i),  
         .wb_cyc_i(wb_cyc_i),  
         .wb_dat_i(wb_dat_i),
         .wb_stb_i(wb_stb_i),  
         .wb_we_i(wb_we_i),    
         .wb_ack_o(wb_ack_o),  
         .wb_dat_o(wb_dat_o),
         .wb_int_o(wb_int_o),  
         // Client FIFO Interfaces
         .sys_clk(bus_clk),
         .reset(bus_rst),
         .rx_tdata(m_axis_tdata),
         .rx_tuser(m_axis_tuser),
         .rx_tlast(m_axis_tlast),
         .rx_tvalid(m_axis_tvalid),
         .rx_tready(m_axis_tready),
         .tx_tdata(s_axis_tdata),
         .tx_tuser(s_axis_tuser),                // Bit[3] (error) is ignored for now.
         .tx_tlast(s_axis_tlast),
         .tx_tvalid(s_axis_tvalid),
         .tx_tready(s_axis_tready),
         // Other
         .phy_ready(xge_phy_resetdone),
         // Debug
         .debug_rx(),
         .debug_tx()
      );

      assign phy_status  = {8'h00, xgmii_status};
   
   end else if (PROTOCOL == "1GbE") begin

      //-----------------------------------------------------------------
      // 1 Gigabit Ethernet
      //-----------------------------------------------------------------
      wire [7:0]  gmii_txd, gmii_rxd;
      wire        gmii_tx_en, gmii_tx_er, gmii_rx_dv, gmii_rx_er;
      wire        gmii_clk;
   
      assign sfpp_tx_disable = 1'b0; // Always on.
   
      one_gige_phy one_gige_phy_i
      (
         .reset(areset),                  // Asynchronous reset for entire core.
         .independent_clock(bus_clk),
         // Tranceiver Interface
         .gtrefclk(gt_refclk),            // Reference clock for MGT: 125MHz, very high quality.
         .gtrefclk_bufg(gb_refclk),       // Reference clock routed through a BUFG
         .txp(txp),                       // Differential +ve of serial transmission from PMA to PMD.
         .txn(txn),                       // Differential -ve of serial transmission from PMA to PMD.
         .rxp(rxp),                       // Differential +ve for serial reception from PMD to PMA.
         .rxn(rxn),                       // Differential -ve for serial reception from PMD to PMA.
         // GMII Interface (client MAC <=> PCS)
         .gmii_clk(gmii_clk),            // Clock to client MAC.
         .gmii_txd(gmii_txd),            // Transmit data from client MAC.
         .gmii_tx_en(gmii_tx_en),        // Transmit control signal from client MAC.
         .gmii_tx_er(gmii_tx_er),        // Transmit control signal from client MAC.
         .gmii_rxd(gmii_rxd),            // Received Data to client MAC.
         .gmii_rx_dv(gmii_rx_dv),        // Received control signal to client MAC.
         .gmii_rx_er(gmii_rx_er),        // Received control signal to client MAC.
         // Management: MDIO Interface
         .mdc(mdc),                      // Management Data Clock
         .mdio_i(mdio_in),               // Management Data In
         .mdio_o(mdio_out),              // Management Data Out
         .mdio_t(),                       // Management Data Tristate
         .configuration_vector(5'd0),     // Alternative to MDIO interface.
         .configuration_valid(1'b1),      // Validation signal for Config vector (MUST be 1 for proper functionality...undocumented)
         // General IO's
         .status_vector(phy_status),    // Core status.
         .signal_detect(1'b1 /*Optical module not supported*/) // Input from PMD to indicate presence of optical input.
      );
   
      simple_gemac_wrapper #(.RX_FLOW_CTRL(0), .PORTNUM(PORTNUM)) simple_gemac_wrapper_i
      (
         .clk125(gmii_clk),
         .reset(areset),

         .GMII_GTX_CLK(),
         .GMII_TX_EN(gmii_tx_en),
         .GMII_TX_ER(gmii_tx_er),
         .GMII_TXD(gmii_txd),
         .GMII_RX_CLK(gmii_clk),
         .GMII_RX_DV(gmii_rx_dv),
         .GMII_RX_ER(gmii_rx_er),
         .GMII_RXD(gmii_rxd),

         .sys_clk(bus_clk),
         .rx_tdata(m_axis_tdata),
         .rx_tuser(m_axis_tuser),
         .rx_tlast(m_axis_tlast),
         .rx_tvalid(m_axis_tvalid),
         .rx_tready(m_axis_tready),
         .tx_tdata(s_axis_tdata),
         .tx_tuser(s_axis_tuser),
         .tx_tlast(s_axis_tlast),
         .tx_tvalid(s_axis_tvalid),
         .tx_tready(s_axis_tready),
         // MDIO
         .mdc(mdc),
         .mdio_in(mdio_in),
         .mdio_out(mdio_out),
         .mdio_tri(),
         // Wishbone I/F
         .wb_clk_i(bus_clk_div2),
         .wb_rst_i(bus_rst_div2),
         .wb_adr_i(wb_adr_i),
         .wb_cyc_i(wb_cyc_i),
         .wb_dat_i(wb_dat_o),
         .wb_stb_i(wb_stb_i),
         .wb_we_i(wb_we_i),
         .wb_ack_o(wb_ack_o),
         .wb_dat_o(wb_dat_i),
         .wb_int_o(wb_int_o),
         // Debug
         .debug_tx(), .debug_rx()
      );

   end else if (PROTOCOL == "Aurora") begin

      //-----------------------------------------------------------------
      // Aurora
      //-----------------------------------------------------------------
      wire        au_user_clk, au_user_rst, phy_areset;
      wire [63:0] i_tdata, o_tdata;
      wire        i_tvalid, i_tready, o_tvalid;
      wire        channel_up, hard_err, soft_err;

      assign sfpp_tx_disable = 1'b0; // Always on.

      aurora_phy_x1 aurora_phy_i (
         // Resets
         .areset(areset | phy_areset),
         // Clocks
         .refclk(gt_refclk),
         .init_clk(misc_clk),
         .user_clk(au_user_clk),
         .user_rst(au_user_rst),
         // GTX Serial I/O
         .tx_p(txp),
         .tx_n(txn),
         .rx_p(rxp),
         .rx_n(rxn),
         // AXI4-Stream TX Interface
         .s_axis_tdata(i_tdata),
         .s_axis_tvalid(i_tvalid),
         .s_axis_tready(i_tready),
         // AXI4-Stream RX Interface
         .m_axis_tdata(o_tdata),
         .m_axis_tvalid(o_tvalid),
         // AXI4-Lite Config Interface: TODO: Hook up to WB->AXI4Lite converter
         .s_axi_awaddr(32'h0),
         .s_axi_araddr(32'h0),
         .s_axi_awvalid(1'b0),
         .s_axi_awready(),
         .s_axi_wdata(32'h0),
         .s_axi_wvalid(1'b0),
         .s_axi_wstrb(1'b0),
         .s_axi_wready(),
         .s_axi_bvalid(),
         .s_axi_bresp(),
         .s_axi_bready(1'b1),
         .s_axi_arready(),
         .s_axi_arvalid(1'b0),
         .s_axi_rdata(),
         .s_axi_rvalid(),
         .s_axi_rresp(),
         .s_axi_rready(1'b1),
         // Status and Error Reporting Interface
         .channel_up(channel_up),
         .hard_err(hard_err),
         .soft_err(soft_err)
      );

      assign phy_status = {14'd0, hard_err, channel_up};

      wire           bist_gen_en, bist_checker_en, bist_loopback_en;
      wire           bist_checker_locked;
      wire [4:0]     bist_gen_rate;
      wire [47:0]    bist_checker_samps, bist_checker_errors;
      wire [31:0]    overruns, checksum_errors;

      aurora_axis_mac aurora_mac_i (
         // Clocks and resets
         .phy_clk(au_user_clk), .phy_rst(au_user_rst),
         .sys_clk(bus_clk), .sys_rst(bus_rst),
         // PHY Interface (Synchronous to phy_clk)
         .phy_s_axis_tdata(o_tdata),
         .phy_s_axis_tvalid(o_tvalid),
         .phy_m_axis_tdata(i_tdata),
         .phy_m_axis_tvalid(i_tvalid),
         .phy_m_axis_tready(i_tready),
         // User Interface (Synchronous to sys_clk)
         .s_axis_tdata(s_axis_tdata),
         .s_axis_tlast(s_axis_tlast),
         .s_axis_tvalid(s_axis_tvalid),
         .s_axis_tready(s_axis_tready),
         .m_axis_tdata(m_axis_tdata),
         .m_axis_tlast(m_axis_tlast),
         .m_axis_tvalid(m_axis_tvalid),
         .m_axis_tready(m_axis_tready),
         // PHY Status Inputs (Synchronous to phy_clk)
         .channel_up(channel_up),
         .hard_err(hard_err),
         .soft_err(soft_err),
         // Status and Error Outputs (Synchronous to sys_clk)
         .overruns(overruns),
         .soft_errors(),
         .checksum_errors(checksum_errors),
         // BIST Interface (Synchronous to sys_clk)
         .bist_gen_en(bist_gen_en),
         .bist_gen_rate(bist_gen_rate),
         .bist_checker_en(bist_checker_en),
         .bist_loopback_en(bist_loopback_en),
         .bist_checker_locked(bist_checker_locked),
         .bist_checker_samps(bist_checker_samps),
         .bist_checker_errors(bist_checker_errors)
      );

      assign m_axis_tuser = 4'd0;

      wire        set_stb;
      wire [3:0]  set_addr, rb_addr;
      wire [31:0] set_data;
      reg  [31:0] rb_data;

      settings_bus #(.AWIDTH(8), .DWIDTH(32), .SWIDTH(4)) settings_bus_i (
         .wb_clk(bus_clk), .wb_rst(bus_rst),
         .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i),
         .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i), .wb_ack_o(wb_ack_o),
         .strobe(set_stb), .addr(set_addr), .data(set_data)
      );

      settings_readback #(.AWIDTH(8),.DWIDTH(32), .RB_ADDRW(4)) settings_readback_i (
         .wb_clk(bus_clk), .wb_rst(bus_rst),
         .wb_adr_i(wb_adr_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i), .wb_dat_o(wb_dat_o),
         .rb_data(rb_data), .rb_addr(rb_addr), .rb_rd_stb()
      );

      setting_reg #(.my_addr(4'd0), .awidth(4), .width(9), .at_reset(9'h000)) set_core_control_i (
         .clk(bus_clk), .rst(bus_rst),
         .strobe(set_stb), .addr(set_addr), .in(set_data),
         .out({phy_areset, bist_gen_rate, bist_loopback_en, bist_gen_en, bist_checker_en}), .changed()
      );

      wire channel_up_bclk, hard_err_bclk, soft_err_bclk;
      synchronizer #(.INITIAL_VAL(1'b0)) channel_up_sync (
         .clk(bus_clk), .rst(1'b0 /* no reset */), .in(channel_up), .out(channel_up_bclk));
      synchronizer #(.INITIAL_VAL(1'b0)) hard_err_sync (
         .clk(bus_clk), .rst(1'b0 /* no reset */), .in(hard_err), .out(hard_err_bclk));
      synchronizer #(.INITIAL_VAL(1'b0)) soft_err_sync (
         .clk(bus_clk), .rst(1'b0 /* no reset */), .in(soft_err), .out(soft_err_bclk));

      reg [19:0]  bist_lock_latency;
      always @(posedge bus_clk) begin
         if (!bist_checker_en && !bist_checker_locked)
            bist_lock_latency <= 20'd0;
         else if (bist_checker_en && !bist_checker_locked)
            bist_lock_latency <= bist_lock_latency + 20'd1;
      end

      wire [31:0] core_status = {
         checksum_errors[11:0],     //[31:20]
         bist_lock_latency[19:4],   //[19:4]
         bist_checker_locked,       //[3]
         soft_err_bclk,             //[2]
         hard_err_bclk,             //[1]
         channel_up_bclk            //[0]
      };

      always @(*)
         case (rb_addr)
            4'd0:    rb_data = core_status;
            4'd1:    rb_data = overruns;
            4'd2:    rb_data = bist_checker_samps[47:16];   //Scale num sample by 2^16
            4'd3:    rb_data = bist_checker_errors[31:0];   //Dont scale errors
            default: rb_data = 32'h0;
         endcase // case (rb_addr)

   end else begin

      //Invalid protocol

   end
endgenerate

endmodule

