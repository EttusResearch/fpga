//
// Copyright 2015 National Instruments
//

module one_tap_equalizer (
  input clk_i,
  input rst_i,

  input sof_i,

  input [31:0] i_tdata,
  input i_tlast,
  input i_tvalid,
  output i_tready,

  output [31:0] o_tdata,
  output o_tlast,
  output o_tvalid,
  input  o_tready);

  //----------------------------------------------------------------------------
  // Constants
  //----------------------------------------------------------------------------

  localparam STATE_PREAMBLE = 2'd0;
  localparam STATE_ESTIMATE = 2'd1;
  localparam STATE_EQUALIZE = 2'd2;

  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------

  reg last_sof = 1'b0;
  reg [1:0] state = STATE_PREAMBLE;
  reg [5:0] prembl_count = 6'd0;

  reg signed [1:0] long_preamble[63:0];

  //----------------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------------

  // Determine start of frame
  wire sof;

  // Extract preamble
  wire [31:0] prembl_tdata;
  wire prembl_tlast, prembl_tvalid, prembl_tready;
  wire first_prembl_tvalid;

  // Apply stored preamble
  wire [31:0] neg_prembl_tdata;
  wire [31:0] applied_prembl_tdata;

  // Buffer preamble
  wire [31:0] prembl_flop_tdata;
  wire prembl_flop_tlast, prembl_flop_tvalid, prembl_flop_tready;

  // Invert preamble
  wire [31:0] inv_tdata;
  wire inv_tlast, inv_tvalid, inv_tready;

  // Buffer equalization factor
  wire [31:0] eq_tdata;
  wire eq_tlast, eq_tvalid, eq_tready;

  wire [31:0] eq_fifo_tdata;
  wire eq_fifo_tlast, eq_fifo_tvalid, eq_fifo_tready;

  wire eq_mul_tready, eq_mul_tvalid;

  // Extract data
  wire [31:0] data_tdata;
  wire data_tlast, data_tvalid, data_tready;
  wire skip_prembl_tvalid;

  // Buffer incoming data
  wire [31:0] data_fifo_tdata;
  wire data_fifo_tlast, data_fifo_tvalid, data_fifo_tready;

  // Multiplied result
  wire [63:0] mul_tdata;
  wire mul_tlast, mul_tvalid, mul_tready;

  //----------------------------------------------------------------------------
  // Instantiations
  //----------------------------------------------------------------------------

  // Split incoming stream in preamble and data
  split_stream #(
    .WIDTH(64),
    .ACTIVE_MASK(4'b0011))
  split_stream_inst (
    .clk(clk_i),
    .reset(rst_i | sof),
    .clear(sof),
    // Incoming data
    .i_tdata(i_tdata),
    .i_tlast(i_tlast),
    .i_tvalid(i_tvalid),
    .i_tready(i_tready),
    // Port 0
    .o0_tdata(prembl_tdata),
    .o0_tlast(prembl_tlast),
    .o0_tvalid(prembl_tvalid),
    .o0_tready(prembl_tready),
    // Port 1
    .o1_tdata(data_tdata),
    .o1_tlast(data_tlast),
    .o1_tvalid(data_tvalid),
    .o1_tready(data_tready),
    // Port 2
    .o2_tdata(),
    .o2_tlast(),
    .o2_tvalid(),
    .o2_tready(1'b1),
    // Port 3
    .o3_tdata(),
    .o3_tlast(),
    .o3_tvalid(),
    .o3_tready(1'b1));

  // Buffer incoming data
  axi_fifo #(
    .WIDTH(33),
    .SIZE(8))
  axi_data_fifo_inst (
    .clk(clk_i),
    .reset(rst_i | sof),
    .clear(sof),
    .i_tdata({data_tlast, data_tdata}),
    .i_tvalid(skip_prembl_tvalid),
    .i_tready(data_tready),
    .o_tdata({data_fifo_tlast, data_fifo_tdata}),
    .o_tvalid(data_fifo_tvalid),
    .o_tready(data_fifo_tready),
    .space(),
    .occupied());

  // Buffer applied preamble
  axi_fifo_flop #(
    .WIDTH(33))
  axi_prembl_flop (
    .clk(clk_i),
    .reset(rst_i | sof),
    .clear(sof),
    .i_tdata({prembl_tlast, applied_prembl_tdata}),
    .i_tvalid(first_prembl_tvalid),
    .i_tready(prembl_tready),
    .o_tdata({prembl_flop_tlast, prembl_flop_tdata}),
    .o_tvalid(prembl_flop_tvalid),
    .o_tready(prembl_flop_tready),
    .space(),
    .occupied());

  // Invert incoming preamble
  complex_invert complex_invert_inst (
    .clk(clk_i),
    .reset(rst_i | sof),
    .clear(sof),
    .i_tdata(prembl_flop_tdata),
    .i_tlast(prembl_flop_tlast),
    .i_tvalid(prembl_flop_tvalid),
    .i_tready(prembl_flop_tready),
    .o_tdata(inv_tdata),
    .o_tlast(inv_tlast),
    .o_tvalid(inv_tvalid),
    .o_tready(inv_tready));

  // Buffer equalization factor
  axi_fifo #(
    .WIDTH(33),
    .SIZE(6))
  axi_eq_fifo_inst (
    .clk(clk_i),
    .reset(rst_i | sof),
    .clear(sof),
    .i_tdata({eq_tlast, eq_tdata}),
    .i_tvalid(eq_tvalid),
    .i_tready(eq_tready),
    .o_tdata({eq_fifo_tlast, eq_fifo_tdata}),
    .o_tvalid(eq_fifo_tvalid),
    .o_tready(eq_fifo_tready),
    .space(),
    .occupied());

  // Multiply data with equalization factor
  cmul cmul_inst (
    .clk(clk_i),
    .reset(rst_i | sof_i), // Multiplier needs reset to be at least 2 cycles
    .a_tdata(eq_fifo_tdata),
    .a_tlast(eq_fifo_tlast),
    .a_tvalid(eq_mul_tvalid),
    .a_tready(eq_mul_tready),
    .b_tdata(data_fifo_tdata),
    .b_tlast(data_fifo_tlast),
    .b_tvalid(data_fifo_tvalid),
    .b_tready(data_fifo_tready),
    .o_tdata(mul_tdata),
    .o_tlast(mul_tlast),
    .o_tvalid(mul_tvalid),
    .o_tready(mul_tready));

  // Round an clip output
  axi_round_and_clip_complex #(
    .WIDTH_IN(32),
    .WIDTH_OUT(16),
    .CLIP_BITS(6), // Calibrated value
    .FIFOSIZE(0))
  axi_round_and_clip_complex_inst (
    .clk(clk_i),
    .reset(rst_i | sof),
    .i_tdata(mul_tdata),
    .i_tlast(mul_tlast),
    .i_tvalid(mul_tvalid),
    .i_tready(mul_tready),
    .o_tdata(o_tdata),
    .o_tlast(o_tlast),
    .o_tvalid(o_tvalid),
    .o_tready(o_tready));

  //----------------------------------------------------------------------------
  // Sequential Logic
  //----------------------------------------------------------------------------

  always @(posedge clk_i) begin
    if(rst_i) begin
      state <= STATE_PREAMBLE;
      last_sof <= 1'b0;
      prembl_count <= 6'd0;
    end
    else begin
      last_sof <= sof_i;

      if(sof)
        prembl_count <= 6'd0;
      else if(prembl_tvalid && prembl_tready)
        prembl_count <= prembl_count + 1;

      case(state)
        STATE_PREAMBLE:
          if(prembl_tlast)
            state <= STATE_ESTIMATE;
        STATE_ESTIMATE:
          if(inv_tlast)
            state <= STATE_EQUALIZE;
        STATE_EQUALIZE:
          if(sof)
            state <= STATE_PREAMBLE;
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // Combinational Logic
  //----------------------------------------------------------------------------

  // Start of frame edge detection
  assign sof = ~last_sof & sof_i;

  // Invert I part
  assign neg_prembl_tdata[31:16] = (prembl_tdata[31:16] == -16'sd32768) ?
    16'sd32767 : (~prembl_tdata[31:16] + 1'b1);
  // Invert Q part
  assign neg_prembl_tdata[15:0] = (prembl_tdata[15:0] == -16'sd32768) ?
    16'sd32767 : (~prembl_tdata[15:0] + 1'b1);

  // Apply stored preamble:
  //  0 ->  0 + 0j
  //  1 ->  a + bj
  // -1 -> -a - bj
  assign applied_prembl_tdata = (long_preamble[prembl_count] == 2'sd0) ?
    32'sd0 : ((long_preamble[prembl_count] == -2'sd1) ?
    neg_prembl_tdata : prembl_tdata);

  // Only process preamble once
  assign first_prembl_tvalid = (state == STATE_PREAMBLE) ? prembl_tvalid : 1'b0;

  // Skip preamble for data FIFO
  assign skip_prembl_tvalid = data_tvalid & (~first_prembl_tvalid);

  // Preamble FIFO feedback
  assign eq_tdata = (state == STATE_ESTIMATE) ? inv_tdata : eq_fifo_tdata;
  assign eq_tlast = (state == STATE_ESTIMATE) ? inv_tlast : eq_fifo_tlast;
  assign eq_tvalid = (state == STATE_ESTIMATE) ? inv_tvalid : (eq_fifo_tvalid & eq_fifo_tready);
  assign inv_tready = (state == STATE_ESTIMATE) ? eq_tready : 1'b0;

  assign eq_fifo_tready = (state == STATE_EQUALIZE) ?
    (eq_mul_tready & eq_tready) : 1'b0;

  assign eq_mul_tvalid = (state == STATE_EQUALIZE) ? eq_fifo_tvalid : 1'b0;

  // Long preamble from IEEE 802.11
  initial begin
    long_preamble[0]  =  2'sd0;
    long_preamble[1]  =  2'sd0;
    long_preamble[2]  =  2'sd0;
    long_preamble[3]  =  2'sd0;
    long_preamble[4]  =  2'sd0;
    long_preamble[5]  =  2'sd0;
    long_preamble[6]  =  2'sd1;
    long_preamble[7]  =  2'sd1;
    long_preamble[8]  = -2'sd1;
    long_preamble[9]  = -2'sd1;
    long_preamble[10] =  2'sd1;
    long_preamble[11] =  2'sd1;
    long_preamble[12] = -2'sd1;
    long_preamble[13] =  2'sd1;
    long_preamble[14] = -2'sd1;
    long_preamble[15] =  2'sd1;
    long_preamble[16] =  2'sd1;
    long_preamble[17] =  2'sd1;
    long_preamble[18] =  2'sd1;
    long_preamble[19] =  2'sd1;
    long_preamble[20] =  2'sd1;
    long_preamble[21] = -2'sd1;
    long_preamble[22] = -2'sd1;
    long_preamble[23] =  2'sd1;
    long_preamble[24] =  2'sd1;
    long_preamble[25] = -2'sd1;
    long_preamble[26] =  2'sd1;
    long_preamble[27] = -2'sd1;
    long_preamble[28] =  2'sd1;
    long_preamble[29] =  2'sd1;
    long_preamble[30] =  2'sd1;
    long_preamble[31] =  2'sd1;
    long_preamble[32] =  2'sd0;
    long_preamble[33] =  2'sd1;
    long_preamble[34] = -2'sd1;
    long_preamble[35] = -2'sd1;
    long_preamble[36] =  2'sd1;
    long_preamble[37] =  2'sd1;
    long_preamble[38] = -2'sd1;
    long_preamble[39] =  2'sd1;
    long_preamble[40] = -2'sd1;
    long_preamble[41] =  2'sd1;
    long_preamble[42] = -2'sd1;
    long_preamble[43] = -2'sd1;
    long_preamble[44] = -2'sd1;
    long_preamble[45] = -2'sd1;
    long_preamble[46] = -2'sd1;
    long_preamble[47] =  2'sd1;
    long_preamble[48] =  2'sd1;
    long_preamble[49] = -2'sd1;
    long_preamble[50] = -2'sd1;
    long_preamble[51] =  2'sd1;
    long_preamble[52] = -2'sd1;
    long_preamble[53] =  2'sd1;
    long_preamble[54] = -2'sd1;
    long_preamble[55] =  2'sd1;
    long_preamble[56] =  2'sd1;
    long_preamble[57] =  2'sd1;
    long_preamble[58] =  2'sd1;
    long_preamble[59] =  2'sd0;
    long_preamble[60] =  2'sd0;
    long_preamble[61] =  2'sd0;
    long_preamble[62] =  2'sd0;
    long_preamble[63] =  2'sd0;
  end

endmodule
