//
// Copyright 2015 Ettus Research LLC
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_fft_tb();
  `TEST_BENCH_INIT("noc_block_fft_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  // Creates clocks (bus_clk, ce_clk), resets (bus_rst, ce_rst), 
  // AXI crossbar, and Export IO RFNoC block instance.
  // Export IO is a special RFNoC block used to expose the internal 
  // NoC Shell / AXI wrapper interfaces to the test bench.
  `RFNOC_SIM_INIT(1,166.67,200);
  // Instantiate & connect FFT RFNoC block
  `CONNECT_RFNOC_BLOCK(noc_block_fft,0);

  // FFT specific settings
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
    for (int l = 0; l < 10; l = l + 1) begin
      for (int k = 0; k < FFT_SIZE; k = k + 1) begin
        tb_axis_data.pull_word({real_val,cplx_val},last);
        if (k == FFT_BIN) begin
          // Assert that for the special case of a 1/8th sample rate sine wave input, 
          // the real part of the corresponding 1/8th sample rate FFT bin should always be greater than 0 and
          // the complex part equal to 0.
          `ASSERT_ERROR(real_val > 32'd0, "FFT bin real part is not greater than 0!");
          `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
        end else begin
          // Assert all other FFT bins should be 0 for both complex and real parts
          `ASSERT_ERROR(real_val == 32'd0, "FFT bin real part is not 0!");
          `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
        end
        // Check packet size via tlast assertion
        if (k == FFT_SIZE-1) begin
          `ASSERT_ERROR(last == 1'b1, "Detected late tlast!");
        end else begin
          `ASSERT_ERROR(last == 1'b0, "Detected early tlast!");
        end
      end
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
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF}});  // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});    // Command packet to set up source control window enable

    // Setup FFT flow control
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:0, sid:sid_noc_block_fft, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}});                             // Command packet to setup flow control
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF}});                              // Command packet to set up source control window size
    tb_cvita_cmd.push_pkt({header, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001}});                                // Command packet to set up source control window enable
    tb_cvita_cmd.push_pkt({header, {SR_NEXT_DST_BASE, 16'd0, sid_tb}});                                           // Set next destination
    tb_cvita_cmd.push_pkt({header, {SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word}}});                                // Configure FFT core
    tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_FFT_SIZE_LOG2, {24'd0, fft_size_log2}}});             // Set FFT size register
    tb_cvita_cmd.push_pkt({header, {24'd0, noc_block_fft.SR_MAGNITUDE_OUT, {30'd0, noc_block_fft.MAG_SQ_OUT}}});  // Enable magnitude out

    repeat (10) @(posedge bus_clk);

    // Send 1/8th sample rate sine wave
    tb_next_dst = sid_noc_block_fft;
    forever begin
      for (int i = 0; i < (FFT_SIZE/8); i = i + 1) begin
        tb_axis_data.push_word({ 16'd32767,     16'd0},0);
        tb_axis_data.push_word({ 16'd23170, 16'd23170},0);
        tb_axis_data.push_word({     16'd0, 16'd32767},0);
        tb_axis_data.push_word({-16'd23170, 16'd23170},0);
        tb_axis_data.push_word({-16'd32767,     16'd0},0);
        tb_axis_data.push_word({-16'd23170,-16'd23170},0);
        tb_axis_data.push_word({     16'd0,-16'd32767},0);
        tb_axis_data.push_word({ 16'd23170,-16'd23170},(i == (FFT_SIZE/8)-1)); // Assert tlast on final word
      end
    end
  end

endmodule