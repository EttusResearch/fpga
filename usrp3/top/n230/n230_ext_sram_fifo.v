//
// Copyright 2014-2016 Ettus Research LLC
//

module n230_ext_sram_fifo #(
   parameter BIST_ENABLED  = 0,
   parameter BIST_REG_BASE = 0,
   parameter INT_BUF_DEPTH = 0
) (
   //Clocks
   input          extram_clk,
   input          user_clk,
   input          user_rst,
   
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

   // AXI Stream Interface
   input [63:0]   i_tdata,
   input          i_tlast,
   input          i_tvalid,
   output         i_tready,

   output [63:0]  o_tdata,
   output         o_tlast,
   output         o_tvalid,
   input          o_tready,

   // BIST Control Status Interface
   input          set_stb,
   input [7:0]    set_addr,
   input [31:0]   set_data,

   output         bist_done,
   output [1:0]   bist_error
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

   OBUF pin_RAM_A18 (.I(1'b0), .O(RAM_A[18]));
   OBUF pin_RAM_A19 (.I(1'b0), .O(RAM_A[19]));
   OBUF pin_RAM_A20 (.I(1'b0), .O(RAM_A[20]));

   //------------------------------------------------------------------
   // RAM clock from bus clock
   //------------------------------------------------------------------
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) ram_clk_out_i
     (.Q(RAM_CLK), .C(extram_clk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0));

   // --------------------------------------------
   // Instantiate FIFO logic
   // --------------------------------------------

   wire [63:0] i_tdata_fifo;
   wire        i_tlast_fifo, i_tvalid_fifo, i_tready_fifo;

   wire [63:0] i_tdata_64;
   wire        i_tlast_64, i_tvalid_64, i_tready_64;

   wire [31:0] fifo_tdata_in; 
   wire        fifo_tlast_in, fifo_tvalid_in, fifo_tready_in;
   wire [31:0] fifo_tdata_out; 
   wire        fifo_tlast_out, fifo_tvalid_out, fifo_tready_out;
   wire [2:0]  fifo_unused_in, fifo_unused_out;

   wire [63:0] o_tdata_64;
   wire        o_tlast_64, o_tvalid_64, o_tready_64;

   wire [63:0] o_tdata_fifo;
   wire        o_tlast_fifo, o_tvalid_fifo, o_tready_fifo;

   // Convert 64bit to 32bit AXIS bus
   axi_fifo #(.WIDTH(65), .SIZE(INT_BUF_DEPTH)) pre_ext_fifo_i0 (
      .clk(user_clk), .reset(user_rst),  .clear(1'b0),
      .i_tdata({i_tlast_fifo, i_tdata_fifo}), .i_tvalid(i_tvalid_fifo), .i_tready(i_tready_fifo),
      .o_tdata({i_tlast_64, i_tdata_64}), .o_tvalid(i_tvalid_64), .o_tready(i_tready_64),
      .space(),.occupied()
   );

   axi_fifo64_to_fifo32 fifo64_to_fifo32_i0 (
      .clk(user_clk), .reset(user_rst),  .clear(1'b0),
      .i_tdata(i_tdata_64), .i_tuser(3'b0/*done care*/), .i_tlast(i_tlast_64),
      .i_tvalid(i_tvalid_64), .i_tready(i_tready_64),
      .o_tdata(fifo_tdata_in), .o_tuser(/*ignored cuz vita has len*/),
      .o_tlast(fifo_tlast_in), .o_tvalid(fifo_tvalid_in), .o_tready(fifo_tready_in)
   );

   assign fifo_unused_in = 3'd0;

   ext_fifo #(
      .EXT_WIDTH(36), .INT_WIDTH(36),
      .RAM_DEPTH(18), .FIFO_DEPTH(18)
   ) ext_fifo_i (
      .int_clk    (user_clk),
      .ext_clk    (user_clk),
      .rst        (user_rst),
      .RAM_D_pi   (RAM_D_pi),
      .RAM_D_po   (RAM_D_po),
      .RAM_D_poe  (RAM_D_poe),
      .RAM_A      (RAM_A[17:0]),
      .RAM_WEn    (RAM_WEn),
      .RAM_CENn   (RAM_CENn),
      .RAM_LDn    (RAM_LDn),
      .RAM_OEn    (RAM_OEn),
      .RAM_CE1n   (RAM_CE1n),
      .datain     ({fifo_unused_in, fifo_tlast_in, fifo_tdata_in}),
      .src_rdy_i  (fifo_tvalid_in),
      .dst_rdy_o  (fifo_tready_in),
      .dataout    ({fifo_unused_out, fifo_tlast_out, fifo_tdata_out}),
      .src_rdy_o  (fifo_tvalid_out),
      .dst_rdy_i  (fifo_tready_out)
   );

   // Convert 32bit AXIS bus to 64bit
   axi_fifo32_to_fifo64 fifo32_to_fifo64_i0 (
      .clk(user_clk), .reset(user_rst), .clear(1'b0),
      .i_tdata(fifo_tdata_out), .i_tuser(2'b0/*always 32 bits*/), .i_tlast(fifo_tlast_out),
      .i_tvalid(fifo_tvalid_out), .i_tready(fifo_tready_out),
      .o_tdata(o_tdata_64), .o_tuser(/*ignored cuz vita has len*/),
      .o_tlast(o_tlast_64), .o_tvalid(o_tvalid_64), .o_tready(o_tready_64)
   );

   axi_fifo #(.WIDTH(65), .SIZE(INT_BUF_DEPTH)) post_ext_fifo_i0 (
      .clk(user_clk), .reset(user_rst),  .clear(1'b0),
      .i_tdata({o_tlast_64, o_tdata_64}), .i_tvalid(o_tvalid_64), .i_tready(o_tready_64),
      .o_tdata({o_tlast_fifo, o_tdata_fifo}), .o_tvalid(o_tvalid_fifo), .o_tready(o_tready_fifo),
      .space(),.occupied()
   );

   // --------------------------------------------
   // Instantiate BIST logic
   // --------------------------------------------
generate if (BIST_ENABLED == 1) begin

   wire [63:0] i_tdata_bist;
   wire        i_tvalid_bist, i_tready_bist, i_tlast_bist;

   wire [63:0] o_tdata_bist;
   wire        o_tvalid_bist, o_tready_bist, o_tlast_bist;

   axi_mux4 #(.PRIO(1), .WIDTH(64), .BUFFER(1)) bist_mux_i (
      .clk(user_clk), .reset(user_rst),  .clear(1'b0),
      .i0_tdata(i_tdata), .i0_tlast(i_tlast), .i0_tvalid(i_tvalid), .i0_tready(i_tready),
      .i1_tdata(i_tdata_bist), .i1_tlast(i_tlast_bist), .i1_tvalid(i_tvalid_bist), .i1_tready(i_tready_bist),
      .i2_tdata(64'h0), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata(64'h0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata(i_tdata_fifo), .o_tlast(i_tlast_fifo), .o_tvalid(i_tvalid_fifo), .o_tready(i_tready_fifo)
   );

   wire bist_running;
   axi_chdr_test_pattern #(
     .DELAY_MODE("STATIC"), 
     .SID_MODE("STATIC"), 
     .BW_COUNTER(0),
     .SR_BASE(BIST_REG_BASE)
   ) axi_chdr_test_pattern_i (
      .clk(user_clk), .reset(user_rst),
      .i_tdata(i_tdata_bist), .i_tlast(i_tlast_bist), .i_tvalid(i_tvalid_bist), .i_tready(i_tready_bist),
      .o_tdata(o_tdata_bist), .o_tlast(o_tlast_bist), .o_tvalid(o_tvalid_bist), .o_tready(o_tready_bist),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .running(bist_running), .done(bist_done), .error(bist_error), .status_vtr(), .bw_ratio()
   );

   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(64)) bist_demux_i (
      .clk(user_clk), .reset(user_rst),  .clear(1'b0),
      .header(), .dest({1'b0, bist_running}),
      .i_tdata(o_tdata_fifo), .i_tlast(o_tlast_fifo), .i_tvalid(o_tvalid_fifo), .i_tready(o_tready_fifo),
      .o0_tdata(o_tdata), .o0_tlast(o_tlast), .o0_tvalid(o_tvalid), .o0_tready(o_tready),
      .o1_tdata(o_tdata_bist), .o1_tlast(o_tlast_bist), .o1_tvalid(o_tvalid_bist), .o1_tready(o_tready_bist),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b0),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b0)
   );

end else begin    //if (BIST_ENABLED == 1)

   assign {i_tdata_fifo, i_tlast_fifo, i_tvalid_fifo, o_tready_fifo} = {i_tdata, i_tlast, i_tvalid, o_tready};
   assign {o_tdata, o_tlast, o_tvalid, i_tready} = {o_tdata_fifo, o_tlast_fifo, o_tvalid_fifo, i_tready_fifo};
   
   assign bist_done = 1'b0;
   assign bist_error = 2'b00;

end endgenerate   //if (BIST_ENABLED == 1)

endmodule // n230_ext_sram_fifo
