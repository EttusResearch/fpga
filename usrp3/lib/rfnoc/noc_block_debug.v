//
// Copyright 2017 Ettus Research
//
// Experimental debugging block for collecting packet statistics
// such as throughput, packet size, and flow control congestion.
//

module noc_block_debug #(
  parameter NOC_ID = 64'hDEB1_2000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data[0:1];
  wire [7:0]  set_addr[0:1];
  wire [1:0]  set_stb;
  reg  [63:0] rb_data[0:1];
  wire [7:0]  rb_addr[0:1];

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready;
  wire [63:0] str_src_tdata[0:1];
  wire [1:0]  str_src_tlast, str_src_tvalid, str_src_tready;

  wire [15:0] src_sid[0:1];
  wire [15:0] next_dst_sid[0:1];

  wire [1:0]  clear_tx_seqnum;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(1),
    .OUTPUT_PORTS(2),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data({set_data[1],set_data[0]}), .set_addr({set_addr[1],set_addr[0]}), .set_stb(set_stb),
    .rb_stb(16'hFFFF), .rb_data({rb_data[1],rb_data[0]}), .rb_addr({rb_addr[1],rb_addr[0]}),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata({str_src_tdata[1],str_src_tdata[0]}), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Stream IDs set by host 
    .src_sid({src_sid[1],src_sid[0]}),                   // SID of this block
    .next_dst_sid({next_dst_sid[1],next_dst_sid[0]}),    // Next destination SID
    .resp_in_dst_sid(),
    .resp_out_dst_sid(),
    // Misc
    .vita_time('d0), .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper for loopback
  //
  ////////////////////////////////////////////////////////////
  wire [31:0]  m_axis_data_tdata;
  wire         m_axis_data_tlast;
  wire         m_axis_data_tvalid;
  wire         m_axis_data_tready;
  wire [127:0] m_axis_data_tuser;

  wire [31:0]  s_axis_data_tdata[0:1];
  wire         s_axis_data_tlast[0:1];
  wire         s_axis_data_tvalid[0:1];
  wire         s_axis_data_tready[0:1];
  wire [127:0] s_axis_data_tuser[0:1];
  wire [127:0] s_axis_data_tuser_mod;

  axi_wrapper #(
    .SIMPLE_MODE(0))
  axi_wrapper_0 (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum[0]),
    .next_dst(next_dst_sid[0]),
    .set_stb(set_stb[0]), .set_addr(set_addr[0]), .set_data(set_data[0]),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata[0]), .o_tlast(str_src_tlast[0]), .o_tvalid(str_src_tvalid[0]), .o_tready(str_src_tready[0]),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tuser(m_axis_data_tuser),
    .s_axis_data_tdata(s_axis_data_tdata[0]),
    .s_axis_data_tlast(s_axis_data_tlast[0]),
    .s_axis_data_tvalid(s_axis_data_tvalid[0]),
    .s_axis_data_tready(s_axis_data_tready[0]),
    .s_axis_data_tuser(s_axis_data_tuser_mod),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  reg set_eob;

  cvita_hdr_modify cvita_hdr_modify (
    .header_in(s_axis_data_tuser[0]),
    .header_out(s_axis_data_tuser_mod),
    .use_pkt_type(1'b0),       .pkt_type(),
    .use_has_time(1'b0),       .has_time(),
    .use_eob(1'b1),            .eob(s_axis_data_tuser[0][124] | set_eob),
    .use_seqnum(1'b0),         .seqnum(),
    .use_length(1'b0),         .length(),
    .use_payload_length(1'b0), .payload_length(),
    .use_src_sid(1'b1),        .src_sid(src_sid[0]),
    .use_dst_sid(1'b1),        .dst_sid(next_dst_sid[0]),
    .use_vita_time(1'b0),      .vita_time());

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper for output packet statistics
  //
  ////////////////////////////////////////////////////////////
  axi_wrapper #(
    .SIMPLE_MODE(0))
  axi_wrapper_1 (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum[1]),
    .next_dst(next_dst_sid[1]),
    .set_stb(set_stb[1]), .set_addr(set_addr[1]), .set_data(set_data[1]),
    .i_tdata(), .i_tlast(), .i_tvalid(), .i_tready(),
    .o_tdata(str_src_tdata[1]), .o_tlast(str_src_tlast[1]), .o_tvalid(str_src_tvalid[1]), .o_tready(str_src_tready[1]),
    .m_axis_data_tdata(),
    .m_axis_data_tlast(),
    .m_axis_data_tvalid(),
    .m_axis_data_tready(),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata[1]),
    .s_axis_data_tlast(s_axis_data_tlast[1]),
    .s_axis_data_tvalid(s_axis_data_tvalid[1]),
    .s_axis_data_tready(s_axis_data_tready[1]),
    .s_axis_data_tuser(s_axis_data_tuser[1]),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  assign s_axis_data_tuser[1] = {4'd0,12'd0,16'd0,src_sid[1],next_dst_sid[1],64'd0};

  ////////////////////////////////////////////////////////////
  //
  // Settings Regs
  //
  ////////////////////////////////////////////////////////////
  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_USER_REG_BASE = 128;

  localparam [7:0] SR_CONFIG       = SR_USER_REG_BASE;
  localparam [7:0] SR_PAYLOAD_LEN  = SR_USER_REG_BASE + 1;
  localparam [7:0] RB_CONFIG       = 0;
  localparam [7:0] RB_PAYLOAD_LEN  = 1;

  wire [1:0] sr_config;
  wire sr_config_changed;
  wire en_null_sink = sr_config[0];
  wire en_null_src  = sr_config[1];
  setting_reg #(
    .my_addr(SR_CONFIG), .awidth(8), .width(2))
  setting_reg_config (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb[0]), .addr(set_addr[0]), .in(set_data[0]), .out(sr_config), .changed(sr_config_changed));

  wire [15:0] sr_payload_len;
  setting_reg #(
    .my_addr(SR_PAYLOAD_LEN), .awidth(8), .width(16),
    .at_reset(64)) // Fairly safe default value, but should generally not be relied on
  setting_reg_payload_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb[0]), .addr(set_addr[0]), .in(set_data[0]), .out(sr_payload_len), .changed());

  // Readback registers
  always @(posedge ce_clk) begin
    case(rb_addr[0])
      RB_CONFIG       : rb_data[0] <= {62'd0, sr_config};
      RB_PAYLOAD_LEN  : rb_data[0] <= {48'd0, sr_payload_len};
      default         : rb_data[0] <= 64'h0BADC0DE0BADC0DE;
    endcase
  end

  ////////////////////////////////////////////////////////////
  //
  // Loopback input -> output
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] fifo_out_tdata;
  wire [127:0] fifo_out_tuser;
  wire fifo_out_tlast, fifo_out_tvalid, fifo_out_tready;
  axi_fifo #(
    .WIDTH(33+128), .SIZE(1))
  inst_axi_fifo (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[0]),
    .i_tdata({m_axis_data_tlast,m_axis_data_tdata,m_axis_data_tuser}), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready),
    .o_tdata({fifo_out_tlast,fifo_out_tdata,fifo_out_tuser}), .o_tvalid(fifo_out_tvalid), .o_tready(fifo_out_tready),
    .space(), .occupied());

  reg [15:0] sample_cnt;
  always @(posedge ce_clk) begin
    if (ce_rst | clear_tx_seqnum[0]) begin
      sample_cnt <= 1;
    end else begin
      if (s_axis_data_tvalid[0] & s_axis_data_tready[0]) begin
        if (s_axis_data_tlast[0]) begin
          sample_cnt <= 1;
        end else begin
          sample_cnt <= sample_cnt + 1;
        end
      end
    end
  end

  reg en_null_sink_reg, en_null_src_reg;
  // Enable null source and/or null sink only at the end of a packet
  always @(posedge ce_clk) begin
    if (ce_rst | clear_tx_seqnum[0]) begin
      set_eob          <= 1'b0;
      en_null_sink_reg <= 1'b0;
      en_null_src_reg  <= 1'b0;
    end else begin
      if (s_axis_data_tvalid[0] & s_axis_data_tready[0] & s_axis_data_tlast[0]) begin
        set_eob          <= 1'b0;
        en_null_sink_reg <= en_null_sink;
        en_null_src_reg  <= en_null_src;
      end
      if (sr_config_changed) begin
        set_eob          <= (en_null_src | en_null_sink) & ~(en_null_src_reg | en_null_sink_reg);
      end
    end
  end

  assign s_axis_data_tdata[0]  = en_null_src_reg                      ? 32'd0                           : fifo_out_tdata;
  assign s_axis_data_tlast[0]  = (en_null_src_reg | en_null_sink_reg) ? (sample_cnt >= sr_payload_len)  : fifo_out_tlast;
  assign s_axis_data_tvalid[0] = en_null_src_reg                      ? 1'b1                            : fifo_out_tvalid;
  assign s_axis_data_tuser[0]  = (en_null_src_reg | en_null_sink_reg) ? 128'd0                          : fifo_out_tuser;
  assign fifo_out_tready       = en_null_sink_reg                     ? 1'b1                            : s_axis_data_tready[0];

  ////////////////////////////////////////////////////////////
  //
  // Gather received packet stats and output on block port 1
  //
  ////////////////////////////////////////////////////////////
  // Counter to track time
  reg [47:0] local_time;
  always @(posedge ce_clk) begin
    if (ce_rst) begin
      local_time <= 48'd0;
    end else begin
      local_time <= local_time + 1;
    end
  end

  wire [15:0] input_payload_len;
  cvita_hdr_decoder cvita_hdr_decoder (
    .header(m_axis_data_tuser),
    .pkt_type(), .eob(), .has_time(),
    .seqnum(), .length(), .payload_length(input_payload_len),
    .src_sid(), .dst_sid(),
    .vita_time());

  // State Machine to capture useful information about incoming packets
  // - Count of upsteam / downstream tvalid / tready status
  // - Received packet start / end time
  // - Payload size
  reg state;
  localparam S_FIRST_LINE = 0;
  localparam S_LAST_LINE  = 1;

  localparam NUM_DEBUG_ITEMS = 10;

  reg [31:0] idle_upstream_not_valid, idle_downstream_not_ready, idle;
  reg [31:0] midpkt_upstream_not_valid, midpkt_downstream_not_ready, throttled;
  reg [31:0] payload_len, pkt_time, idle_time;
  reg [47:0] start_time, prev_stop_time;

  wire [NUM_DEBUG_ITEMS*32-1:0] packet_stat_fifo_in_tdata, packet_stat_fifo_out_tdata;
  reg packet_stat_fifo_in_tvalid;
  wire packet_stat_fifo_out_tvalid, packet_stat_fifo_in_tready, packet_stat_fifo_out_tready;

  always @(posedge ce_clk) begin
    if (ce_rst | clear_tx_seqnum[0]) begin
      packet_stat_fifo_in_tvalid  <= 1'b0;
      prev_stop_time              <= 48'd0;
      start_time                  <= 48'd0;
      idle                        <= 32'd0;
      idle_upstream_not_valid     <= 32'd0;
      idle_downstream_not_ready   <= 32'd0;
      throttled                   <= 32'd0;
      midpkt_upstream_not_valid   <= 32'd0;
      midpkt_downstream_not_ready <= 32'd0;
      state                       <= S_FIRST_LINE;
    end else begin
      case (state)
        S_FIRST_LINE : begin
          packet_stat_fifo_in_tvalid  <= 1'b0;
          idle_time                   <= local_time - prev_stop_time;
          if (~m_axis_data_tvalid) begin
            idle_upstream_not_valid   <= idle_upstream_not_valid + 1;
          end
          if (~m_axis_data_tready) begin
            idle_downstream_not_ready <= idle_downstream_not_ready + 1;
          end
          if (~m_axis_data_tvalid | ~m_axis_data_tready) begin
            idle                      <= idle + 1;
          end
          if (m_axis_data_tvalid & m_axis_data_tready) begin
            payload_len               <= input_payload_len;
            start_time                <= local_time;
            state                     <= S_LAST_LINE;
          end
        end
        S_LAST_LINE : begin
          pkt_time                      <= local_time - start_time;
          if (~m_axis_data_tvalid) begin
            midpkt_upstream_not_valid   <= midpkt_upstream_not_valid + 1;
          end
          if (~m_axis_data_tready) begin
            midpkt_downstream_not_ready <= midpkt_downstream_not_ready + 1;
          end
          if (~m_axis_data_tvalid | ~m_axis_data_tready) begin
            throttled                   <= throttled + 1;
          end
          if (m_axis_data_tvalid & m_axis_data_tready & m_axis_data_tlast) begin
            packet_stat_fifo_in_tvalid  <= 1'b1;
            idle                        <= 32'd0;
            idle_upstream_not_valid     <= 32'd0;
            idle_downstream_not_ready   <= 32'd0;
            throttled                   <= 32'd0;
            midpkt_upstream_not_valid   <= 32'd0;
            midpkt_downstream_not_ready <= 32'd0;
            prev_stop_time              <= local_time;
            state                       <= S_FIRST_LINE;
          end
        end
      endcase
    end
  end

  assign packet_stat_fifo_in_tdata  = {payload_len, pkt_time, idle_time, local_time[31:0],
                                       idle_upstream_not_valid, idle_downstream_not_ready, idle,
                                       midpkt_upstream_not_valid, midpkt_downstream_not_ready, throttled};

  // FIFO to hold packet stats
  // Note: If FIFO is full, stats data will be dropped. This is safer than trying to throttle the input
  //       data. Generally this should never happen since the stat packet output rate is very low relative
  //       to the input data rate.
  axi_fifo #(
    .WIDTH(NUM_DEBUG_ITEMS*32), .SIZE(5))
  inst_axi_fifo_packet_stat (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[1]),
    .i_tdata(packet_stat_fifo_in_tdata), .i_tvalid(packet_stat_fifo_in_tvalid), .i_tready(packet_stat_fifo_in_tready),
    .o_tdata(packet_stat_fifo_out_tdata), .o_tvalid(packet_stat_fifo_out_tvalid), .o_tready(packet_stat_fifo_out_tready),
    .space(), .occupied());

  ////////////////////////////////////////////////////////////
  //
  // Output stats packets on block port 1
  //
  ////////////////////////////////////////////////////////////
  localparam OUTPUT_PKT_LEN = 32*NUM_DEBUG_ITEMS;

  reg output_state;
  localparam S_OUTPUT_IDLE = 1'd0;
  localparam S_OUTPUT_PKT  = 1'd1;

  wire [31:0] packet_stat_tdata;
  reg packet_stat_tvalid;
  wire packet_stat_tlast, packet_stat_tready;

  reg [$clog2(OUTPUT_PKT_LEN)-1:0] packet_out_cnt;
  reg [$clog2(NUM_DEBUG_ITEMS)-1:0] packet_out_mux;

  always @(posedge ce_clk) begin
    if (ce_rst | clear_tx_seqnum[1]) begin
      packet_out_cnt      <= 'd0;
      packet_out_mux      <= 'd0;
      packet_stat_tvalid  <= 1'b0;
      output_state        <= S_OUTPUT_IDLE;
    end else begin
      case (output_state)
        S_OUTPUT_IDLE : begin
          if (packet_stat_fifo_out_tvalid & packet_stat_tready) begin
            packet_stat_tvalid  <= 1'b1;
            output_state        <= S_OUTPUT_PKT;
          end
        end
        S_OUTPUT_PKT : begin
          if (packet_stat_tready) begin
            if (packet_out_cnt >= OUTPUT_PKT_LEN-1) begin
              packet_out_cnt      <= 'd0;
            end else begin
              packet_out_cnt      <= packet_out_cnt + 1;
            end
            if (packet_out_mux >= NUM_DEBUG_ITEMS-1) begin
              packet_stat_tvalid  <= 1'b0;
              packet_out_mux      <= 'd0;
              output_state        <= S_OUTPUT_IDLE;
            end else begin
              packet_out_mux      <= packet_out_mux + 1;
            end
          end
        end
      endcase
    end
  end

  assign packet_stat_fifo_out_tready = packet_stat_tvalid & packet_stat_tready & (packet_out_mux == NUM_DEBUG_ITEMS-1);

  assign packet_stat_tdata     = (packet_out_mux <= NUM_DEBUG_ITEMS-1) ? packet_stat_fifo_out_tdata[32*packet_out_mux +: 32] : 'd0;
  assign packet_stat_tlast     = (packet_out_cnt == OUTPUT_PKT_LEN-1);

  assign s_axis_data_tdata[1]  = packet_stat_tdata;
  assign s_axis_data_tlast[1]  = packet_stat_tlast;
  assign s_axis_data_tvalid[1] = packet_stat_tvalid;
  assign packet_stat_tready    = s_axis_data_tready[1];

endmodule