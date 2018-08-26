//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module noc_block_sos_filter #(
  parameter NOC_ID            = 64'h505F_0000_0000_0002,
  parameter NUM_SOS           = 2,
  parameter STR_SINK_FIFOSIZE = 11
) (
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  localparam [7:0] SR_COEFF_BASE   = 136;
  localparam [7:0] SR_COEFF_REGS   = 8;

  localparam [7:0] COEFF_B0_OFFSET = 0;
  localparam [7:0] COEFF_B1_OFFSET = 1;
  localparam [7:0] COEFF_B2_OFFSET = 2;
  localparam [7:0] COEFF_A1_OFFSET = 3;
  localparam [7:0] COEFF_A2_OFFSET = 4;

  localparam [7:0] RB_FILTER_INFO  = 0;

  localparam COEFF_W = 16;
  localparam DATA_W  = 16;

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data;
  wire [7:0]  set_addr, rb_addr;
  wire        set_stb;
  reg  [63:0] rb_data;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;
  wire [15:0] next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)
  ) noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(), .set_has_time(),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug)
  );

  always @(*) begin
    case(rb_addr)
      RB_FILTER_INFO  : rb_data <= {32'h0, COEFF_W[7:0], DATA_W[7:0], NUM_SOS[7:0], 8'd0};
      default         : rb_data <= 64'h0;
    endcase
  end

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 1; // Not used

  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;

  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;

  wire [31:0] m_axis_config_tdata;
  wire        m_axis_config_tvalid;
  wire        m_axis_config_tready;

  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

  axi_wrapper #(
    .SIMPLE_MODE(1),
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
    .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS)
  ) inst_axi_wrapper (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .m_axis_config_tdata(m_axis_config_tdata),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(m_axis_config_tvalid), 
    .m_axis_config_tready(m_axis_config_tready)
  );

  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  wire [COEFF_W-1:0] set_b0[0:NUM_SOS-1];
  wire [COEFF_W-1:0] set_b1[0:NUM_SOS-1];
  wire [COEFF_W-1:0] set_b2[0:NUM_SOS-1];
  wire [COEFF_W-1:0] set_a1[0:NUM_SOS-1];
  wire [COEFF_W-1:0] set_a2[0:NUM_SOS-1];
  wire [4:0]         coeff_rst[0:NUM_SOS-1];

  wire [(DATA_W*2)-1:0] cascade_tdata [0:NUM_SOS];
  wire                  cascade_tlast [0:NUM_SOS];
  wire                  cascade_tvalid[0:NUM_SOS];
  wire                  cascade_tready[0:NUM_SOS];

  // Input to first stage
  assign cascade_tdata[0]   = m_axis_data_tdata;
  assign cascade_tlast[0]   = m_axis_data_tlast;
  assign cascade_tvalid[0]  = m_axis_data_tvalid;
  assign m_axis_data_tready = cascade_tready[0];
  // Output from last stage
  assign s_axis_data_tdata  = cascade_tdata[NUM_SOS];
  assign s_axis_data_tlast  = cascade_tlast[NUM_SOS];
  assign s_axis_data_tvalid = cascade_tvalid[NUM_SOS];
  assign cascade_tready[NUM_SOS]= s_axis_data_tready;

  genvar i;
  generate
    for (i = 0; i < NUM_SOS; i = i + 1) begin : sos
      setting_reg #( 
        .my_addr(SR_COEFF_BASE + (SR_COEFF_REGS*i) + COEFF_B0_OFFSET), .width(COEFF_W)
      ) sr_b0_i (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_b0[i]), .changed(coeff_rst[i][0])
      );
      setting_reg #( 
        .my_addr(SR_COEFF_BASE + (SR_COEFF_REGS*i) + COEFF_B1_OFFSET), .width(COEFF_W)
      ) sr_b1_i (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_b1[i]), .changed(coeff_rst[i][1])
      );
      setting_reg #( 
        .my_addr(SR_COEFF_BASE + (SR_COEFF_REGS*i) + COEFF_B2_OFFSET), .width(COEFF_W)
      ) sr_b2_i (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_b2[i]), .changed(coeff_rst[i][2])
      );
      setting_reg #( 
        .my_addr(SR_COEFF_BASE + (SR_COEFF_REGS*i) + COEFF_A1_OFFSET), .width(COEFF_W)
      ) sr_a1_i (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_a1[i]), .changed(coeff_rst[i][3])
      );
      setting_reg #( 
        .my_addr(SR_COEFF_BASE + (SR_COEFF_REGS*i) + COEFF_A2_OFFSET), .width(COEFF_W)
      ) sr_a2_i (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_a2[i]), .changed(coeff_rst[i][4])
      );

      biquad_filter #(
        .DATA_W(DATA_W), .COEFF_W(COEFF_W),
        .FEEDBACK_W(25), .ACCUM_HEADROOM(2)
      ) biquad_filt_i (
        .clk(ce_clk), .reset(ce_rst | (|coeff_rst[i])),
        .set_b0(set_b0[i]), .set_b1(set_b1[i]), .set_b2(set_b2[i]),
        .set_a1(set_a1[i]), .set_a2(set_a2[i]),
        .i_tdata(cascade_tdata[i]), .i_tlast(cascade_tlast[i]),
        .i_tvalid(cascade_tvalid[i]), .i_tready(cascade_tready[i]),
        .o_tdata(cascade_tdata[i+1]), .o_tlast(cascade_tlast[i+1]),
        .o_tvalid(cascade_tvalid[i+1]), .o_tready(cascade_tready[i+1])
      );
    end
  endgenerate

endmodule // noc_block_vector_iir