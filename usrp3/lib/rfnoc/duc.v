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

  reg  [1:0] hb_rate;
  reg  [7:0] cic_interp_rate;

  wire [1:0] hb_rate_int;
  wire [7:0] cic_interp_rate_int;

  wire [31:0] o_tdata_halfbands;
  wire o_tvalid_halfbands;

  wire rate_changed;
  wire reset_on_change;

  wire [15:0] o_tdata_phase;
  wire o_tlast_phase;
  wire o_tvalid_phase;
  wire i_tready_phase;

  wire [17:0] scale_factor;

 /**************************************************************************
  * Settings registers
  **************************************************************************/
  // AXI settings bus for phase values
  axi_setting_reg #(
    .ADDR(SR_PHASE_INC_ADDR), .AWIDTH(8), .WIDTH(16), .STROBE_LAST(1), .REPEATS(1))
  set_phase_acc (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(o_tdata_phase), .o_tlast(o_tlast_phase), .o_tvalid(o_tvalid_phase), .o_tready(i_tready_phase));

  setting_reg #(.my_addr(SR_SCALE_ADDR), .width(18)) sr_1 (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(scale_factor),.changed());

  setting_reg #(.my_addr(SR_INTERP_ADDR), .width(10), .at_reset(1)) sr_interp_word
    (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
     .in(set_data),.out({hb_rate_int,cic_interp_rate_int}),.changed(rate_changed));

  // Prevent changing interpolation rates while processing
  reg active, rate_changed_hold;
  reg [1:0] shift_reset;
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
        shift_reset       <= {shift_reset[0], 1'b1};
      end else begin
        shift_reset       <= {shift_reset[0], 1'b0};
      end
    end
  end

  assign reset_on_change = shift_reset[0] | shift_reset[1];

  /**************************************************************************
   * Ettus CIC; the Xilinx CIC has a minimum interpolation of 4,
   * so we use the strobed version and convert to and from AXI.
   *************************************************************************/
  wire [31:0] o_tdata_cic;
  wire [31:0] o_cic;
  wire o_tvalid_cic, o_tready_cic;

  wire to_cic_stb, from_cic_stb;
  wire [31:0] to_cic_data;
  wire [15:0] i_cic;
  wire [15:0] q_cic;

  // Convert from AXI to strobed and back to AXI again for the CIC interpolation module
  axi_to_strobed #(.WIDTH(32), .FIFO_SIZE(1), .MIN_RATE(128)) axi_to_strobed (
    .clk(clk), .reset(reset | reset_on_change), .clear(clear),
    .out_rate(cic_interp_rate), .ready(o_tready_cic & o_tready), .error(),
    .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tlast(1'b0), .i_tready(i_tready),
    .out_stb(to_cic_stb), .out_last(), .out_data(to_cic_data)
  );

  cic_interpolate #(.WIDTH(16), .N(4), .MAX_RATE(128)) cic_interpolate_i (
    .clk(clk), .reset(reset | clear),
    .rate_stb(reset_on_change),
    .rate(cic_interp_rate), .strobe_in(to_cic_stb), .strobe_out(from_cic_stb),
    .signal_in(to_cic_data[15:0]), .signal_out(i_cic)
  );

  cic_interpolate #(.WIDTH(16), .N(4), .MAX_RATE(128)) cic_interpolate_q (
    .clk(clk), .reset(reset | clear),
    .rate_stb(reset_on_change),
    .rate(cic_interp_rate), .strobe_in(to_cic_stb), .strobe_out(),
    .signal_in(to_cic_data[31:16]), .signal_out(q_cic)
  );

  assign o_cic = {i_cic, q_cic};

  strobed_to_axi #(.WIDTH(32), .FIFO_SIZE(8)) strobed_to_axi (
    .clk(clk), .reset(reset | reset_on_change), .clear(clear),
    .in_stb(from_cic_stb), .in_data(o_cic), .in_last(1'b0),
    .o_tdata(o_tdata_cic), .o_tvalid(o_tvalid_cic), .o_tlast(), .o_tready(o_tready_cic)
  );

 /**************************************************************************
  * Halfbands
  *************************************************************************/
  wire [31:0] o_tdata_hb1;
  wire o_tvalid_hb1, o_tready_hb1;

  axi_hb31 halfband1 (
    .aclk(clk),
    .aresetn(~(reset | clear | reset_on_change)),
    .s_axis_data_tvalid(o_tvalid_cic),
    .s_axis_data_tready(i_tready_hb1),
    .s_axis_data_tdata(o_tdata_cic),
    .m_axis_data_tvalid(o_tvalid_hb1),
    .m_axis_data_tready(o_tready_hb1),
    .m_axis_data_tdata(o_tdata_hb1)
  );

  wire [31:0] o_tdata_hb2;
  wire o_tvalid_hb2, o_tready_hb2;

  axi_hb31 halfband2 (
    .aclk(clk),
    .aresetn(~(reset | clear | reset_on_change)),
    .s_axis_data_tvalid(o_tvalid_hb1),
    .s_axis_data_tready(i_tready_hb2),
    .s_axis_data_tdata(o_tdata_hb1),
    .m_axis_data_tvalid(o_tvalid_hb2),
    .m_axis_data_tready(o_tready_hb2),
    .m_axis_data_tdata(o_tdata_hb2)
  );

 /**************************************************************************
  * Halfband selection multiplexing
  *************************************************************************/
  assign o_tdata_halfbands = (hb_rate == 2'b0) ? o_tdata_cic :
                             (hb_rate == 2'b1) ? o_tdata_hb1 :
                                                 o_tdata_hb2;

  assign o_tvalid_halfbands = (hb_rate == 2'b0) ? o_tvalid_cic :
                              (hb_rate == 2'b1) ? o_tvalid_hb1 :
                                                  o_tvalid_hb2;

  assign o_tready_cic = (hb_rate == 2'b0) ? i_tready_cartesian : i_tready_hb1;
  assign o_tready_hb1 = (hb_rate == 2'b1) ? i_tready_cartesian : i_tready_hb2;
  assign o_tready_hb2 = i_tready_cartesian;

 /**************************************************************************
  * CORDIC
  *************************************************************************/

  // Phase accumulator for tracking the phase into the CORDIC
  wire [15:0] o_tdata_acc;
  wire o_tvalid_acc, i_tready_acc;

  phase_accum phase_acc (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(o_tdata_phase), .i_tlast(o_tlast_phase), .i_tvalid(1'b1), .i_tready(i_tready_phase),
    .o_tdata(o_tdata_acc), .o_tlast(o_tlast_acc), .o_tvalid(o_tvalid_acc), .o_tready(i_tready_acc)
  );

  // Xilinx IP AXI CORDIC
  wire [31:0] o_tdata_cordic;
  wire o_tvalid_cordic, o_tready_cordic;
  cordic_rotator cordic (
    .aclk(clk),
    .aresetn(~(reset | clear)),

    /* IQ input */
    .s_axis_cartesian_tvalid(o_tvalid_halfbands & o_tvalid_acc),
    .s_axis_cartesian_tlast(o_tlast_acc),
    .s_axis_cartesian_tready(i_tready_cartesian),
    .s_axis_cartesian_tdata(o_tdata_halfbands),

    /* Phase input from NCO */
    .s_axis_phase_tvalid(o_tvalid_halfbands & o_tvalid_acc),
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
  wire [31:0] prod_i;
  wire [31:0] prod_q;

  MULT_MACRO #(
    .DEVICE("7SERIES"),     // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES" 
    .LATENCY(1),            // Desired clock cycle latency, 0-4
    .WIDTH_A(16),           // Multiplier A-input bus width, 1-25
    .WIDTH_B(16))           // Multiplier B-input bus width, 1-18
  SCALE_I (.P(prod_i),      // Multiplier output bus, width determined by WIDTH_P parameter
    .A(o_tdata_cordic[31:16]),     // Multiplier input A bus, width determined by WIDTH_A parameter
    .B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
    .CE(o_tvalid_cordic & o_tready_cordic),   // 1-bit active high input clock enable
    .CLK(clk),              // 1-bit positive edge clock input
    .RST(reset | clear));   // 1-bit input active high reset

  MULT_MACRO #(
    .DEVICE("7SERIES"),     // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES"
    .LATENCY(1),            // Desired clock cycle latency, 0-4
    .WIDTH_A(16),           // Multiplier A-input bus width, 1-25
    .WIDTH_B(16))           // Multiplier B-input bus width, 1-18
   SCALE_Q (.P(prod_q),     // Multiplier output bus, width determined by WIDTH_P parameter
    .A(o_tdata_cordic[15:0]),     // Multiplier input A bus, width determined by WIDTH_A parameter
    .B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
    .CE(o_tvalid_cordic & o_tready_cordic),   // 1-bit active high input clock enable
    .CLK(clk),              // 1-bit positive edge clock input
    .RST(reset | clear));   // 1-bit input active high reset

  wire [31:0] o_tdata_rc;
  wire o_tvalid_rc, o_tready_rc;
  axi_round_and_clip_complex #(.WIDTH_IN(32), .WIDTH_OUT(16)) round_clip (
      .clk(clk), .reset(reset | clear),
      .i_tdata({prod_i, prod_q}), .i_tlast(1'b0), .i_tvalid(o_tvalid_cordic), .i_tready(o_tready_cordic),
      .o_tdata(o_tdata_rc), .o_tlast(), .o_tvalid(o_tvalid_rc), .o_tready(o_tready_rc));

 /**************************************************************************
  * Assign the outputs (and ready input) of the module
  *************************************************************************/
  assign o_tdata = o_tdata_rc;
  assign o_tvalid = o_tvalid_rc;
  assign o_tready_rc = o_tready;

endmodule // duc
