//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_to_axis_ctrl
// Description:
//  Converts from CHDR to AXIS-Control and vice versa
//
// Parameters:
//   - CHDR_W: Width of the CHDR bus in bits
//
// Signals:
//   - s_rfnoc_chdr_* : Input CHDR stream (AXI-Stream)
//   - m_rfnoc_chdr_* : Output CHDR stream (AXI-Stream)
//   - s_ctrl_chdr_* : Input control stream (AXI-Stream)
//   - m_ctrl_chdr_* : Output control stream (AXI-Stream)

module chdr_to_axis_ctrl #(
  parameter CHDR_W = 256
)(
  // CHDR Bus (master and slave)
  input  wire              rfnoc_chdr_clk,
  input  wire              rfnoc_chdr_rst,
  input  wire [CHDR_W-1:0] s_rfnoc_chdr_tdata,
  input  wire              s_rfnoc_chdr_tlast,
  input  wire              s_rfnoc_chdr_tvalid,
  output wire              s_rfnoc_chdr_tready,
  output wire [CHDR_W-1:0] m_rfnoc_chdr_tdata,
  output wire              m_rfnoc_chdr_tlast,
  output wire              m_rfnoc_chdr_tvalid,
  input  wire              m_rfnoc_chdr_tready,
  // AXIS-Control Bus (master and slave)
  input  wire              rfnoc_ctrl_clk,
  input  wire              rfnoc_ctrl_rst,
  input  wire [31:0]       s_rfnoc_ctrl_tdata,
  input  wire              s_rfnoc_ctrl_tlast,
  input  wire              s_rfnoc_ctrl_tvalid,
  output wire              s_rfnoc_ctrl_tready,
  output wire [31:0]       m_rfnoc_ctrl_tdata,
  output wire              m_rfnoc_ctrl_tlast,
  output wire              m_rfnoc_ctrl_tvalid,
  input  wire              m_rfnoc_ctrl_tready
);

  // ---------------------------------------------------
  //  RFNoC Includes
  // ---------------------------------------------------
  `include "rfnoc_chdr_utils.vh"
  `include "rfnoc_axis_ctrl_utils.vh"

  localparam [1:0] ST_HEADER   = 2'd0;
  localparam [1:0] ST_METADATA = 2'd1;
  localparam [1:0] ST_BODY     = 2'd2;

  // ---------------------------------------------------
  //  Input/output register slices
  // ---------------------------------------------------
  wire [CHDR_W-1:0] chdr_i_tdata,  chdr_o_tdata;
  wire              chdr_i_tlast,  chdr_o_tlast;
  wire              chdr_i_tvalid, chdr_o_tvalid;
  wire              chdr_i_tready, chdr_o_tready;

  axi_fifo #(.WIDTH(CHDR_W+1), .SIZE(1)) in_reg_i (
    .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst), .clear(1'b0),
    .i_tdata({s_rfnoc_chdr_tlast, s_rfnoc_chdr_tdata}),
    .i_tvalid(s_rfnoc_chdr_tvalid), .i_tready(s_rfnoc_chdr_tready),
    .o_tdata({chdr_i_tlast, chdr_i_tdata}),
    .o_tvalid(chdr_i_tvalid), .o_tready(chdr_i_tready),
    .space(), .occupied()
  );

  axi_fifo #(.WIDTH(CHDR_W+1), .SIZE(1)) out_reg_i (
    .clk(rfnoc_chdr_clk), .reset(rfnoc_chdr_rst), .clear(1'b0),
    .i_tdata({chdr_o_tlast, chdr_o_tdata}),
    .i_tvalid(chdr_o_tvalid), .i_tready(chdr_o_tready),
    .o_tdata({m_rfnoc_chdr_tlast, m_rfnoc_chdr_tdata}),
    .o_tvalid(m_rfnoc_chdr_tvalid), .o_tready(m_rfnoc_chdr_tready),
    .space(), .occupied()
  );

  // ---------------------------------------------------
  //  CHDR => Ctrl path
  // ---------------------------------------------------
  reg [1:0] chdr_i_state = ST_HEADER;
  reg [6:0] num_mdata = 7'd0;

  always @(posedge rfnoc_chdr_clk) begin
    if (rfnoc_chdr_rst) begin
      chdr_i_state <= ST_HEADER;
    end else if (chdr_i_tvalid && chdr_i_tready) begin
      case (chdr_i_state)
        ST_HEADER: begin
          num_mdata <= chdr_get_num_mdata(chdr_i_tdata) - 7'd1;
          if (!chdr_i_tlast)
            chdr_i_state <= (chdr_get_num_mdata(chdr_i_tdata) == 7'd0) ? 
              ST_BODY : ST_METADATA;
          else
            chdr_i_state <= ST_HEADER;  // Premature termination
        end
        ST_METADATA: begin
          num_mdata <= num_mdata - 7'd1;
          if (!chdr_i_tlast)
            chdr_i_state <= (num_mdata == 7'd0) ? ST_BODY : ST_METADATA;
          else
            chdr_i_state <= ST_HEADER;  // Premature termination
        end
        ST_BODY: begin
          if (chdr_i_tlast)
            chdr_i_state <= ST_HEADER;
        end
        default: begin
          // We should never get here
          chdr_i_state <= ST_HEADER;
        end
      endcase
    end
  end

  wire [(CHDR_W/8)-1:0] chdr_i_tkeep;
  chdr_compute_tkeep #( .CHDR_W(CHDR_W)) chdr_tkeep_gen_i (
    .clk(rfnoc_chdr_clk), .rst(rfnoc_chdr_rst),
    .axis_tdata(chdr_i_tdata), .axis_tlast(chdr_i_tlast),
    .axis_tvalid(chdr_i_tvalid), .axis_tready(chdr_i_tready),
    .axis_tkeep(chdr_i_tkeep)
  );

  axis_width_conv #(
    .WORD_W(32), .IN_WORDS(CHDR_W/32), .OUT_WORDS(1),
    .SYNC_CLKS(0), .PIPELINE("OUT")
  ) ctrl_downsizer_i (
    .s_axis_aclk(rfnoc_chdr_clk), .s_axis_rst(rfnoc_chdr_rst),
    .s_axis_tdata(chdr_i_tdata),
    .s_axis_tkeep(chdr_i_tkeep[(CHDR_W/8)-1:2]),
    .s_axis_tlast(chdr_i_tlast),
    .s_axis_tvalid(chdr_i_tvalid && (chdr_i_state == ST_BODY)),
    .s_axis_tready(chdr_i_tready),
    .m_axis_aclk(rfnoc_ctrl_clk), .m_axis_rst(rfnoc_ctrl_rst),
    .m_axis_tdata(m_rfnoc_ctrl_tdata),
    .m_axis_tkeep(/* Unused: OUT_WORDS=1 */),
    .m_axis_tlast(m_rfnoc_ctrl_tlast),
    .m_axis_tvalid(m_rfnoc_ctrl_tvalid),
    .m_axis_tready(m_rfnoc_ctrl_tready)
  );

  // ---------------------------------------------------
  //  Ctrl => CHDR path
  // ---------------------------------------------------

  wire [CHDR_W-1:0] wide_ctrl_tdata;
  wire              wide_ctrl_tlast, wide_ctrl_tvalid, wide_ctrl_tready;

  axis_width_conv #(
    .WORD_W(32), .IN_WORDS(1), .OUT_WORDS(CHDR_W/32),
    .SYNC_CLKS(0), .PIPELINE("IN")
  ) ctrl_upsizer_i (
    .s_axis_aclk(rfnoc_ctrl_clk), .s_axis_rst(rfnoc_ctrl_rst),
    .s_axis_tdata(s_rfnoc_ctrl_tdata),
    .s_axis_tkeep(/* Unused: IN_WORDS=1 */),
    .s_axis_tlast(s_rfnoc_ctrl_tlast),
    .s_axis_tvalid(s_rfnoc_ctrl_tvalid),
    .s_axis_tready(s_rfnoc_ctrl_tready),
    .m_axis_aclk(rfnoc_chdr_clk), .m_axis_rst(rfnoc_chdr_rst),
    .m_axis_tdata(wide_ctrl_tdata),
    .m_axis_tkeep(/* Unused: We are updating the CHDR length */),
    .m_axis_tlast(wide_ctrl_tlast),
    .m_axis_tvalid(wide_ctrl_tvalid),
    .m_axis_tready(wide_ctrl_tready)
  );

  // Information to generate CHDR header
  wire [7:0] num_ctrl_lines = 8'd3 +                                // Header + OpWord
    (axis_ctrl_get_has_time(wide_ctrl_tdata[31:0]) ? 8'd2 : 8'd0) + // Timestamp
    ({5'h0, axis_ctrl_get_num_data(wide_ctrl_tdata[31:0])});        // Data words

  wire [15:0] chdr_len = ({8'h0, num_ctrl_lines} << 2) + 16'd8;     // CHDR header + Payload
  wire [15:0] dst_epid = axis_ctrl_get_epid(wide_ctrl_tdata[31:0]);

  reg [1:0] chdr_o_state = ST_HEADER;
  reg [15:0] seq_num = 16'd0;

  always @(posedge rfnoc_chdr_clk) begin
    if (rfnoc_chdr_rst) begin
      chdr_o_state <= ST_HEADER;
      seq_num <= 16'd0;
    end else if (chdr_o_tvalid && chdr_o_tready) begin
      case (chdr_o_state)
        ST_HEADER: begin
          if (!chdr_o_tlast)
            chdr_o_state <= ST_BODY;
        end
        ST_BODY: begin
          if (chdr_o_tlast)
            chdr_o_state <= ST_HEADER;
        end
        default: begin
          // We should never get here
          chdr_o_state <= ST_HEADER;
        end
      endcase
      if (chdr_o_tlast)
        seq_num <= seq_num + 16'd1;
    end
  end

  // Hold the first line to generate info
  // for the outgoing CHDR header
  assign wide_ctrl_tready = (chdr_o_state == ST_BODY) ? chdr_o_tready : 1'b0;

  // Build a header for the outgoing CHDR packet
  wire [CHDR_W-1:0] chdr_header;
  assign chdr_header[63:0] = chdr_build_header(
    /*flags*/ 6'h0, CHDR_PKT_TYPE_CTRL, /*nmdata*/ 7'd0, seq_num, chdr_len, dst_epid);
  generate 
    if (CHDR_W > 64)
      assign chdr_header[CHDR_W-1:64] = 'h0;
  endgenerate

  // Output signals
  assign chdr_o_tdata   = (chdr_o_state == ST_HEADER) ? chdr_header : wide_ctrl_tdata;
  assign chdr_o_tlast   = wide_ctrl_tlast;
  assign chdr_o_tvalid  = wide_ctrl_tvalid;

endmodule // chdr_to_axis_ctrl
