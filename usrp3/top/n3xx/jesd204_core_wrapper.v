//////////////////////////////////////
//
//  2017 Ettus Research
//
//////////////////////////////////////

module jesd204_core_wrapper #(
  parameter REG_BASE    = 0,
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 16  // Width of the address bus
)(
  input         db_fpga_clk_p,
  input         db_fpga_clk_n,
  output        sample_clk,
  input         clk40,

  input         s_axi_aclk,
  input         s_axi_aresetn,
  // Regport access
  input [31:0]  s_axi_awaddr,
  input         s_axi_awvalid,
  output        s_axi_awready,

  input [31:0]  s_axi_wdata,
  input [3:0]   s_axi_wstrb,
  input         s_axi_wvalid,
  output        s_axi_wready,

  output [1:0]  s_axi_bresp,
  output        s_axi_bvalid,
  input         s_axi_bready,

  input [31:0]  s_axi_araddr,
  input         s_axi_arvalid,
  output        s_axi_arready,

  output [31:0] s_axi_rdata,
  output [1:0]  s_axi_rresp,
  output        s_axi_rvalid,
  input         s_axi_rready,

  // JESD204
  output [31:0] rx0,
  output [31:0] rx1,
  output        rx_stb,

  input  [31:0] tx0,
  input  [31:0] tx1,
  output        tx_stb,

  output        lmk_sync,
  output reg    myk_reset,

  output        jesd_dac_sync,
  output        jesd_adc_sync,

  input         jesd_refclk_p,
  input         jesd_refclk_n,

  input  [3:0]  jesd_adc_rx_p,
  input  [3:0]  jesd_adc_rx_n,
  output [3:0]  jesd_dac_tx_p,
  output [3:0]  jesd_dac_tx_n,

  output        myk_adc_sync_p,
  output        myk_adc_sync_n,
  input         myk_dac_sync_p,
  input         myk_dac_sync_n,

  input         fpga_sysref_p,
  input         fpga_sysref_n
);

  //////////////////////////////////////////////////////////////////////////////////////////////
  //
  // AXI-Lite interface to NI Regport
  //
  //////////////////////////////////////////////////////////////////////////////////////////////

  wire                  reg_port_rd;
  wire                  reg_port_wr;
  wire [REG_AWIDTH-1:0] reg_port_addr;
  wire [REG_DWIDTH-1:0] reg_port_wr_data;
  wire [REG_DWIDTH-1:0] reg_port_rd_data;
  wire                  reg_port_ready;
  wire [REG_DWIDTH-1:0] reg_port_rd_data_jesd;
  wire                  reg_port_ready_jesd;
  reg  [REG_DWIDTH-1:0] reg_port_rd_data_glob;
  reg                   reg_port_ready_glob;

  axil_to_ni_regport #(
    .RP_DWIDTH   (REG_DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64) //FIXME
    .RP_AWIDTH   (REG_AWIDTH),                 // Width of the address bus
    .TIMEOUT     (512)
  ) ni_regport_inst (
    // Clock and reset
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_areset  (~s_axi_aresetn),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    // Register port
    .reg_port_in_rd    (reg_port_rd),
    .reg_port_in_wt    (reg_port_wr),
    .reg_port_in_addr  (reg_port_addr),
    .reg_port_in_data  (reg_port_wr_data),
    .reg_port_out_data (reg_port_rd_data),
    .reg_port_out_ready(reg_port_ready)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////
  //
  // JESD and Clocking Registers
  //
  //////////////////////////////////////////////////////////////////////////////////////////////

  localparam REG_RADIO_CLK_CTRL     = REG_BASE + 'h0000;
  localparam REG_JESD_REFCLK        = REG_BASE + 'h0004;
  localparam REG_MYK_RESET          = REG_BASE + 'h0008;

  // Clocking Registers
  reg  radio_clk1x_enable;
  reg  radio_clk2x_enable;
  reg  radio_clk3x_enable;
  reg  radio_clk_mmcm_reset;
  wire jesd_refclk_present;  //Read only

  wire radio_clks_valid;
  wire fpga_clks_stable;
  wire sample_clk_1x;
  wire sample_clk_2x;

  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      radio_clk1x_enable   <= 1'b0;
      radio_clk2x_enable   <= 1'b0;
      radio_clk3x_enable   <= 1'b0;
      radio_clk_mmcm_reset <= 1'b1;
      reg_port_ready_glob  <= 1'b0;
      myk_reset            <= 1'b0; //Active Low reset
    end else begin
      if (reg_port_wr) begin
      reg_port_ready_glob <= 1'b1;
        case ({2'b0,reg_port_addr})
          REG_RADIO_CLK_CTRL : begin
            radio_clk1x_enable   <= reg_port_wr_data[0];
            radio_clk2x_enable   <= reg_port_wr_data[1];
            radio_clk3x_enable   <= reg_port_wr_data[2];
            radio_clk_mmcm_reset <= reg_port_wr_data[3];
          end
          REG_MYK_RESET :
            myk_reset            <= reg_port_wr_data[0];
        endcase
      end
    end
    if (reg_port_rd) begin
      reg_port_ready_glob <= 1'b1;
      case ({2'b0,reg_port_addr})
        REG_RADIO_CLK_CTRL :
          reg_port_rd_data_glob <= {27'b0, radio_clks_valid,     // Bit 4
                                           radio_clk_mmcm_reset, // Bit 3
                                           radio_clk3x_enable,   // Bit 2
                                           radio_clk2x_enable,   // Bit 1
                                           radio_clk1x_enable};  // Bit 0
        REG_JESD_REFCLK :
          reg_port_rd_data_glob <= {31'b0, jesd_refclk_present};
        REG_MYK_RESET :
          reg_port_rd_data_glob <= {31'b0, myk_reset};
        default :
          reg_port_rd_data_glob <= 32'b0;
      endcase
    end else
      reg_port_rd_data_glob <= 32'b0;
  end

  assign reg_port_ready = reg_port_ready_jesd & reg_port_ready_glob;
  assign reg_port_rd_data = reg_port_rd_data_jesd | reg_port_rd_data_glob;
  assign sample_clk = sample_clk_1x;
  assign fpga_clks_stable = radio_clks_valid & radio_clk1x_enable & radio_clk2x_enable;

  ////////////////////////////////////////////////////////////////////
  //
  // Generate Radio Clocks from DBA_FPGA_CLK_P/N
  // Input clk can be 122.88MHz, 125MHz or 153.6MHz
  //
  //----------------------------------------------------------------------------
  //  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
  //   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
  //----------------------------------------------------------------------------
  // CLK_OUT1_____0.000_______0.000______50.0_______0.00________0.00
  // CLK_OUT2_____0.000_______0.000______50.0_______0.00________0.00
  // CLK_OUT3_____0.000_______0.000______50.0_______0.00________0.00
  //
  //----------------------------------------------------------------------------
  // Input Clock   Freq (MHz)    Input Jitter (UI)
  //----------------------------------------------------------------------------
  // __primary_________125.000____________0.00
  //
  ////////////////////////////////////////////////////////////////////

  // Radio Clock Generation


  RadioClocking radio_clocking_inst
  (
    .aReset(~s_axi_aresetn),
    .BusClk(s_axi_aclk),
    .aRadioClkMmcmReset(radio_clk_mmcm_reset),   //Async reset to the RadioClkMmcm. driven by the RegPort
    .bRadioClk1xEnabled(radio_clk1x_enable),
    .bRadioClk2xEnabled(radio_clk2x_enable),
    .bRadioClk3xEnabled(radio_clk3x_enable),
    .bRadioClksValid(radio_clks_valid),          //Locked indication from the RadioClkMmcm in BusClk and aReset domain, Toggling indicator to the Window
    .pPsInc(1'b0),                   //Phase shift interface for the RadioClkMmcm
    .pPsEn(1'b0),
    .PsClk(s_axi_aclk),
    .pPsDone(),
    .FpgaClk_n(db_fpga_clk_n),
    .FpgaClk_p(db_fpga_clk_p),
    .RadioClk1x(sample_clk_1x),
    .RadioClk2x(sample_clk_2x),
    .RadioClk3x()               //Open
  );

  Jesd204bXcvrCoreEttus jesd204_core
  (
      // Clocks and Reset
     .aReset(~s_axi_aresetn),                    // Async Reset
     .bReset(1'b0),                   // Sync Reset for regport = FALSE
     .BusClk(s_axi_aclk),                   // Register bus and General Control
     .ReliableClk40(clk40),              // Must be stable BEFORE everything = 40 MHz clock //FIXME
     .FpgaClk1x(sample_clk_1x),          // 1x Sample Clock through MMCM and bufg
     .FpgaClk2x(sample_clk_2x),          // 2x Sample Clock through MMCM and bufg
     .bFpgaClksStable(fpga_clks_stable), // Assert this after both FPGA clocks are stable

     // Register Interface
     .bRegPortInAddress({2'b0,reg_port_addr}),  // Input regport address [15:0]
     .bRegPortInData(reg_port_wr_data),  // Input regport data [31:0]
     .bRegPortInRd(reg_port_rd),         // Input read strobe
     .bRegPortInWt(reg_port_wr),         // Input write strobe
     .bRegPortOutData(reg_port_rd_data_jesd), // Output read data [31:0]
     .bRegPortOutReady(reg_port_ready_jesd),  // Ready to accept

     .aLmkSync(lmk_sync),                // FIXME: Hardcoded to CPLD : OK for bringup.
     .fSysRef(),                         // open?

     // I/O interface
     .JesdRefClk_p(jesd_refclk_p),       // MGT reference clock - USRPIO_A_MGTCLK_P
     .JesdRefClk_n(jesd_refclk_n),       // MGT reference clock - USRPIO_A_MGTCLK_N
     .bJesdRefClkPresent(jesd_refclk_present), // ? //Clock status //FIXME - add to regs
     .aAdcRx_p(jesd_adc_rx_p),           // [3:0] USRPIO_A_RX_P
     .aAdcRx_n(jesd_adc_rx_n),           // [3:0] USRPIO_A_RX_N
     .aSyncAdcOut_p(myk_adc_sync_p),     // Sync Output for ADC_P - DbaMykSyncIn_p
     .aSyncAdcOut_n(myk_adc_sync_n),     // Sync Output for ADC_N - DbaMykSyncIn_n
     .aDacTx_p(jesd_dac_tx_p),           // [3:0] USRPIO_A_TX_P
     .aDacTx_n(jesd_dac_tx_n),           // [3:0] USRPIO_A_TX_N
     .aSyncDacIn_p(myk_dac_sync_p),      // Sync Input for DAC_P - DbaMykSyncOut_p
     .aSyncDacIn_n(myk_dac_sync_n),      // Sync Input for DAC_N - DbaMykSyncOut_n
     .fSysRefFpgaLvds_p(fpga_sysref_p),  // DbaFpgaSysref_p
     .fSysRefFpgaLvds_n(fpga_sysref_n),  // DbaFpgaSysref_n

     // Data Interface
     .fAdc0DataI(rx0[31:16]),
     .fAdc0DataQ(rx0[15:0]),
     .fAdc1DataI(rx1[31:16]),
     .fAdc1DataQ(rx1[15:0]),
     .fAdcDataValid(rx_stb),             // rx_stb //FIXME // 1 bit
     .fDac0DataI(tx0[31:16]),
     .fDac0DataQ(tx0[15:0]),
     .fDac1DataI(tx1[31:16]),
     .fDac1DataQ(tx1[15:0]),
     .fDacReadyForInput(tx_stb),         // tx_stb //FIXME

     // Data Manipulation Interface
     .bDac0DataSettingsInvertA(1'b0),    // Bit-wise inversion of the *DataI signal
     .bDac0DataSettingsInvertB(1'b0),    // Bit-wise inversion of the *DataQ signal
     .bDac0DataSettingsZeroA(1'b0),      // Zeros out the *DataI signal
     .bDac0DataSettingsZeroB(1'b0),      // Zeros out the *DataQ signal
     .bDac0DataSettingsAisI(1'b1),       // Swap I and Q
     .bDac0DataSettingsBisQ(1'b1),       // Swap I and Q
     .bDac1DataSettingsInvertA(1'b0),
     .bDac1DataSettingsInvertB(1'b0),
     .bDac1DataSettingsZeroA(1'b0),
     .bDac1DataSettingsZeroB(1'b0),
     .bDac1DataSettingsAisI(1'b1),
     .bDac1DataSettingsBisQ(1'b1),
     .bAdc0DataSettingsInvertA(1'b0),
     .bAdc0DataSettingsInvertB(1'b0),
     .bAdc0DataSettingsZeroA(1'b0),
     .bAdc0DataSettingsZeroB(1'b0),
     .bAdc0DataSettingsAisI(1'b1),
     .bAdc0DataSettingsBisQ(1'b1),
     .bAdc1DataSettingsInvertA(1'b0),
     .bAdc1DataSettingsInvertB(1'b0),
     .bAdc1DataSettingsZeroA(1'b0),
     .bAdc1DataSettingsZeroB(1'b0),
     .bAdc1DataSettingsAisI(1'b1),
     .bAdc1DataSettingsBisQ(1'b1),

     // Sync
     .aDacSync(jesd_dac_sync),
     .aAdcSync(jesd_adc_sync)
  );

endmodule
