//
// Copyright 2015 Ettus Research LLC
//

module rx_frontend_gen3 #(
  parameter SR_MAG_CORRECTION = 0,
  parameter SR_PHASE_CORRECTION = 1,
  parameter SR_OFFSET_I = 2,
  parameter SR_OFFSET_Q = 3,
  parameter SR_IQ_MAPPING = 4,
  parameter SR_HET_PHASE_INCR = 5,
  parameter BYPASS_DC_OFFSET_CORR = 0,
  parameter BYPASS_IQ_COMP = 0,
  parameter BYPASS_REALMODE_DSP = 0,
  parameter DEVICE = "7SERIES"
)(
  input clk, input reset, input sync_in,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input adc_stb, input [15:0] adc_i, input [15:0] adc_q,
  output rx_stb, output [15:0] rx_i, output [15:0] rx_q
);

  wire               realmode;
  wire               swap_iq;
  wire               invert_i;
  wire               invert_q;
  wire               realmode_decim;
  wire               bypass_all;
  wire [1:0]         iq_map_reserved;
  wire [17:0]        mag_corr, phase_corr;
  wire [31:0]        phase_incr;
  wire               phase_reset;

  reg  [23:0]        adc_i_mux, adc_q_mux;
  reg                adc_mux_stb;
  wire [23:0]        adc_i_ofs, adc_q_ofs, adc_i_comp, adc_q_comp;
  reg  [23:0]        adc_i_ofs_dly, adc_q_ofs_dly;
  wire               adc_ofs_stb, adc_comp_stb;
  reg                adc_ofs_stb_dly;
  wire [23:0]        adc_i_dsp, adc_q_dsp;
  wire               adc_dsp_stb;
  wire [35:0]        corr_i, corr_q;
  wire [15:0]        rx_i_out, rx_q_out;

  /********************************************************
  ** Settings Bus Registers
  ********************************************************/
  setting_reg #(.my_addr(SR_MAG_CORRECTION),.width(18)) sr_mag_corr (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(mag_corr),.changed());

  setting_reg #(.my_addr(SR_PHASE_CORRECTION),.width(18)) sr_phase_corr (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(phase_corr),.changed());

  setting_reg #(.my_addr(SR_IQ_MAPPING), .width(8)) sr_mux_sel (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out({bypass_all,iq_map_reserved,realmode_decim,invert_i,invert_q,realmode,swap_iq}),.changed());

  setting_reg #(.my_addr(SR_HET_PHASE_INCR), .width(32)) sr_het_phase_incr (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(phase_incr),.changed(phase_reset));

  /********************************************************
  ** IQ Mapping (swapping, inversion, real-mode)
  ********************************************************/
  // MUX so we can do realmode signals on either input
  always @(posedge clk) begin
    if (swap_iq) begin
      adc_i_mux[23:8] <= invert_q ? ~adc_q   : adc_q;
      adc_q_mux[23:8] <= realmode ? 16'd0 : invert_i ? ~adc_i : adc_i;
    end else begin
      adc_i_mux[23:8] <= invert_i ? ~adc_i   : adc_i;
      adc_q_mux[23:8] <= realmode ? 16'd0 : invert_q ? ~adc_q : adc_q;
    end
    adc_mux_stb <= adc_stb;
    adc_i_mux[7:0] <= 8'd0;
    adc_q_mux[7:0] <= 8'd0;
  end

  /********************************************************
  ** DC offset Correction
  ********************************************************/
  generate
    if (BYPASS_DC_OFFSET_CORR == 0) begin

      rx_dcoffset #(.WIDTH(24),.ADDR(SR_OFFSET_I)) rx_dcoffset_i (
        .clk(clk),.rst(reset),.set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
        .in_stb(adc_mux_stb),.in(adc_i_mux),
        .out_stb(adc_ofs_stb),.out(adc_i_ofs));
      rx_dcoffset #(.WIDTH(24),.ADDR(SR_OFFSET_Q)) rx_dcoffset_q (
        .clk(clk),.rst(reset),.set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
        .in_stb(adc_mux_stb),.in(adc_q_mux),
        .out_stb(),.out(adc_q_ofs));

    end else begin
      assign adc_ofs_stb = adc_mux_stb;
      assign adc_i_ofs   = adc_i_mux;
      assign adc_q_ofs   = adc_q_mux;
    end
  endgenerate

  /********************************************************
  ** IQ Imbalance Compensation
  ********************************************************/
  generate
    if (BYPASS_IQ_COMP == 0) begin

      MULT_MACRO #(
        .DEVICE(DEVICE), .LATENCY(1),
        .WIDTH_A(18), .WIDTH_B(18))
      mult_i (
        .CLK(clk), .RST(reset), .CE(adc_ofs_stb),
        .P(corr_i), .A(adc_i_ofs[23:6]), .B(mag_corr));
      MULT_MACRO #(
        .DEVICE(DEVICE), .LATENCY(1),
        .WIDTH_A(18), .WIDTH_B(18))
      mult_q (
        .CLK(clk), .RST(reset), .CE(adc_ofs_stb),
        .P(corr_q), .A(adc_i_ofs[23:6]), .B(phase_corr));

      // Delay to match path latencies
      always @(posedge clk) begin
        if (reset) begin
          adc_ofs_stb_dly <= 1'b0;
          adc_i_ofs_dly   <= 24'd0;
          adc_q_ofs_dly   <= 24'd0;
        end else begin
          adc_ofs_stb_dly <= adc_ofs_stb;
          if (adc_ofs_stb) begin
            adc_i_ofs_dly <= adc_i_ofs;
            adc_q_ofs_dly <= adc_q_ofs;
          end
        end
      end

      add2_and_clip_reg #(.WIDTH(24))
      add_clip_i (
        .clk(clk), .rst(reset),
        .in1(adc_i_ofs_dly), .in2(corr_i[35:12]), .strobe_in(adc_ofs_stb_dly),
        .sum(adc_i_comp), .strobe_out(adc_comp_stb));
      add2_and_clip_reg #(.WIDTH(24))
      add_clip_q (
        .clk(clk), .rst(reset), 
        .in1(adc_q_ofs_dly), .in2(corr_q[35:12]), .strobe_in(adc_ofs_stb_dly),
        .sum(adc_q_comp), .strobe_out());

    end else begin
      assign adc_comp_stb = adc_ofs_stb;
      assign adc_i_comp   = adc_i_ofs;
      assign adc_q_comp   = adc_q_ofs;
    end
  endgenerate

  /********************************************************
  ** Realmode DSP:
  *  - Heterodyne frequency translation
  *  - Realmode decimation (by 2)
  ********************************************************/
  generate
    if (BYPASS_REALMODE_DSP == 0) begin

      // NCO for CORDIC
      reg [31:0] phase;
      always @(posedge clk) begin
        if (reset || phase_reset || sync_in)
          phase <= 32'd0;
        else if (adc_dsp_cin_stb)
          phase <= phase + phase_incr;
      end

      wire [24:0] adc_i_dsp_cin, adc_q_dsp_cin;
      wire [24:0] adc_i_dsp_cout, adc_q_dsp_cout;
      wire [23:0] adc_i_cclip, adc_q_cclip;
      wire [46:0] adc_i_hb, adc_q_hb;
      wire        adc_dsp_cin_stb, adc_dsp_cout_stb;
      wire        adc_cclip_stb;
      wire        adc_hb_stb;

      sign_extend #(.bits_in(24), .bits_out(25)) sign_extend_cordic_i (
        .in(adc_i_comp), .out(adc_i_dsp_cin));
      sign_extend #(.bits_in(24), .bits_out(25)) sign_extend_cordic_q (
        .in(adc_q_comp), .out(adc_q_dsp_cin));
      assign adc_dsp_cin_stb = adc_comp_stb;   //sign_extend has 0 latency

     // CORDIC  24-bit I/O
      cordic #(.bitwidth(25)) het_cordic_i (
        .clk(clk), .reset(reset || sync_in), .enable(1'b1),
        .strobe_in(adc_dsp_cin_stb), .strobe_out(adc_dsp_cout_stb),
        .last_in(1'b0), .last_out(),
        .xi(adc_i_dsp_cin),. yi(adc_q_dsp_cin), .zi(phase[31:8]),
        .xo(adc_i_dsp_cout),.yo(adc_q_dsp_cout),.zo());

      clip_reg #(.bits_in(25), .bits_out(24)) clip_cordic_i (
        .clk(clk), .in(adc_i_dsp_cout), .out(adc_i_cclip),
        .strobe_in(adc_dsp_cout_stb), .strobe_out(adc_cclip_stb));
      clip_reg #(.bits_in(25), .bits_out(24)) clip_cordic_q (
        .clk(clk), .in(adc_q_dsp_cout), .out(adc_q_cclip),
        .strobe_in(adc_dsp_cout_stb), .strobe_out());

      // Half-band decimator for heterodyne signals
      // We assume that hbdec1 can accept a sample per cycle
      hbdec1 het_hbdec_i (
        .clk(clk), .sclr(reset || sync_in), .ce(1'b1),
        .coef_ld(1'b0), .coef_we(1'b0), .coef_din(18'd0),
        .rfd(), .nd(adc_cclip_stb),
        .din_1(adc_i_cclip), .din_2(adc_q_cclip),
        .rdy(), .data_valid(adc_hb_stb),
        .dout_1(adc_i_hb), .dout_2(adc_q_hb));

      localparam  HB_SCALE = 17;
      assign adc_dsp_stb = realmode_decim ? adc_hb_stb : adc_cclip_stb;
      assign adc_i_dsp   = realmode_decim ? adc_i_hb[23+HB_SCALE:HB_SCALE] : adc_i_cclip;
      assign adc_q_dsp   = realmode_decim ? adc_q_hb[23+HB_SCALE:HB_SCALE] : adc_q_cclip;

    end else begin
      assign adc_dsp_stb = adc_comp_stb;
      assign adc_i_dsp   = adc_i_comp;
      assign adc_q_dsp   = adc_q_comp;
    end
  endgenerate

  // Round to short complex (sc16)
  round_sd #(.WIDTH_IN(24),.WIDTH_OUT(16)) round_i (
    .clk(clk),.reset(reset), .in(adc_i_dsp),.strobe_in(adc_dsp_stb), .out(rx_i_out), .strobe_out(rx_stb));
  round_sd #(.WIDTH_IN(24),.WIDTH_OUT(16)) round_q (
    .clk(clk),.reset(reset), .in(adc_q_dsp),.strobe_in(adc_dsp_stb), .out(rx_q_out), .strobe_out());
    
  assign rx_i = bypass_all ? adc_i : rx_i_out;
  assign rx_q = bypass_all ? adc_q : rx_q_out;

endmodule
