//
// Copyright 2015 Ettus Research LLC
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 100000000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_ddc_tb();
  `TEST_BENCH_INIT("noc_block_ddc_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 2;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_ddc, 0 /* xbar port 0 */);
  `RFNOC_ADD_BLOCK(noc_block_fft, 1 /* xbar port 1 */);

  // FFT specific settings
  localparam [15:0] FFT_SIZE = 256;
  wire [7:0] fft_size_log2   = $clog2(FFT_SIZE);        // Set FFT size
  wire fft_direction         = 0;                       // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale      = 12'b011010101010;        // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word  = {fft_scale, fft_direction, fft_size_log2};

  // DDC
  wire [7:0] SR_N_ADDR           = noc_block_ddc.gen_ddc_chains[0].axi_rate_change.SR_N_ADDR;
  wire [7:0] SR_M_ADDR           = noc_block_ddc.gen_ddc_chains[0].axi_rate_change.SR_M_ADDR;
  wire [7:0] SR_CONFIG_ADDR      = noc_block_ddc.gen_ddc_chains[0].axi_rate_change.SR_CONFIG_ADDR;
  wire [7:0] SR_FREQ_ADDR        = noc_block_ddc.gen_ddc_chains[0].ddc.SR_FREQ_ADDR;
  wire [7:0] SR_SCALE_IQ_ADDR    = noc_block_ddc.gen_ddc_chains[0].ddc.SR_SCALE_IQ_ADDR;
  wire [7:0] SR_DECIM_ADDR       = noc_block_ddc.gen_ddc_chains[0].ddc.SR_DECIM_ADDR;
  wire [7:0] SR_MUX_ADDR         = noc_block_ddc.gen_ddc_chains[0].ddc.SR_MUX_ADDR;
  wire [7:0] SR_COEFFS_ADDR      = noc_block_ddc.gen_ddc_chains[0].ddc.SR_COEFFS_ADDR;

  localparam SPP                 = FFT_SIZE;
  localparam PKT_SIZE_BYTES      = FFT_SIZE*4;

  localparam real PI             = $acos(-1.0);

  /********************************************************
  ** Helper Tasks
  ********************************************************/
  task automatic set_decim_rate(input int decim_rate);
    begin
      logic [7:0] cic_rate = 8'd0;
      logic [1:0] hb_enables = 2'b0;

      int _decim_rate = decim_rate;

      `ASSERT_ERROR(decim_rate <= 2040, "Decimation rate cannot exceed 1060!");
      `ASSERT_ERROR((decim_rate <= 510) ||
                    (decim_rate > 511  && decim_rate[1:0] == 2'b0 && decim_rate <= 1020) || // Only rates div 4 work
                    (decim_rate > 1020 && decim_rate[2:0] == 3'b0 && decim_rate <= 2040),  // Only rates div 8
                    "Invalid decimation rate!");
      `ASSERT_ERROR(decim_rate > 0, "Decimation rate must be positive and cannot equal 0!");

      // Calculate which half bands to enable and whatever is left over set the CIC
      while ((_decim_rate[0] == 0) && (hb_enables < 3)) begin
        hb_enables += 1'b1;
        _decim_rate = _decim_rate >> 1;
      end
      // CIC rate cannot be set to 0
      cic_rate = (_decim_rate[7:0] == 8'd0) ? 8'd1 : _decim_rate[7:0];

      // Setup DDC
      $display("Set decimation to %0d", decim_rate);
      $display("- Number of enabled HBs: %0d", hb_enables);
      $display("- CIC Rate:              %0d", cic_rate);
      tb_streamer.write_reg(sid_noc_block_ddc, SR_N_ADDR, decim_rate);                  // Set decimation rate in AXI rate change
      tb_streamer.write_reg(sid_noc_block_ddc, SR_DECIM_ADDR, {hb_enables,cic_rate});   // Enable HBs, set CIC rate

    end
  endtask

  task automatic send_ramp (
    input int unsigned decim_rate,
    // (Optional) For testing passing through partial packets
    input logic drop_partial_packet = 1'b0,
    input int unsigned extra_samples = 0);
    begin
      set_decim_rate(decim_rate);

      // Setup DDC
      tb_streamer.write_reg(sid_noc_block_ddc, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB
      tb_streamer.write_reg(sid_noc_block_ddc, SR_FREQ_ADDR, 32'd0);                // CORDIC phase increment
      tb_streamer.write_reg(sid_noc_block_ddc, SR_SCALE_IQ_ADDR, (1 << 14) + 3515); // Scaling, set to 1

      // Send a short ramp, should pass through unchanged
      fork
        begin
          cvita_payload_t send_payload;
          cvita_metadata_t md;
          $display("Send ramp");
          for (int i = 0; i < decim_rate*(PKT_SIZE_BYTES/8 + extra_samples); i++) begin
            send_payload.push_back({16'(2*i/decim_rate), 16'(2*i/decim_rate), 16'((2*i+1)/decim_rate), 16'((2*i+1)/decim_rate)});
          end
          md.eob = 1;
          tb_streamer.send(send_payload,md);
          $display("Send ramp complete");
        end
        begin
          string s;
          logic [63:0] samples, samples_old;
          cvita_payload_t recv_payload, temp_payload;
          cvita_metadata_t md;
          logic eob;
          $display("Check ramp");
          if (~drop_partial_packet && (extra_samples > 0)) begin
            tb_streamer.recv(temp_payload,md);
            $sformat(s, "Invalid EOB state! Expected %b, Received: %b", 1'b0, md.eob);
            `ASSERT_ERROR(md.eob == 1'b0, s);
          end
          tb_streamer.recv(recv_payload,md);
          $sformat(s, "Invalid EOB state! Expected %b, Received: %b", 1'b1, md.eob);
          `ASSERT_ERROR(md.eob == 1'b1, s);
          recv_payload = {temp_payload, recv_payload};
          if (drop_partial_packet) begin
            $sformat(s, "Incorrect packet size! Expected: %0d, Actual: %0d", PKT_SIZE_BYTES/8, recv_payload.size());
            `ASSERT_ERROR(recv_payload.size() == PKT_SIZE_BYTES/8, s);
          end else begin
            $sformat(s, "Incorrect packet size! Expected: %0d, Actual: %0d", PKT_SIZE_BYTES/8, recv_payload.size() + extra_samples);
            `ASSERT_ERROR(recv_payload.size() == PKT_SIZE_BYTES/8 + extra_samples, s);
          end
          samples = 64'd0;
          samples_old = 64'd0;
          for (int i = 0; i < PKT_SIZE_BYTES/8; i++) begin
            samples = recv_payload[i];
            for (int j = 0; j < 4; j++) begin
              // Need to check a range of values due to imperfect gain compensation
              $sformat(s, "Ramp word %0d invalid! Expected: %0d-%0d, Received: %0d", 2*i,
                  samples_old[16*j +: 16], samples_old[16*j +: 16]+16'd4, samples[16*j +: 16]);
              `ASSERT_ERROR((samples_old[16*j +: 16]+16'd4 >= samples[16*j +: 16]) && (samples >= samples_old[16*j +: 16]), s);
            end
            samples_old = samples;
          end
          $display("Check complete");
        end
      join
    end
  endtask

  task automatic calc_freq_resp (input int decim_rate[$]);
    begin
      int fd;
      string s;
      real freq_resp[0:FFT_SIZE/2-1];
      real phase_resp[0:FFT_SIZE/2-1];
      cvita_payload_t send_payload, recv_payload;
      cvita_metadata_t md;
      real re, im, mag, mag_new, phase;

      `RFNOC_CONNECT(noc_block_tb, noc_block_ddc, SC16, SPP);
      `RFNOC_CONNECT(noc_block_ddc, noc_block_fft, SC16, SPP);
      `RFNOC_CONNECT(noc_block_fft, noc_block_tb, SC16, SPP);

      // Setup DDC
      tb_streamer.write_reg(sid_noc_block_ddc, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB
      tb_streamer.write_reg(sid_noc_block_ddc, SR_FREQ_ADDR, 32'd0);                // CORDIC phase increment
      tb_streamer.write_reg(sid_noc_block_ddc, SR_SCALE_IQ_ADDR, (1 << 14) + 3515); // Scaling, set to 1
      // Setup FFT
      tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word});  // Configure FFT core
      tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SIZE_LOG2, fft_size_log2);             // Set FFT size register
      tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_MAGNITUDE_OUT, noc_block_fft.COMPLEX_OUT); // Enable complex out

      for (int k = 0; k < decim_rate.size(); k++) begin
        set_decim_rate(decim_rate[k]);
        // Send bin centered tones through DDC and FFT
        for (int i = 0; i < FFT_SIZE/2; i++) begin
          send_payload.delete();
          for (int j = 0; j < 4*decim_rate[k]*PKT_SIZE_BYTES/8; j += 2) begin
            send_payload.push_back({shortint'((2**15-1)*$sin(2.0*PI*j*i/(FFT_SIZE-1))),
                                    shortint'((2**15-1)*$cos(2.0*PI*j*i/(FFT_SIZE-1))),
                                    shortint'((2**15-1)*$sin(2.0*PI*(j+1)*i/(FFT_SIZE-1))),
                                    shortint'((2**15-1)*$cos(2.0*PI*(j+1)*i/(FFT_SIZE-1)))});
          end
          tb_streamer.send(send_payload,'{eob:1, default:0});
          md.eob = 0;
          while (~md.eob) tb_streamer.recv(recv_payload,md);
          $sformat(s, "Incorrect number of samples! Expected: %0d, Actual: %0d", FFT_SIZE, 2*recv_payload.size());
          `ASSERT_ERROR(recv_payload.size() == FFT_SIZE/2, s);
          mag = 0;
          for (int j = 0; j < recv_payload.size; j++) begin
            for (int k = 0; k < 2; k++) begin
              re      = real'($signed(recv_payload[j][16*(2*k+1) +: 16]));
              im      = real'($signed(recv_payload[j][16*(2*k)   +: 16]));
              mag_new = $sqrt(re**2 + im**2);
              if (mag < mag_new) begin
                mag   = mag_new;
                phase = $atan2(re,im);
              end
            end
          end
          freq_resp[i]  = mag;
          phase_resp[i] = phase;
        end
        // Write to disk
        $sformat(s, "freq_resp_%0d.csv", k);
        fd = $fopen(s);
        for (int l = 0; l < FFT_SIZE/2-1; l++) begin
          $fdisplay(fd, "%0d,%5.4f,%1.4f", l, freq_resp[l], phase_resp[l]);
        end
        $fclose(fd);
      end
    end
  endtask

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] resp;
    string s;
    real freq_resp[0:FFT_SIZE/2-1];
    real phase_resp[0:FFT_SIZE/2-1];

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
    tb_streamer.read_reg(sid_noc_block_fft, RB_NOC_ID, resp);
    $display("Read FFT NOC ID: %16x", resp);
    `ASSERT_FATAL(resp == noc_block_fft.NOC_ID, "Incorrect NOC ID");
    tb_streamer.read_reg(sid_noc_block_ddc, RB_NOC_ID, resp);
    $display("Read DDC NOC ID: %16x", resp);
    `ASSERT_FATAL(resp == noc_block_ddc.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Test various decimation rates
    ********************************************************/
    `TEST_CASE_START("Decimate by 1, 2, 3, 4, 6, 8, 12, 13, 16, 24, 40, 255, 2040");
    $display("Note: This test will take a long time!");
    `RFNOC_CONNECT(noc_block_tb, noc_block_ddc, SC16, SPP);
    `RFNOC_CONNECT(noc_block_ddc, noc_block_tb, SC16, SPP);
    // List of rates to catch most issues
    send_ramp(1);    // HBs enabled: 0, CIC rate: 1
    send_ramp(2);    // HBs enabled: 1, CIC rate: 1
    send_ramp(3);    // HBs enabled: 0, CIC rate: 3
    send_ramp(4);    // HBs enabled: 2, CIC rate: 1
    send_ramp(6);    // HBs enabled: 1, CIC rate: 3
    send_ramp(8);    // HBs enabled: 3, CIC rate: 1
    send_ramp(12);   // HBs enabled: 2, CIC rate: 3
    send_ramp(13);   // HBs enabled: 0, CIC rate: 13
    send_ramp(16);   // HBs enabled: 3, CIC rate: 2
    send_ramp(24);   // HBs enabled: 3, CIC rate: 3
    send_ramp(40);   // HBs enabled: 3, CIC rate: 5
    send_ramp(200); // HBs enabled: 3, CIC rate: 25
    send_ramp(255);  // HBs enabled: 0, CIC rate: 255
    send_ramp(2040); // HBs enabled: 3, CIC rate: 255
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Test timed cordic tune
    ********************************************************/
    `TEST_CASE_START("Test timed CORDIC tune");
    `RFNOC_CONNECT(noc_block_tb, noc_block_ddc, SC16, SPP);
    `RFNOC_CONNECT(noc_block_ddc, noc_block_fft, SC16, SPP);
    `RFNOC_CONNECT(noc_block_fft, noc_block_tb, SC16, SPP);
    // Configure DDC
    set_decim_rate(1);
    tb_streamer.read_user_reg(sid_noc_block_ddc, 0, resp);
    tb_streamer.write_reg(sid_noc_block_ddc, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB
    tb_streamer.write_reg(sid_noc_block_ddc, SR_SCALE_IQ_ADDR, (1 << 14) + 3515); // Scaling, set to 1
    // Configure FFT
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word});  // Configure FFT core
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SIZE_LOG2, fft_size_log2);             // Set FFT size register
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_MAGNITUDE_OUT, noc_block_fft.COMPLEX_OUT); // Enable complex out
    // Test description:
    // - Send three packets to DDC, each set to a constant value
    // - Setup a timed tune for the last two packets
    //   - CORDIC tuning will cause the DDC to output a sine tone the last two packets
    // - Route DDC output to FFT
    // - Check FFT output for DC, Fs/8, and Fs/4 tones
    fork
      begin
        // Send timed tunes
        tb_streamer.write_reg_timed(sid_noc_block_ddc, SR_FREQ_ADDR, 2**29, SPP-1); // Shift by Fs/8
        tb_streamer.write_reg_timed(sid_noc_block_ddc, SR_FREQ_ADDR, 2**30, 2*SPP-1); // Shift by Fs/4
      end
      begin
        cvita_payload_t send_payload;
        cvita_metadata_t md;
        $display("Send constant waveform");
        for (int i = 0; i < 3*(SPP/2); i++) begin
          send_payload.push_back({16'd5000, 16'd0, 16'd5000, 16'd0});
        end
        md.eob = 1;
        md.has_time = 1;
        md.timestamp = 0;
        tb_streamer.send(send_payload,md);
        $display("Send constant waveform complete");
      end
      begin
        logic [31:0] recv_word;
        logic recv_eob;
        $display("Receive & check FFT output");
        // DC
        for (int i = 0; i < 3*SPP; i++) begin
          tb_streamer.pull_word(recv_word,recv_eob);
          if (i == FFT_SIZE/2) begin
            $sformat(s, "Invalid CORDIC shift! Did not detect DC component! Expected: {5000,0}, Received: {%d,%d}", recv_word[31:16], recv_word[15:0]);
            `ASSERT_WARN(recv_word == {16'd5000,16'd0}, s);
          end else if (i == SPP+FFT_SIZE/2+FFT_SIZE/8) begin
            $sformat(s, "Invalid CORDIC shift! Did not detect tone at Fs/8! Expected: {5000,0}, Received: {%d,%d}", recv_word[31:16], recv_word[15:0]);
            `ASSERT_WARN(recv_word == {16'd5000,16'd0}, s);
          end else if (i == 2*SPP+FFT_SIZE/2+FFT_SIZE/4) begin
            $sformat(s, "Invalid CORDIC shift! Did not detect tone at Fs/4! Expected: {5000,0}, Received: {%d,%d}", recv_word[31:16], recv_word[15:0]);
            `ASSERT_WARN(recv_word == {16'd5000,16'd0}, s);
          end else begin
            $sformat(s, "Invalid CORDIC shift! Non-zero component detected at index %0d! Expected: {0,0}, Received: {%d,%d}", i, recv_word[31:16], recv_word[15:0]);
            `ASSERT_WARN(recv_word == 32'd0, s);
          end
        end
        $display("Receive & check FFT output complete");
      end
    join
    // Reset CORDIC to 0
    tb_streamer.write_reg_timed(sid_noc_block_ddc, SR_FREQ_ADDR, 0, 0);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test passing through a partial packet
    ********************************************************/
    `TEST_CASE_START("Pass through partial packet");
    `RFNOC_CONNECT(noc_block_tb, noc_block_ddc, SC16, SPP);
    `RFNOC_CONNECT(noc_block_ddc, noc_block_tb, SC16, SPP);
    send_ramp(2,0,4);
    send_ramp(3,0,4);
    send_ramp(4,0,4);
    send_ramp(8,0,4);
    send_ramp(13,0,4);
    send_ramp(24,0,4);
    `TEST_CASE_DONE(1);

    // Calculate frequency response of filters
    //calc_freq_resp('{1,2,3,4,5,6,7,8,9,10});
    `TEST_BENCH_DONE;
  end
endmodule
