//
// Copyright 2015 Ettus Research LLC
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_conv_encoder_qpsk_tb();
  `TEST_BENCH_INIT("noc_block_conv_encoder_qpsk",`NUM_TEST_CASES,`NS_PER_TICK);
  // Creates clocks (bus_clk, ce_clk), resets (bus_rst, ce_rst), 
  // AXI crossbar, and Export IO RFNoC block instance.
  // Export IO is a special RFNoC block used to expose the internal 
  // NoC Shell / AXI wrapper interfaces to the test bench.
  `RFNOC_SIM_INIT(3,50,56);
  // Instantiate & connect FFT RFNoC block
  `CONNECT_RFNOC_BLOCK(noc_block_conv_encoder_qpsk,0);
  `CONNECT_RFNOC_BLOCK(noc_block_fir_filter,1);
  `CONNECT_RFNOC_BLOCK(noc_block_fft,2);

  // Set Convolutional Encoder parameters
  defparam noc_block_conv_encoder_qpsk.FIXED_K = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_G_UPPER = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_G_LOWER = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_PUNCTURE_CODE_RATE = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_PUNCTURE_VECTOR = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_BITS_PER_SYMBOL = 2;
  defparam noc_block_conv_encoder_qpsk.MAX_K = 7;
  defparam noc_block_conv_encoder_qpsk.MAX_BITS_PER_SYMBOL = 2;
  defparam noc_block_conv_encoder_qpsk.MAX_PUNCTURE_CODE_RATE = 7;

  // FIR Filter settings
  wire [31:0] rrc_filter_taps [40:0] = {-1368,17276,-20246,4310,25864,-32840,2186,31466,-49104,23056,
                                        62900,-97474,17128,80252,-213396,214748,478872,-1133180,-710020,5095420,
                                        9185516,5095420,-710020,-1133180,478872,214748,-213396,80252,17128,-97474,
                                        62900,23056,-49104,31466,2186,-32840,25864,4310,-20246,17276,-1368};

  // FFT settings
  localparam [15:0] FFT_SIZE = 256;
  localparam FFT_BIN = FFT_SIZE/8 + FFT_SIZE/2;       // 1/8 sample rate freq + FFT shift
  wire [7:0] fft_size_log2   = $clog2(FFT_SIZE);      // Set FFT size
  wire fft_direction         = 0;                     // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale      = 12'b011010101010;      // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word  = {fft_scale, fft_direction, fft_size_log2};

  cvita_pkt_t  pkt;
  logic [63:0] header;
  logic [15:0] real_val;
  logic [15:0] cplx_val;
  logic last;

  /********************************************************
  ** Setup RFNoC block's NoC Shell & control registers
  ** and send sine tone to FFT RFNoC block
  ********************************************************/
  initial begin : tb_main
    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    `TEST_CASE_START("Receive & check FFT data");
    forever begin
      tb_axis_data.pull_word({real_val,cplx_val},last);
    end
    `TEST_CASE_DONE(1);

  end

  /*
   * Setup RFNoC block's NoC Shell & control registers and send sine tone to FFT RFNoC block
   */
  initial begin
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);

    repeat (10) @(posedge bus_clk);

    // Setup testbench (noc_block_export_io) flow control
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:0, sid:sid_tb, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}}); // Command packet to setup flow control
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0005}});  // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});    // Command packet to set up source control window enable

    // Setup Convolutional Encoder flow control
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:0, sid:sid_noc_block_conv_encoder_qpsk, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}});                             // Command packet to setup flow control
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0005}});                              // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});                                // Command packet to set up source control window enable
    tb_cvita_cmd.push_pkt({header, {SR_NEXT_DST_BASE, 16'd0, sid_noc_block_fir_filter}});                         // Set next destination
    // Setup QPSK constellation
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b00}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {-16'sd32767,-16'sd32767}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b01}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {-16'sd32767,+16'sd32767}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b10}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {+16'sd32767,-16'sd32767}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b11}}});
    tb_cvita_cmd.push_pkt({header, {noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {+16'sd32767,+16'sd32767}}});

    // Setup FIR flow control
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:0, sid:sid_noc_block_fir_filter, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}});                             // Command packet to setup flow control
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0005}});                              // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});                                // Command packet to set up source control window enable
    tb_cvita_cmd.push_pkt({header, {SR_NEXT_DST_BASE, 16'd0, sid_noc_block_fft}});                                // Set next destination
    for (int i = 0; i < 40; i = i + 1) begin
      tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_AXI_CONFIG_BASE, {rrc_filter_taps[i]}}});           // Set FIR filter taps
    end
    tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_AXI_CONFIG_BASE+1, {rrc_filter_taps[40]}}});          // Set FIR filter taps (tlast)

    // Setup FFT flow control
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:0, sid:sid_noc_block_fft, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}});                             // Command packet to setup flow control
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0005}});                              // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});                                // Command packet to set up source control window enable
    tb_cvita_cmd.push_pkt({header, {SR_NEXT_DST_BASE, 16'd0, sid_tb}});                                           // Set next destination
    tb_cvita_cmd.push_pkt({header, {SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word}}});                                // Configure FFT core
    tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_FFT_SIZE_LOG2, {24'd0, fft_size_log2}}});             // Set FFT size register
    tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_MAGNITUDE_OUT, {30'd0, noc_block_fft.MAG_SQ_OUT}}});  // Enable magnitude out

    repeat (10) @(posedge bus_clk);

    // Send 1/8th sample rate sine wave
    tb_next_dst = sid_noc_block_conv_encoder_qpsk;
    forever begin
      for (int i = 0; i < (FFT_SIZE/2); i = i + 1) begin
        tb_axis_data.push_word({32'b1111_1111_1111_1111_0101_0101_0101_0101},0);
        tb_axis_data.push_word({32'b0000_0000_0000_0000_1010_1010_1010_1010},(i == (FFT_SIZE/2)-1)); // Assert tlast on final word
      end
    end
  end

endmodule