//
// Copyright 2014-2016 Ettus Research LLC
//

module n230_ext_sram_fifo #(
   parameter INGRESS_BUF_DEPTH = 8,
   parameter EGRESS_BUF_DEPTH  = 8,
   parameter BIST_ENABLED      = 0,
   parameter BIST_REG_BASE     = 0
) (
   //Clocks
   input          bus_clk,
   input          bus_rst,
   input          ram_ui_clk,
   input          ram_io_clk,
   
   // IO Interface
   inout  [35:0]  RAM_D,
   output [20:0]  RAM_A,
   output [3:0]   RAM_BWn,
   output         RAM_ZZ,
   output         RAM_LDn,
   output         RAM_OEn,
   output         RAM_WEn,
   output         RAM_CENn,
   output         RAM_CE1n,
   output         RAM_CLK,

   // Ch0: AXI Stream Interface
   input [63:0]   i0_tdata,
   input          i0_tlast,
   input          i0_tvalid,
   output         i0_tready,

   output [63:0]  o0_tdata,
   output         o0_tlast,
   output         o0_tvalid,
   input          o0_tready,

   // Ch1: AXI Stream Interface
   input [63:0]   i1_tdata,
   input          i1_tlast,
   input          i1_tvalid,
   output         i1_tready,

   output [63:0]  o1_tdata,
   output         o1_tlast,
   output         o1_tvalid,
   input          o1_tready,

   // BIST Control Status Interface
   input          set_stb,
   input [7:0]    set_addr,
   input [31:0]   set_data,

   output         bist_done,
   output [1:0]   bist_error
);

   wire ram_ui_rst;
   reset_sync radio_reset_sync (
      .clk(ram_ui_clk), .reset_in(bus_rst), .reset_out(ram_ui_rst)
   );

   // --------------------------------------------
   // Instantiate IO for Bidirectional bus to SRAM
   // --------------------------------------------
   wire [35:0] RAM_D_pi;
   wire [35:0] RAM_D_po;
   wire        RAM_D_poe;

   genvar i;
   generate for(i = 0; i < 36; i = i + 1) begin : gen_RAM_D_IO
      IOBUF ram_data_i (
         .IO(RAM_D[i]),
         .I(RAM_D_po[i]),.O(RAM_D_pi[i]), .T(RAM_D_poe)
      );
   end endgenerate

   // Drive low so that RAM does not sleep.
   OBUF pin_RAM_ZZ (.I(1'b0),.O(RAM_ZZ));

   // Byte Writes are qualified by the global write enable
   // Always do 36bit operations to extram.
   OBUF pin_RAM_BW0 (.I(1'b0), .O(RAM_BWn[0]));
   OBUF pin_RAM_BW1 (.I(1'b0), .O(RAM_BWn[1]));
   OBUF pin_RAM_BW2 (.I(1'b0), .O(RAM_BWn[2]));
   OBUF pin_RAM_BW3 (.I(1'b0), .O(RAM_BWn[3]));

   //Only 18 of the 21 address lines are used on the 9Mbit SRAM part    
   OBUF pin_RAMA_18 (.I(1'b0), .O(RAM_A[18]));
   OBUF pin_RAMA_19 (.I(1'b0), .O(RAM_A[19]));
   OBUF pin_RAMA_20 (.I(1'b0), .O(RAM_A[20]));

   //------------------------------------------------------------------
   // RAM clock from bus clock
   //------------------------------------------------------------------
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) ram_clk_out_i (
      .Q(RAM_CLK), .C(ram_io_clk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0)
   );

   // --------------------------------------------
   // Ingress buffer
   // --------------------------------------------
   wire [63:0] i0_tdata_buf, i1_tdata_buf;
   wire        i0_tlast_buf, i0_tvalid_buf, i0_tready_buf, i1_tlast_buf, i1_tvalid_buf, i1_tready_buf;

   axi_fifo_2clk #(.WIDTH(65), .SIZE(INGRESS_BUF_DEPTH)) ingress_fifo_i0 (
      .reset(bus_rst),
      .i_aclk(bus_clk), .i_tdata({i0_tlast, i0_tdata}), .i_tvalid(i0_tvalid), .i_tready(i0_tready),
      .o_aclk(ram_ui_clk), .o_tdata({i0_tlast_buf, i0_tdata_buf}), .o_tvalid(i0_tvalid_buf), .o_tready(i0_tready_buf)
   );

   axi_fifo_2clk #(.WIDTH(65), .SIZE(INGRESS_BUF_DEPTH)) ingress_fifo_i1 (
      .reset(bus_rst),
      .i_aclk(bus_clk), .i_tdata({i1_tlast, i1_tdata}), .i_tvalid(i1_tvalid), .i_tready(i1_tready),
      .o_aclk(ram_ui_clk), .o_tdata({i1_tlast_buf, i1_tdata_buf}), .o_tvalid(i1_tvalid_buf), .o_tready(i1_tready_buf)
   );

   // --------------------------------------------
   // FIFO Logic
   // --------------------------------------------
   wire [63:0] ib_tdata;
   wire        ib_tlast, ib_tvalid, ib_tready;

   wire [63:0] mux_tdata;
   wire        mux_tlast, mux_tvalid, mux_tready;
   wire [1:0]  mux_tdest;

   wire [31:0] fifo_tdata_in; 
   wire        fifo_tlast_in, fifo_tvalid_in, fifo_tready_in;
   wire [1:0]  fifo_tdest_in;
   wire [31:0] fifo_tdata_out; 
   wire        fifo_tlast_out, fifo_tvalid_out, fifo_tready_out;
   wire [1:0]  fifo_tdest_out;

   wire [31:0] upbuf_tdata;
   wire        upbuf_tlast, upbuf_tvalid, upbuf_tready;
   wire [1:0]  upbuf_tdest;

   wire [63:0] demux_tdata;
   wire        demux_tlast, demux_tvalid, demux_tready;
   wire [1:0]  demux_tdest;
   wire [7:0]  demux_tkeep;
   wire        demux_terr;

   wire [63:0] ob_tdata;
   wire        ob_tlast, ob_tvalid, ob_tready;

   wire [63:0] o0_tdata_buf;
   wire        o0_tlast_buf, o0_tvalid_buf, o0_tready_buf;
   wire        o0_terr_buf;

   wire [63:0] o1_tdata_buf;
   wire        o1_tlast_buf, o1_tvalid_buf, o1_tready_buf;
   wire        o1_terr_buf;

   // MUX and add source information
   axi_mux4 #(.PRIO(0), .WIDTH(66), .BUFFER(1)) src_mux_i (
      .clk(ram_ui_clk), .reset(ram_ui_rst),  .clear(1'b0),
      .i0_tdata({2'd0, i0_tdata_buf}), .i0_tlast(i0_tlast_buf), .i0_tvalid(i0_tvalid_buf), .i0_tready(i0_tready_buf),
      .i1_tdata({2'd1, i1_tdata_buf}), .i1_tlast(i1_tlast_buf), .i1_tvalid(i1_tvalid_buf), .i1_tready(i1_tready_buf),
      .i2_tdata({2'd2, 64'h0}), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata({2'd3, ib_tdata}), .i3_tlast(ib_tlast), .i3_tvalid(ib_tvalid), .i3_tready(ib_tready),
      .o_tdata({mux_tdest, mux_tdata}), .o_tlast(mux_tlast), .o_tvalid(mux_tvalid), .o_tready(mux_tready)
   );

   // 64 -> 32 conversion
   axi_downsizer_64to32 downsizer_i (
      .aclk(ram_ui_clk), .aresetn(~ram_ui_rst),
      .s_axis_tdata(mux_tdata), .s_axis_tdest(mux_tdest), .s_axis_tlast(mux_tlast),
      .s_axis_tvalid(mux_tvalid), .s_axis_tready(mux_tready),
      .m_axis_tdata(fifo_tdata_in), .m_axis_tdest(fifo_tdest_in), .m_axis_tlast(fifo_tlast_in),
      .m_axis_tvalid(fifo_tvalid_in), .m_axis_tready(fifo_tready_in)
   );

   // NoBL FIFO
   wire ext_fifo_discard0;
   ext_fifo #(
      .EXT_WIDTH(36), .INT_WIDTH(36),
      .RAM_DEPTH(18), .FIFO_DEPTH(18)
   ) ext_fifo_i (
      .int_clk    (ram_ui_clk),
      .ext_clk    (ram_ui_clk),
      .rst        (ram_ui_rst),
      .RAM_D_pi   (RAM_D_pi),
      .RAM_D_po   (RAM_D_po),
      .RAM_D_poe  (RAM_D_poe),
      .RAM_A      (RAM_A[17:0]),
      .RAM_WEn    (RAM_WEn),
      .RAM_CENn   (RAM_CENn),
      .RAM_LDn    (RAM_LDn),
      .RAM_OEn    (RAM_OEn),
      .RAM_CE1n   (RAM_CE1n),
      .datain     ({1'b0, fifo_tlast_in, fifo_tdest_in, fifo_tdata_in}),
      .src_rdy_i  (fifo_tvalid_in),
      .dst_rdy_o  (fifo_tready_in),
      .dataout    ({ext_fifo_discard0, fifo_tlast_out, fifo_tdest_out, fifo_tdata_out}),
      .src_rdy_o  (fifo_tvalid_out),
      .dst_rdy_i  (fifo_tready_out)
   );

   // Short buffer for AXI upsizer
   axi_fifo_short #(.WIDTH(35)) upsizer_buf_i (
      .clk(ram_ui_clk), .reset(ram_ui_rst), .clear(1'b0),
      .i_tdata({fifo_tlast_out, fifo_tdest_out, fifo_tdata_out}), .i_tvalid(fifo_tvalid_out), .i_tready(fifo_tready_out),
      .o_tdata({upbuf_tlast, upbuf_tdest, upbuf_tdata}), .o_tvalid(upbuf_tvalid), .o_tready(upbuf_tready),
      .space(), .occupied()
   );

   // 32 -> 64 conversion
   axi_upsizer_32to64 upsizer_i (
      .aclk(ram_ui_clk), .aresetn(~ram_ui_rst),
      .s_axis_tdata(upbuf_tdata), .s_axis_tdest(upbuf_tdest), .s_axis_tlast(upbuf_tlast),
      .s_axis_tvalid(upbuf_tvalid), .s_axis_tready(upbuf_tready),
      .m_axis_tdata(demux_tdata), .m_axis_tdest(demux_tdest), .m_axis_tlast(demux_tlast),
      .m_axis_tvalid(demux_tvalid), .m_axis_tready(demux_tready), .m_axis_tkeep(demux_tkeep)
   );
   assign demux_terr = ~(&demux_tkeep);

   // DEMUX and split streams based on destination
   wire [65:0] header;
   wire [1:0]  o0_tdest, o1_tdest, ob_tdest;
   wire        ob_terr;

   axi_demux4 #(.ACTIVE_CHAN(4'b1011), .WIDTH(67), .BUFFER(1)) dest_demux_i (
      .clk(ram_ui_clk), .reset(ram_ui_rst),  .clear(1'b0),
      .header(header), .dest(header[65:64]),
      .i_tdata({demux_terr, demux_tdest, demux_tdata}), .i_tlast(demux_tlast), .i_tvalid(demux_tvalid), .i_tready(demux_tready),
      .o0_tdata({o0_terr_buf, o0_tdest, o0_tdata_buf}), .o0_tlast(o0_tlast_buf), .o0_tvalid(o0_tvalid_buf), .o0_tready(o0_tready_buf),
      .o1_tdata({o1_terr_buf, o1_tdest, o1_tdata_buf}), .o1_tlast(o1_tlast_buf), .o1_tvalid(o1_tvalid_buf), .o1_tready(o1_tready_buf),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata({ob_terr, ob_tdest, ob_tdata}), .o3_tlast(ob_tlast), .o3_tvalid(ob_tvalid), .o3_tready(ob_tready)
   );

   // --------------------------------------------
   // Egress buffer and packet gate
   // --------------------------------------------
   wire [63:0] o0_tdata_gt;
   wire        o0_tlast_gt, o0_tvalid_gt, o0_tready_gt;
   wire        o0_terr_gt;

   wire [63:0] o1_tdata_gt;
   wire        o1_tlast_gt, o1_tvalid_gt, o1_tready_gt;
   wire        o1_terr_gt;

   axi_fifo_2clk #(.WIDTH(66), .SIZE(0)) egress_fifo_i0 (
      .reset(bus_rst),
      .i_aclk(ram_ui_clk), .i_tdata({o0_terr_buf, o0_tlast_buf, o0_tdata_buf}), .i_tvalid(o0_tvalid_buf), .i_tready(o0_tready_buf),
      .o_aclk(bus_clk), .o_tdata({o0_terr_gt, o0_tlast_gt, o0_tdata_gt}), .o_tvalid(o0_tvalid_gt), .o_tready(o0_tready_gt)
   );

   axi_packet_gate #(.WIDTH(64), .SIZE(EGRESS_BUF_DEPTH)) egress_pkt_gate_i0 (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata(o0_tdata_gt), .i_tlast(o0_tlast_gt), .i_terror(o0_terr_gt), .i_tvalid(o0_tvalid_gt), .i_tready(o0_tready_gt),
      .o_tdata(o0_tdata), .o_tlast(o0_tlast), .o_tvalid(o0_tvalid), .o_tready(o0_tready)
   );

   axi_fifo_2clk #(.WIDTH(66), .SIZE(0)) egress_fifo_i1 (
      .reset(bus_rst),
      .i_aclk(ram_ui_clk), .i_tdata({o1_terr_buf, o1_tlast_buf, o1_tdata_buf}), .i_tvalid(o1_tvalid_buf), .i_tready(o1_tready_buf),
      .o_aclk(bus_clk), .o_tdata({o1_terr_gt, o1_tlast_gt, o1_tdata_gt}), .o_tvalid(o1_tvalid_gt), .o_tready(o1_tready_gt)
   );

   axi_packet_gate #(.WIDTH(64), .SIZE(EGRESS_BUF_DEPTH)) egress_pkt_gate_i1 (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata(o1_tdata_gt), .i_tlast(o1_tlast_gt), .i_terror(o1_terr_gt), .i_tvalid(o1_tvalid_gt), .i_tready(o1_tready_gt),
      .o_tdata(o1_tdata), .o_tlast(o1_tlast), .o_tvalid(o1_tvalid), .o_tready(o1_tready)
   );

   // --------------------------------------------
   // Instantiate BIST logic
   // --------------------------------------------
generate if (BIST_ENABLED == 1) begin

   axi_chdr_test_pattern #(
     .DELAY_MODE("STATIC"), 
     .SID_MODE("STATIC"), 
     .BW_COUNTER(0),
     .SR_BASE(BIST_REG_BASE)
   ) axi_chdr_test_pattern_i (
      .clk(ram_ui_clk), .reset(ram_ui_rst),
      .i_tdata(ib_tdata), .i_tlast(ib_tlast), .i_tvalid(ib_tvalid), .i_tready(ib_tready),
      .o_tdata(ob_tdata), .o_tlast(ob_tlast), .o_tvalid(ob_tvalid), .o_tready(ob_tready),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .running(), .done(bist_done), .error(bist_error), .status_vtr(), .bw_ratio()
   );

end else begin    //if (BIST_ENABLED == 1)

   assign {ib_tdata, ib_tlast, ib_tvalid} = {64'h0, 1'b0, 1'b0};
   assign ob_tready = 1'b1;
   
   assign bist_done = 1'b0;
   assign bist_error = 2'b00;

end endgenerate   //if (BIST_ENABLED == 1)

endmodule // n230_ext_sram_fifo
