//
// Copyright 2016 Ettus Research
//

// TODO: This testbench needs more tests to verify
//       that the DUC has the correct output

`timescale 1ns/1ps
`define SIM_RUNTIME_US 100000000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 3

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_duc_tb();
  `TEST_BENCH_INIT("noc_block_duc_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_duc, 0 /* xbar port 0 */);

  // DUC
  wire [7:0] SR_N_ADDR      = noc_block_duc.gen_duc_chains[0].axi_rate_change.SR_N_ADDR;
  wire [7:0] SR_M_ADDR      = noc_block_duc.gen_duc_chains[0].axi_rate_change.SR_M_ADDR;
  wire [7:0] SR_CONFIG_ADDR = noc_block_duc.gen_duc_chains[0].axi_rate_change.SR_CONFIG_ADDR;
  wire [7:0] SR_PHASE_INC_ADDR = noc_block_duc.gen_duc_chains[0].duc.SR_PHASE_INC_ADDR;
  wire [7:0] SR_INTERP_ADDR = noc_block_duc.gen_duc_chains[0].duc.SR_INTERP_ADDR;
  wire [7:0] SR_SCALE_ADDR  = noc_block_duc.gen_duc_chains[0].duc.SR_SCALE_ADDR;

  localparam SPP                 = 512;
  localparam PKT_SIZE_BYTES      = 4*SPP;
  localparam MAX_DELAY           = 1000;

  /********************************************************
  ** Helper Tasks
  ********************************************************/
  task automatic set_interp_rate(input int interp_rate);
    begin
      logic [7:0] cic_rate = 8'd0;
      logic [7:0] hb_enables = 2'b0;

      int _interp_rate = interp_rate;
      `ASSERT_ERROR(interp_rate <= 512, "Interpolation rate cannot exceed 512!");
      `ASSERT_ERROR((interp_rate <= 128) || // CIC goes to 128, after that, we need either 1 or 2 halfbands
                    (interp_rate <= 256  && interp_rate[0] == 1'b0) ||
                    (interp_rate <= 512  && interp_rate[1:0] == 2'b0),
                    "Invalid interpolation rate!");

      // Calculate which half bands to enable and whatever is left over set the CIC
      while ((_interp_rate[0] == 0) && (hb_enables < 2)) begin
        hb_enables += 1'b1;
        _interp_rate = _interp_rate >> 1;
      end

      // CIC rate cannot be set to 0
      cic_rate = (_interp_rate[7:0] == 8'd0) ? 8'd1 : _interp_rate[7:0];

      // Setup DUC
      $display("Set interpolation to %0d", interp_rate);
      $display("- Number of enabled HBs: %0d", hb_enables);
      $display("- CIC Rate:              %0d", cic_rate);
      tb_streamer.write_reg(sid_noc_block_duc, SR_M_ADDR, interp_rate);                 // Set interpolation rate in AXI rate change
      tb_streamer.write_reg(sid_noc_block_duc, SR_INTERP_ADDR, {hb_enables, cic_rate}); // Enable HBs, set CIC rate
    end
  endtask

  task automatic send_ones(input int interp_rate);
    begin
      set_interp_rate(interp_rate);

      // Setup DUC
      tb_streamer.write_reg(sid_noc_block_duc, SR_CONFIG_ADDR, 32'd1);           // Enable clear EOB
      tb_streamer.write_reg(sid_noc_block_duc, SR_PHASE_INC_ADDR, 32'd0);        // CORDIC phase increment
      tb_streamer.write_reg(sid_noc_block_duc, SR_SCALE_ADDR, (1 << 14) + 3515); // Scaling, set to 1

      fork
        begin
          cvita_payload_t send_payload;
          cvita_metadata_t md;
          int delay;

          $display("Send ones");
          for (int i = 0; i < PKT_SIZE_BYTES/8; i++) begin
            send_payload.push_back({16'hffff, 16'hffff, 16'hffff, 16'hffff});
          end
          md.eob = 1;

          // Wait a random number of cycles between sending
          delay = $urandom() % MAX_DELAY;
          $display("Waiting %0d clock cycles", delay);
          #(delay)

          tb_streamer.send(send_payload, md);
          $display("Send ones complete");
        end
        begin
          string s;
          logic [63:0] samples;
          cvita_payload_t recv_payload;
          cvita_metadata_t md;

          $display("Check incoming samples");
          for (int i = 0; i < interp_rate; i++) begin
            tb_streamer.recv(recv_payload, md);
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
    tb_streamer.read_reg(sid_noc_block_duc, RB_NOC_ID, resp);
    $display("Read DUC NOC ID: %16x", resp);
    `ASSERT_FATAL(resp == noc_block_duc.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Test various interpolation rates with ones
    ********************************************************/
    `TEST_CASE_START("Interpolate by 1, 2, 3, 4, 6, 8, 12, 13, 16, 24, 40");
    $display("Note: This test will take a long time!");
    `RFNOC_CONNECT(noc_block_tb, noc_block_duc, SC16, SPP);
    `RFNOC_CONNECT(noc_block_duc, noc_block_tb, SC16, SPP);
    send_ones(1);    // HBs enabled: 0, CIC rate: 1
    send_ones(2);    // HBs enabled: 1, CIC rate: 1
    send_ones(3);    // HBs enabled: 0, CIC rate: 3
    send_ones(4);    // HBs enabled: 2, CIC rate: 1
    send_ones(6);    // HBs enabled: 1, CIC rate: 3
    send_ones(8);    // HBs enabled: 2, CIC rate: 2
    send_ones(12);   // HBs enabled: 2, CIC rate: 3
    send_ones(13);   // HBs enabled: 0, CIC rate: 13
    send_ones(16);   // HBs enabled: 2, CIC rate: 3
    send_ones(40);   // HBs enabled: 2, CIC rate: 20
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end
endmodule
