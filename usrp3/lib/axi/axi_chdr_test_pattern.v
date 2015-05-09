//
// Synthesizable test pattern generator and checker
// for AXI-Stream that can be used to test transparent blocks
// (FIFOs, switches, etc)
//

module axi_chdr_test_pattern #(
  parameter SR_BASE     = 8'h0,
  parameter DELAY_MODE  = "DYNAMIC",
  parameter SID_MODE    = "DYNAMIC",
  parameter STATIC_SID  = 32'h0
) (
  input             clk,
  input             reset,

  // AXI stream to hook up to input of DUT
  output reg [63:0] i_tdata,
  output reg        i_tlast,
  output reg        i_tvalid,
  input             i_tready,

  // AXI stream to hook up to output of DUT
  input      [63:0] o_tdata,
  input             o_tlast,
  input             o_tvalid,
  output reg        o_tready,

  //Settings bus interface
  input             set_stb,
  input       [7:0] set_addr,
  input      [31:0] set_data,

  // Test flags
  output reg        running,    //Test is currently in progress
  output reg        done,       //(Sticky) Test has finished executing
  output reg  [1:0] error,      //Error code from last test execution
  output    [127:0] status_vtr  //More information about test failure.
);

  //
  // Error Codes
  //
  localparam ERR_SUCCESS                  = 0;
  localparam ERR_DATA_MISMATCH            = 1;
  localparam ERR_SIZE_MISMATCH_TOO_LONG   = 2;
  localparam ERR_SIZE_MISMATCH_TOO_SHORT  = 3;

  //
  // Settings
  //
  wire        bist_size_ramp;
  wire [1:0]  bist_test_patt;
  wire [13:0] bist_max_pkt_size;
  wire        bist_go, bist_ctrl_wr;
  wire [15:0] bist_max_pkts;
  wire [7:0]  bist_rx_delay, bist_tx_delay;
  wire [31:0] bist_cvita_sid;

  localparam TEST_PATT_ZERO_ONE     = 2'd0;
  localparam TEST_PATT_CHECKERBOARD = 2'd1;
  localparam TEST_PATT_COUNT        = 2'd2;
  localparam TEST_PATT_COUNT_INV    = 2'd3;

  // SETTING: Test Control Register
  // Fields:
  // - [0]    : (Strobe) Start the test if 1, otherwise reset the test
  // - [2:1]  : Test pattern:
  //            * 00 = Zeros and Ones (0x0000000000000000 <-> 0xFFFFFFFFFFFFFFFF)
  //            * 01 = Checkerboard   (0x0101010101010101 <-> 0x1010101010101010)
  //            * 10 = Counter        (Each byte will count up)
  //            * 11 = Invert Counter (Each byte will count up and invert)
  setting_reg #(
    .my_addr(SR_BASE + 0), .width(3), .at_reset(3'b0)
  ) reg_ctrl (
    .clk(clk), .rst(reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out({bist_test_patt, bist_go}),.changed(bist_ctrl_wr)
  );
  
  wire bist_start = bist_ctrl_wr & bist_go;
  wire bist_clear = bist_ctrl_wr & ~bist_go;

  // SETTING: Test Packet Configuration Register
  // Fields:
  // - [15:0]  : Number of packets to transfer for each BIST execution
  // - [29:16] : Max number of bytes per packet
  // - [30]    : Send variable (ramping) sized packets
  setting_reg #(
    .my_addr(SR_BASE + 1), .width(31), .at_reset(31'b0)
  ) reg_pkt_config (
    .clk(clk), .rst(reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out({bist_size_ramp, bist_max_pkt_size, bist_max_pkts}),.changed()
  );

  generate
    if (DELAY_MODE == "DYNAMIC") begin
      // SETTING: Delay Register
      // Fields:
      // - [7:0]   : Number of cycles to wait between generating consecutive packets
      // - [15:8]  : Number of cycles to wait between consuming consecutive packets
      setting_reg #(
        .my_addr(SR_BASE + 2), .width(16), .at_reset(16'b0)
      ) reg_delay (
        .clk(clk), .rst(reset),
        .strobe(set_stb), .addr(set_addr), .in(set_data),
        .out({bist_rx_delay, bist_tx_delay}),.changed()
      );
    end else begin
      assign {bist_rx_delay, bist_tx_delay} = 16'h0;
    end
  endgenerate

  generate
    if (SID_MODE == "DYNAMIC") begin
      // SETTING: CHDR Stream ID Register
      // Fields:
      // - [31:0]   : Stream ID to attach to CHDR packets
      setting_reg #(
        .my_addr(SR_BASE + 3), .width(32), .at_reset(32'b0)
      ) reg_sid (
        .clk(clk), .rst(reset),
        .strobe(set_stb), .addr(set_addr), .in(set_data),
        .out(bist_cvita_sid),.changed()
      );
    end else begin
      assign bist_cvita_sid = STATIC_SID;
    end
  endgenerate

  //
  // State
  //
  reg [2:0]  tx_state, rx_state;

  localparam TX_IDLE    = 0;
  localparam TX_START   = 1;
  localparam TX_ACTIVE  = 2;
  localparam TX_GAP     = 3;
  localparam TX_DONE    = 4;
  localparam TX_WAIT    = 5;

  localparam RX_IDLE    = 0;
  localparam RX_ACTIVE  = 1;
  localparam RX_FAIL    = 2;
  localparam RX_DONE    = 3;
  localparam RX_WAIT    = 4;

  reg [15:0]  tx_pkt_cnt, rx_pkt_cnt;
  reg [13:0]  tx_byte_cnt, rx_byte_cnt;
  reg [7:0]   tx_delay, rx_delay;
  wire [63:0] tx_cvita_hdr, rx_cvita_hdr;

  wire tx_next_pkt_cond, rx_next_pkt_cond;
  assign tx_next_pkt_cond = (tx_byte_cnt[13:3] == (bist_size_ramp ? tx_pkt_cnt[10:0] : bist_max_pkt_size[13:3]));
  assign rx_next_pkt_cond = (rx_byte_cnt[13:3] == (bist_size_ramp ? rx_pkt_cnt[10:0] : bist_max_pkt_size[13:3]));

  wire tx_test_done_cond, rx_test_done_cond;
  assign tx_test_done_cond = (tx_pkt_cnt == bist_max_pkts);
  assign rx_test_done_cond = (rx_pkt_cnt == bist_max_pkts);
  
  reg [63:0] tx_data_next, rx_data_exp;
  always @(*) begin
    case (bist_test_patt)
      TEST_PATT_ZERO_ONE: begin
        tx_data_next  <= {64{tx_byte_cnt[3]}};
        rx_data_exp   <= {64{rx_byte_cnt[3]}};
      end
      TEST_PATT_CHECKERBOARD: begin
        tx_data_next  <= {32{tx_byte_cnt[3] ? 2'b01 : 2'b10}};
        rx_data_exp   <= {32{rx_byte_cnt[3] ? 2'b01 : 2'b10}};
      end
      TEST_PATT_COUNT: begin
        tx_data_next  <= {8{tx_byte_cnt[10:3]}};
        rx_data_exp   <= {8{rx_byte_cnt[10:3]}};
      end
      TEST_PATT_COUNT_INV: begin
        tx_data_next  <= {8{(tx_byte_cnt[3] ? 8'hFF : 8'h00) ^ tx_byte_cnt[10:3]}};
        rx_data_exp   <= {8{(rx_byte_cnt[3] ? 8'hFF : 8'h00) ^ rx_byte_cnt[10:3]}};
      end
      default: begin
        tx_data_next  <= 64'd0;
        rx_data_exp   <= 64'd0;
      end
    endcase
  end

  //NOTE: We always attach the max size in the packet header for simplicity.
  //      This will not work with state machines that validate the packet length in the
  //      header with the tlast position.
  assign tx_cvita_hdr = {4'h0, tx_pkt_cnt[11:0], 2'b00, bist_max_pkt_size, bist_cvita_sid};
  assign rx_cvita_hdr = {4'h0, rx_pkt_cnt[11:0], 2'b00, bist_max_pkt_size, bist_cvita_sid};

  assign status_vtr = {
    o_tdata,              //[127:64]
    rx_data_exp[31:0],    //[63:32]
    {2'b0, rx_byte_cnt},  //[31:16]
    rx_pkt_cnt            //[15:0]
  };

  //
  // Transmitter
  //
  always @(posedge clk) begin
    if (reset | bist_clear) begin
      tx_delay      <= 0;
      tx_pkt_cnt    <= 0;
      tx_byte_cnt   <= 0;
      i_tdata       <= 64'h0;
      i_tlast       <= 1'b0;
      i_tvalid      <= 1'b0;
      tx_state      <= TX_IDLE;
    end else begin
      case(tx_state)
        TX_IDLE: begin
          tx_delay    <= 0;
          i_tdata     <= 64'h0;
          i_tlast     <= 1'b0;
          i_tvalid    <= 1'b0;
          tx_byte_cnt <= 0;
          tx_pkt_cnt  <= 1;
          // Run whilst bist_start asserted.
          if (bist_start) begin
            tx_state  <= TX_START;
            // ....Go back to initialized state if bist_start deasserted.
          end else begin
            tx_state  <= TX_IDLE;
          end
        end // case: TX_IDLE

        //
        // START signal is asserted.
        // Now need to start transmiting a packet.
        //
        TX_START: begin
          // At the next clock edge drive first beat of new packet onto HDR bus.
          i_tlast     <= 1'b0;
          i_tvalid    <= 1'b1;
          tx_byte_cnt <= tx_byte_cnt + 8;
          i_tdata     <= tx_cvita_hdr;
          tx_state    <= TX_ACTIVE;
        end

        //
        // Valid data is (already) being driven onto the CHDR bus.
        // i_tlast may also be driven asserted if current data count has reached EOP.
        // Watch i_tready to see when it's consumed.
        // When packets are consumed increment data counter or transition state if
        // EOP has sucsesfully concluded.
        //
        TX_ACTIVE: begin
          i_tvalid <= 1'b1; // Always assert tvalid
          if (i_tready) begin
            i_tdata <= tx_data_next;
            // Will this next beat be the last in a packet?
            if (tx_next_pkt_cond) begin
              tx_byte_cnt <= 0;
              i_tlast     <= 1'b1;
              tx_state    <= TX_GAP;
            end else begin
              tx_byte_cnt <= tx_byte_cnt + 8;
              i_tlast     <= 1'b0;
              tx_state    <= TX_ACTIVE;
            end
          end else begin
            //Keep driving all CHDR bus signals as-is until i_tready is asserted.
            tx_state <= TX_ACTIVE;
          end
        end // case: TX_ACTIVE

        //
        // Force an inter-packet gap between packets in a BIST sequence where tvalid is driven low.
        // As we leave this state check if all packets in BIST sequence have been generated yet,
        // and if so go to done state.
        //
        TX_GAP: begin
          if (i_tready) begin
            i_tvalid    <= 1'b0;
            i_tdata     <= 64'h0;
            i_tlast     <= 1'b0;
            tx_pkt_cnt  <= tx_pkt_cnt + 1;

            if (tx_test_done_cond) begin
              tx_state <= TX_DONE;
            end else begin
              tx_state <= TX_WAIT;
              tx_delay <= bist_tx_delay;
            end
          end else begin // if (i_tready)
            tx_state <= TX_GAP;
          end
        end // case: TX_GAP

        //
        // Simulate inter packet gap in real UHD system
        TX_WAIT: begin
          if (tx_delay == 0)
            tx_state <= TX_START;
          else begin
            tx_delay <= tx_delay - 1;
            tx_state <= TX_WAIT;
          end
        end

        //
        // Complete test pattern BIST sequence has been transmitted. Sit in this
        // state indefinately if START is taken low, which re-inits the whole BIST solution.
        //
        TX_DONE: begin
          if (~bist_start) begin
            tx_state <= TX_DONE;
          end else begin
            tx_state <= TX_IDLE;
          end
          i_tvalid <= 1'b0;
          i_tdata <= 64'd0;
          i_tlast <= 1'b0;
        end
      endcase // case (tx_state)
    end
  end

  //
  // Receiver
  //
  always @(posedge clk) begin
    if (reset | bist_clear) begin
      rx_delay    <= 0;
      rx_pkt_cnt  <= 0;
      rx_byte_cnt <= 0;
      o_tready    <= 1'b0;
      rx_state    <= RX_IDLE;
      error       <= ERR_SUCCESS;
      done        <= 1'b0;
    end else begin
      case(rx_state)
        RX_IDLE: begin
          rx_delay    <= 0;
          o_tready    <= 1'b0;
          rx_byte_cnt <= 0;
          rx_pkt_cnt  <= 1;
          error       <= ERR_SUCCESS;
          done        <= 1'b0;
          // Not accepting data whilst Idle,
          // switch to active when packet arrives
          if (o_tvalid) begin
            o_tready <= 1'b1;
            rx_state <= RX_ACTIVE;
          end else begin
            rx_state <= RX_IDLE;
          end
        end

        RX_ACTIVE: begin
          o_tready <= 1'b1;
          if (o_tvalid) begin
            if (o_tdata != (rx_byte_cnt == 0 ? rx_cvita_hdr : rx_data_exp)) begin
              $display("axis_test_pattern: o_tdata: %x  !=  expected:  %x @ time: %d", o_tdata, rx_data_exp, $time);
              error    <= ERR_DATA_MISMATCH;
              rx_state <= RX_FAIL;
            end else if (rx_next_pkt_cond) begin
              // Last not asserted when it should be!
              if (~(o_tlast === 1)) begin
                $display("axis_test_pattern: o_tlast not asserted when it should be @ time: %d", $time);
                error    <= ERR_SIZE_MISMATCH_TOO_LONG;
                rx_state <= RX_FAIL;
              end else begin
                // End of packet, set up to RX next
                rx_byte_cnt <= 0;
                rx_pkt_cnt  <= rx_pkt_cnt + 1;
                rx_delay    <= bist_rx_delay;
                if (rx_test_done_cond) begin
                  rx_state  <= RX_DONE;
                end else begin
                  rx_state  <= RX_WAIT;
                end
                o_tready    <= 1'b0;
              end
            end else begin
              // ...last asserted when it should not be!
              if (~(o_tlast === 0)) begin
                $display("axis_test_pattern: o_tlast asserted when it should not be @ time: %d", $time);
                error       <= ERR_SIZE_MISMATCH_TOO_SHORT;
                rx_state    <= RX_FAIL;
              end else begin
                // Still in packet body
                rx_byte_cnt <= rx_byte_cnt + 8;
                rx_delay    <= bist_rx_delay;
                rx_state    <= RX_WAIT;
                o_tready    <= 1'b0;
              end
            end
          end else begin
            // Nothing to do this cycle
            rx_state <= RX_ACTIVE;
          end
        end // case: RX_ACTIVE

        // To simulate the radio consuming samples at a steady rate set by the decimation
        // have a programable delay here
        RX_WAIT: begin
          if (rx_delay == 0) begin
            rx_state <= RX_ACTIVE;
            o_tready <= 1'b1;
          end else begin
            rx_delay <= rx_delay - 1;
            rx_state <= RX_WAIT;
          end
        end

        RX_FAIL: begin
          o_tready    <= 1'b0;
          done        <= 1'b1;
          // If bist_start is deasserted allow BIST logic to reset and rearm
          if (bist_start)
            rx_state  <= RX_FAIL;
          else
            rx_state  <= RX_IDLE;
        end

        RX_DONE: begin
          o_tready    <= 1'b0;
          done        <= 1'b1;
          error       <= ERR_SUCCESS;
          // If start is asserted allow BIST logic to reset, rearm & restart
          if (~bist_start)
            rx_state  <= RX_DONE;
          else
            rx_state  <= RX_IDLE;
        end
      endcase // case (rx_state)
    end
  end

  always @(posedge clk) begin
    if (reset | bist_clear)
      running <= 1'b0;
    else if (tx_state == TX_START)
      running <= 1'b1;
    else if (rx_state == RX_DONE || rx_state == RX_FAIL)
      running <= 1'b0;
  end

endmodule
