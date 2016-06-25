//
// Copyright 2016 Ettus Research
//

//! RFNoC specific digital up-conversion chain
// High level block diagram:
//
// CIC -> HB1 -> HB2 -> CORDIC -> Scaler

// We don't care about framing here, hence no tlast

module duc #(
  parameter SR_PHASE_INC_ADDR = 0,
  parameter SR_SCALE_ADDR     = 1,
  parameter SR_INTERP_ADDR    = 2
)(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [31:0] i_tdata, input [127:0] i_tuser, input i_tvalid, output i_tready,
  output [31:0] o_tdata, output [127:0] o_tuser, output o_tvalid, input o_tready
);

  localparam RESET_DELAY = 3;

  localparam WIDTH  = 16;
  localparam CWIDTH = 24;
  localparam PWIDTH = 32;

  localparam CLIP_BITS = 14;

  reg  [1:0] hb_rate;
  reg  [7:0] cic_interp_rate;

  wire [1:0] hb_rate_int;
  wire [7:0] cic_interp_rate_int;

  wire [2*CWIDTH-1:0] o_tdata_halfbands;
  wire o_tvalid_halfbands;

  wire rate_changed;
  wire reset_on_change;

  wire [PWIDTH-1:0] o_tdata_phase;
  wire o_tvalid_phase;
  wire o_tlast_phase;
  wire i_tready_phase;

  wire [WIDTH-1:0] o_tdata_scale;
  wire o_tvalid_scale;
  wire i_tready_scale;

 /**************************************************************************
  * Settings registers
  **************************************************************************/
  // AXI settings bus for phase values
  axi_setting_reg #(
    .ADDR(SR_PHASE_INC_ADDR), .AWIDTH(8), .WIDTH(PWIDTH), .STROBE_LAST(1), .REPEATS(1))
  axi_sr_phase (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(o_tdata_phase), .o_tlast(o_tlast_phase), .o_tvalid(o_tvalid_phase), .o_tready(i_tready_phase));

  axi_setting_reg #(
    .ADDR(SR_SCALE_ADDR), .AWIDTH(8), .WIDTH(WIDTH), .REPEATS(1))
  axi_sr_scale (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(o_tdata_scale), .o_tlast(), .o_tvalid(o_tvalid_scale), .o_tready(i_tready_scale));

  setting_reg #(.my_addr(SR_INTERP_ADDR), .width(10), .at_reset(1)) sr_interp
    (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
     .in(set_data),.out({hb_rate_int,cic_interp_rate_int}),.changed(rate_changed));

  // Prevent changing interpolation rates while processing
  reg active, rate_changed_hold;
  reg [RESET_DELAY-1:0] shift_reset;
  always @(posedge clk) begin
    if (reset) begin
      active            <= 1'b0;
      rate_changed_hold <= 1'b0;
      cic_interp_rate   <= 'd0;
      hb_rate           <= 'd0;
      shift_reset       <= 'd0;
    end else begin
      if (clear) begin
        active <= 1'b0;
      end else if (o_tready & i_tvalid) begin
        active <= 1'b1;
      end
      if (rate_changed & active) begin
        rate_changed_hold <= 1'b1;
      end
      if (~active & (rate_changed | rate_changed_hold)) begin
        rate_changed_hold <= 1'b0;
        cic_interp_rate   <= cic_interp_rate_int;
        hb_rate           <= hb_rate_int;
        shift_reset       <= {shift_reset[RESET_DELAY-1:0], 1'b1};
      end else begin
        shift_reset       <= {shift_reset[RESET_DELAY-1:0], 1'b0};
      end
    end
  end

  assign reset_on_change = |shift_reset;

 /**************************************************************************
  * Halfbands
  *************************************************************************/

  // Sign extend from 16 to 24 bits to increase the accuracy from the CORDIC
  wire [2*CWIDTH-1:0] o_tdata_extd;

  sign_extend #(.bits_in(WIDTH), .bits_out(CWIDTH)) sign_extend_in_i (
    .in(i_tdata[2*WIDTH-1:WIDTH]), .out(o_tdata_extd[2*CWIDTH-1:CWIDTH]));

  sign_extend #(.bits_in(WIDTH), .bits_out(CWIDTH)) sign_extend_in_q (
    .in(i_tdata[WIDTH-1:0]), .out(o_tdata_extd[CWIDTH-1:0]));

  wire [2*CWIDTH-1:0] o_tdata_hb1;
  wire o_tvalid_hb1, o_tready_hb1;

  axi_hb47 halfband1 (
    .aclk(clk),
    .aresetn(~(reset | clear | reset_on_change)),
    .s_axis_data_tvalid(i_tvalid),
    .s_axis_data_tready(i_tready_hb1),
    .s_axis_data_tdata(o_tdata_extd),
    .m_axis_data_tvalid(o_tvalid_hb1),
    .m_axis_data_tready(o_tready_hb1),
    .m_axis_data_tdata(o_tdata_hb1)
  );

  wire [2*CWIDTH-1:0] o_tdata_hb2;
  wire o_tvalid_hb2, o_tready_hb2;

  axi_hb47 halfband2 (
    .aclk(clk),
    .aresetn(~(reset | clear | reset_on_change)),
    .s_axis_data_tvalid(o_tvalid_hb1),
    .s_axis_data_tready(i_tready_hb2),
    .s_axis_data_tdata({o_tdata_hb1[2*CWIDTH-1:CWIDTH] << 2, o_tdata_hb1[CWIDTH-1:0] << 2}),
    .m_axis_data_tvalid(o_tvalid_hb2),
    .m_axis_data_tready(o_tready_hb2),
    .m_axis_data_tdata(o_tdata_hb2)
  );

 /**************************************************************************
  * Halfband selection multiplexing
  *************************************************************************/
  wire [2*CWIDTH-1:0] o_tdata_cic;
  wire [2*CWIDTH-1:0] o_cic;
  wire o_tvalid_cic, i_tready_cic;

  assign o_tdata_halfbands = (hb_rate == 2'b0) ? o_tdata_extd : 
                             (hb_rate == 2'b1) ? {o_tdata_hb1[2*CWIDTH-1:CWIDTH] << 2, o_tdata_hb1[CWIDTH-1:0] << 2} :
                                                 {o_tdata_hb2[2*CWIDTH-1:CWIDTH] << 2, o_tdata_hb2[CWIDTH-1:0] << 2};

  assign o_tvalid_halfbands = (hb_rate == 2'b0) ? i_tvalid :
                              (hb_rate == 2'b1) ? o_tvalid_hb1 :
                                                  o_tvalid_hb2;

  assign i_tready     = (hb_rate == 2'b0) ? i_tready_cic : i_tready_hb1;
  assign o_tready_hb1 = (hb_rate == 2'b1) ? i_tready_cic : i_tready_hb2;
  assign o_tready_hb2 = i_tready_cic;

 /**************************************************************************
  * Ettus CIC; the Xilinx CIC has a minimum interpolation of 4,
  * so we use the strobed version and convert to and from AXI.
  *************************************************************************/
  wire to_cic_stb, from_cic_stb;
  wire [2*CWIDTH-1:0] to_cic_data;
  wire [CWIDTH-1:0] i_cic;
  wire [CWIDTH-1:0] q_cic;

  // Convert from AXI to strobed and back to AXI again for the CIC interpolation module
  axi_to_strobed #(.WIDTH(2*CWIDTH), .FIFO_SIZE(1), .MIN_RATE(128)) axi_to_strobed (
    .clk(clk), .reset(reset), .clear(clear),
    .out_rate(cic_interp_rate), .ready(i_tready_cartesian & o_tready), .error(),
    .i_tdata(o_tdata_halfbands), .i_tvalid(o_tvalid_halfbands), .i_tlast(1'b0), .i_tready(i_tready_cic),
    .out_stb(to_cic_stb), .out_last(), .out_data(to_cic_data)
  );

  cic_interpolate #(.WIDTH(CWIDTH), .N(4), .MAX_RATE(128)) cic_interpolate_i (
    .clk(clk), .reset(reset | clear),
    .rate_stb(reset_on_change),
    .rate(cic_interp_rate), .strobe_in(to_cic_stb), .strobe_out(from_cic_stb),
    .signal_in(to_cic_data[CWIDTH-1:0]), .signal_out(i_cic)
  );

  cic_interpolate #(.WIDTH(CWIDTH), .N(4), .MAX_RATE(128)) cic_interpolate_q (
    .clk(clk), .reset(reset | clear),
    .rate_stb(reset_on_change),
    .rate(cic_interp_rate), .strobe_in(to_cic_stb), .strobe_out(),
    .signal_in(to_cic_data[2*CWIDTH-1:CWIDTH]), .signal_out(q_cic)
  );

  assign o_cic = {i_cic, q_cic};

  strobed_to_axi #(.WIDTH(2*CWIDTH), .FIFO_SIZE(8)) strobed_to_axi (
    .clk(clk), .reset(reset), .clear(clear),
    .in_stb(from_cic_stb), .in_data(o_cic), .in_last(1'b0),
    .o_tdata(o_tdata_cic), .o_tvalid(o_tvalid_cic), .o_tlast(), .o_tready(i_tready_cartesian)
  );

 /**************************************************************************
  * CORDIC
  *************************************************************************/

  // Phase accumulator for tracking the phase into the CORDIC
  wire [CWIDTH-1:0] o_tdata_acc;
  wire o_tvalid_acc, i_tready_acc;

  phase_accum #(.WIDTH_ACCUM(CWIDTH), .WIDTH_IN(CWIDTH), .WIDTH_OUT(CWIDTH))
  phase_acc (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(o_tdata_phase[PWIDTH-1:PWIDTH-CWIDTH]), .i_tlast(o_tlast_phase), .i_tvalid(1'b1), .i_tready(i_tready_phase),
    .o_tdata(o_tdata_acc), .o_tlast(), .o_tvalid(o_tvalid_acc), .o_tready(i_tready_acc)
  );

  // Xilinx IP AXI CORDIC
  wire [2*CWIDTH-1:0] o_tdata_cordic;
  wire o_tvalid_cordic, o_tready_cordic;
  cordic_rotator24 cordic (
    .aclk(clk),
    .aresetn(~(reset | clear)),

    /* IQ input */
    .s_axis_cartesian_tvalid(o_tvalid_cic),
    .s_axis_cartesian_tready(i_tready_cartesian),
    .s_axis_cartesian_tdata(o_tdata_cic),

    /* Phase input from NCO */
    .s_axis_phase_tvalid(o_tvalid_acc),
    .s_axis_phase_tready(i_tready_acc),
    .s_axis_phase_tdata(o_tdata_acc),

    /* IQ output */
    .m_axis_dout_tvalid(o_tvalid_cordic),
    .m_axis_dout_tready(o_tready_cordic),
    .m_axis_dout_tdata(o_tdata_cordic)
  );

 /**************************************************************************
  * Perform scaling on the IQ output
  *************************************************************************/
  wire [CWIDTH-1:0] ii_tdata, iq_tdata;
  wire ii_tvalid, ii_tready;
  wire iq_tvalid, iq_tready;

  split_complex #(.WIDTH(CWIDTH)) split_complex (
    .i_tdata(o_tdata_cordic), .i_tlast(1'b0), .i_tvalid(o_tvalid_cordic), .i_tready(o_tready_cordic),
    .oi_tdata(ii_tdata), .oi_tlast(), .oi_tvalid(ii_tvalid), .oi_tready(ii_tready),
    .oq_tdata(iq_tdata), .oq_tlast(), .oq_tvalid(iq_tvalid), .oq_tready(iq_tready),
    .error()
  );

  wire [CWIDTH+WIDTH-1:0] o_tdata_i_prod, o_tdata_q_prod;
  wire o_tvalid_prod;
  wire o_tready_prod;

  mult #(
   .WIDTH_A(CWIDTH),
   .WIDTH_B(WIDTH),
   .WIDTH_P(CWIDTH+WIDTH),
   .DROP_TOP_P(0),
   .LATENCY(4),
   .CASCADE_OUT(0))
  i_mult (
    .clk(clk), .reset(reset),
    .a_tdata(ii_tdata), .a_tlast(1'b0), .a_tvalid(ii_tvalid), .a_tready(ii_tready),
    .b_tdata(o_tdata_scale), .b_tlast(1'b0), .b_tvalid(o_tvalid_scale), .b_tready(i_tready_scale),
    .p_tdata(o_tdata_i_prod), .p_tlast(), .p_tvalid(o_tvalid_prod), .p_tready(o_tready_prod));

  mult #(
   .WIDTH_A(CWIDTH),
   .WIDTH_B(WIDTH),
   .WIDTH_P(CWIDTH+WIDTH),
   .DROP_TOP_P(0),
   .LATENCY(4),
   .CASCADE_OUT(0))
  q_mult (
    .clk(clk), .reset(reset),
    .a_tdata(iq_tdata), .a_tlast(1'b0), .a_tvalid(iq_tvalid), .a_tready(iq_tready),
    .b_tdata(o_tdata_scale), .b_tlast(1'b0), .b_tvalid(o_tvalid_scale), .b_tready(),
    .p_tdata(o_tdata_q_prod), .p_tlast(), .p_tvalid(), .p_tready(o_tready_prod));

  wire [2*WIDTH-1:0] o_tdata_final_rc;
  wire o_tvalid_final_rc, o_tready_final_rc;
  axi_round_and_clip_complex #(.WIDTH_IN(CWIDTH+WIDTH), .WIDTH_OUT(WIDTH), .CLIP_BITS(CLIP_BITS)) round_clip (
      .clk(clk), .reset(reset | clear),
      .i_tdata({o_tdata_q_prod, o_tdata_i_prod}), .i_tlast(1'b0), .i_tvalid(o_tvalid_prod), .i_tready(o_tready_prod),
      .o_tdata(o_tdata_final_rc), .o_tlast(), .o_tvalid(o_tvalid_final_rc), .o_tready(o_tready_final_rc));

 /**************************************************************************
  * Assign the outputs (and ready input) of the module
  *************************************************************************/
  assign o_tdata = o_tdata_final_rc;
  assign o_tvalid = o_tvalid_final_rc;
  assign o_tready_final_rc = o_tready;

endmodule // duc
