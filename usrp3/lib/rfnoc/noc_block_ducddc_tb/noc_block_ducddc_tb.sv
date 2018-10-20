//
// Copyright 2016 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define SIM_RUNTIME_US 10000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 3

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_ducddc_tb();
  `TEST_BENCH_INIT("noc_block_ducddc_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/200e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/215e6);
  localparam NUM_CE         = 2;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_ducddc, 0 /* xbar port 0 */);
  `RFNOC_ADD_BLOCK(noc_block_fft, 1 /* xbar port 1 */);

  // FFT specific settings
  localparam [15:0] FFT_SIZE = 256;
  wire [7:0] fft_size_log2   = $clog2(FFT_SIZE);        // Set FFT size
  wire fft_direction         = 0;                       // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale      = 12'b101010101010;        // Conservative scaling of 1/N
  wire [1:0] fft_shift       = 2'b00;                   // FFT shift + don't reverse
  int duc_num_hb; //default 2
  int duc_cic_max_interp; //default 16
  int ddc_num_hb; //default 2
  int ddc_cic_max_decim; //default 16

  wire [7:0] SR_SPP_OUT              = noc_block_ducddc.SR_SPP_OUT;
  wire [7:0] SR_N_ADDR               = noc_block_ducddc.SR_N_ADDR;
  wire [7:0] SR_M_ADDR               = noc_block_ducddc.SR_M_ADDR;
  wire [7:0] SR_CONFIG_ADDR          = noc_block_ducddc.SR_CONFIG_ADDR;

  // DUC
  wire [7:0] SR_DUC_FREQ_ADDR        = noc_block_ducddc.SR_DUC_FREQ_ADDR;
  wire [7:0] SR_DUC_INTERP_ADDR      = noc_block_ducddc.SR_DUC_INTERP_ADDR;
  wire [7:0] SR_DUC_SCALE_IQ_ADDR    = noc_block_ducddc.SR_DUC_SCALE_IQ_ADDR;
  wire [7:0] RB_DUC_NUM_HB           = noc_block_ducddc.RB_DUC_NUM_HB;
  wire [7:0] RB_DUC_CIC_MAX_INTERP   = noc_block_ducddc.RB_DUC_CIC_MAX_INTERP;

  // DDC
  wire [7:0] SR_DDC_FREQ_ADDR        = noc_block_ducddc.SR_DDC_FREQ_ADDR;
  wire [7:0] SR_DDC_SCALE_IQ_ADDR    = noc_block_ducddc.SR_DDC_SCALE_IQ_ADDR;
  wire [7:0] SR_DDC_DECIM_ADDR       = noc_block_ducddc.SR_DDC_DECIM_ADDR;
  wire [7:0] SR_DDC_MUX_ADDR         = noc_block_ducddc.SR_DDC_MUX_ADDR;
  wire [7:0] SR_DDC_COEFFS_ADDR      = noc_block_ducddc.SR_DDC_COEFFS_ADDR;
  wire [7:0] RB_DDC_NUM_HB           = noc_block_ducddc.RB_DDC_NUM_HB;
  wire [7:0] RB_DDC_CIC_MAX_DECIM    = noc_block_ducddc.RB_DDC_CIC_MAX_DECIM;

  localparam SPP                 = FFT_SIZE;
  localparam PKT_SIZE_BYTES      = 4*SPP;

  /********************************************************
  ** Helper Tasks
  ********************************************************/
  task automatic set_interp_rate(input int interp_rate);
    begin
      logic [7:0] cic_rate = 8'd0;
      logic [7:0] hb_enables = 2'b0;

      int _interp_rate = interp_rate;

      // Calculate which half bands to enable and whatever is left over set the CIC
      while ((_interp_rate[0] == 0) && (hb_enables < duc_num_hb)) begin
        hb_enables += 1'b1;
        _interp_rate = _interp_rate >> 1;
      end

      // CIC rate cannot be set to 0
      cic_rate = (_interp_rate[7:0] == 8'd0) ? 8'd1 : _interp_rate[7:0];
      `ASSERT_ERROR(hb_enables <= duc_num_hb, "Enabled halfbands may not exceed total number of half bands.");
      `ASSERT_ERROR(cic_rate > 0 && cic_rate <= duc_cic_max_interp,
       "CIC Interpolation rate must be positive, not exceed the max cic interpolation rate, and cannot equal 0!");

      // Setup DUC
      $display("Set interpolation to %0d", interp_rate);
      $display("- Number of enabled HBs: %0d", hb_enables);
      $display("- CIC Rate:              %0d", cic_rate);
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_M_ADDR, interp_rate);                 // Set interpolation rate in AXI rate change
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DUC_INTERP_ADDR, {hb_enables, cic_rate}); // Enable HBs, set CIC rate
    end
  endtask

  task automatic set_decim_rate(input int decim_rate);
    begin
      logic [7:0] cic_rate = 8'd0;
      logic [1:0] hb_enables = 2'b0;

      int _decim_rate = decim_rate;

      // Calculate which half bands to enable and whatever is left over set the CIC
      while ((_decim_rate[0] == 0) && (hb_enables < ddc_num_hb)) begin
        hb_enables += 1'b1;
        _decim_rate = _decim_rate >> 1;
      end
      // CIC rate cannot be set to 0
      cic_rate = (_decim_rate[7:0] == 8'd0) ? 8'd1 : _decim_rate[7:0];
      `ASSERT_ERROR(hb_enables <= ddc_num_hb, "Enabled halfbands may not exceed total number of half bands.");
      `ASSERT_ERROR(cic_rate > 0 && cic_rate <= ddc_cic_max_decim,
      "CIC Decimation rate must be positive, not exceed the max cic decimation rate, and cannot equal 0!");

      // Setup DDC
      $display("Set decimation to %0d", decim_rate);
      $display("- Number of enabled HBs: %0d", hb_enables);
      $display("- CIC Rate:              %0d", cic_rate);
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_N_ADDR, decim_rate);                  // Set decimation rate in AXI rate change
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DDC_DECIM_ADDR, {hb_enables,cic_rate});   // Enable HBs, set CIC rate

    end
  endtask

  task automatic send_ones_upsample(input int interp_rate,  input int decim_rate);
    begin
      set_decim_rate(decim_rate);
      set_interp_rate(interp_rate);

      tb_streamer.write_reg(sid_noc_block_ducddc, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB

      // Setup DUC
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DUC_FREQ_ADDR, 32'd0);                // CORDIC phase increment
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DUC_SCALE_IQ_ADDR, (1 << 14)); // Scaling, set to 1

      // Setup DDC
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DDC_FREQ_ADDR, 32'd0);                // CORDIC phase increment
      tb_streamer.write_reg(sid_noc_block_ducddc, SR_DDC_SCALE_IQ_ADDR, (1 << 14)); // Scaling, set to 1

      fork
        begin
          cvita_payload_t send_payload;
          cvita_metadata_t md;
          int delay;

          $display("Send ones");
          for (int i = 0; i < PKT_SIZE_BYTES/8; i++) begin
            send_payload.push_back({16'h0fff, 16'h0fff, 16'h0fff, 16'h0fff});
          end
          md.eob = 1;

          tb_streamer.send(send_payload, md);
          $display("Send ones complete");
        end
        begin
          string s;
          logic [63:0] samples;
          cvita_payload_t recv_payload;
          cvita_metadata_t md;

          $display("Check incoming samples");
          for (int i = 0; i < interp_rate/decim_rate; i++) begin
            tb_streamer.recv(recv_payload, md);
            $sformat(s, " -- rcv packet with size %d", recv_payload.size()); $display(s);
            $sformat(s, "incorrect (drop) packet size! expected: %0d, actual: %0d", PKT_SIZE_BYTES/8, recv_payload.size());
            `ASSERT_ERROR(recv_payload.size() == PKT_SIZE_BYTES/8, s);

            samples = 64'd0;
            for (int j = 0; j < PKT_SIZE_BYTES/8; j++) begin
              samples = recv_payload[j];
              $sformat(s, "Ramp word %0d invalid! Expected a real value, Received: %0d", 2*j, samples);
              `ASSERT_ERROR(samples >= 0, s);
            end
          end
          $display("Check complete");
        end
      join
    end
  endtask

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] resp;
    string s;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC IDs");

    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_ducddc, RB_NOC_ID, resp);
    $display("Read DUCDDC NOC ID: %16x", resp);
    `ASSERT_FATAL(resp == noc_block_ducddc.NOC_ID, "Incorrect NOC ID");
     //readback regs
    tb_streamer.read_user_reg(sid_noc_block_ducddc, RB_DUC_NUM_HB, duc_num_hb);
    $display("DUC_NUM_HB = %d", duc_num_hb);
    `ASSERT_FATAL(duc_num_hb > 0, "Not enough DUC halfbands");
    tb_streamer.read_user_reg(sid_noc_block_ducddc, RB_DUC_CIC_MAX_INTERP, duc_cic_max_interp);
    $display("DUC_CIC_MAX_INTERP = %d", duc_cic_max_interp);
    `ASSERT_FATAL(duc_cic_max_interp > 0, "Not enough DUC CIC interp");
    tb_streamer.read_user_reg(sid_noc_block_ducddc, RB_DDC_NUM_HB, ddc_num_hb);
    $display("DDC_NUM_HB = %d", ddc_num_hb);
    `ASSERT_FATAL(ddc_num_hb > 0, "Not enough DDC halfbands");
    tb_streamer.read_user_reg(sid_noc_block_ducddc, RB_DDC_CIC_MAX_DECIM, ddc_cic_max_decim);
    $display("DDC_CIC_MAX_DECIM = %d", ddc_cic_max_decim);
    `ASSERT_FATAL(ddc_cic_max_decim > 0, "Not enough DDC CIC interp");

    tb_streamer.write_reg(sid_noc_block_ducddc, SR_SPP_OUT, PKT_SIZE_BYTES);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Test various interpolation rates with ones
    ********************************************************/
    `TEST_CASE_START("Interpolate by 1, 2, 3, 4");
    `RFNOC_CONNECT(noc_block_tb, noc_block_ducddc, SC16, SPP);
    `RFNOC_CONNECT(noc_block_ducddc, noc_block_tb, SC16, SPP);

    send_ones_upsample(1, 1);
    send_ones_upsample(2, 2);
    // send_ones_upsample(2, 1);
    send_ones_upsample(3, 1);
    send_ones_upsample(4, 1);
    send_ones_upsample(4, 2);
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end
endmodule
