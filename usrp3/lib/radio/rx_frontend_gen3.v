//
// Copyright 2015 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
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
  wire               phase_dir;
  wire               phase_reset;

  reg  [23:0]        adc_i_mux, adc_q_mux;
  reg                adc_mux_stb;
  wire [23:0]        adc_i_ofs, adc_q_ofs, adc_i_comp, adc_q_comp;
  reg  [23:0]        adc_i_ofs_dly, adc_q_ofs_dly;
  wire               adc_ofs_stb, adc_comp_stb;
  reg  [1:0]         adc_ofs_stb_dly;
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

  // Setting reg: 1 bit to set phase direction: default to 0:
  //   direction bit == 0: the phase is increased by pi/2 (counter clockwise)
  //   direction bit == 1: the phase is increased by -pi/2 (clockwise)
  setting_reg #(.my_addr(SR_HET_PHASE_INCR), .width(1)) sr_phase_dir (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(phase_dir),.changed(phase_reset));

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

      mult_add_clip #(
        .WIDTH_A(18),
        .BIN_PT_A(17),
        .WIDTH_B(18),
        .BIN_PT_B(17),
        .WIDTH_C(24),
        .BIN_PT_C(23),
        .WIDTH_O(24),
        .BIN_PT_O(23),
        .LATENCY(2)
      ) mult_i (
        .clk(clk),
        .reset(reset),
        .CE(1'b1),
        .A(adc_i_ofs[23:6]),
        .B(mag_corr),
        .C(adc_i_ofs),
        .O(adc_i_comp)
      );

      mult_add_clip #(
        .WIDTH_A(18),
        .BIN_PT_A(17),
        .WIDTH_B(18),
        .BIN_PT_B(17),
        .WIDTH_C(24),
        .BIN_PT_C(23),
        .WIDTH_O(24),
        .BIN_PT_O(23),
        .LATENCY(2)
      ) mult_q (
        .clk(clk),
        .reset(reset),
        .CE(1'b1),
        .A(adc_i_ofs[23:6]),
        .B(phase_corr),
        .C(adc_q_ofs),
        .O(adc_q_comp)
      );

      // Delay to match path latencies
      always @(posedge clk) begin
        if (reset) begin
          adc_ofs_stb_dly <= 2'b0;
        end else begin
          adc_ofs_stb_dly <= {adc_ofs_stb_dly[0], adc_ofs_stb};
        end
      end

      assign adc_comp_stb = adc_ofs_stb_dly[1];

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

      wire [24:0] adc_i_dsp_cout, adc_q_dsp_cout;
      wire [23:0] adc_i_cclip, adc_q_cclip;
      wire [23:0] adc_i_hb, adc_q_hb;
      wire [23:0] adc_i_dec, adc_q_dec;
      wire        adc_dsp_cout_stb;
      wire        adc_cclip_stb;
      wire        adc_hb_stb;

      wire valid_hbf0;
      wire valid_hbf1;
      wire valid_dec0;
      wire valid_dec1;

      // 90 degree mixer
      quarter_rate_downconverter #(.WIDTH(24)) qr_dc_i(
        .clk(clk), .reset(reset || sync_in),
        .i_tdata({adc_i_comp, adc_q_comp}), .i_tlast(1'b1), .i_tvalid(adc_comp_stb), .i_tready(),
        .o_tdata({adc_i_dsp_cout, adc_q_dsp_cout}), .o_tlast(), .o_tvalid(adc_dsp_cout_stb), .o_tready(1'b1),
        .dirctn(phase_dir));

      // Double FIR and decimator block
      localparam HB_COEFS = {-18'd62, 18'd0, 18'd194, 18'd0, -18'd440, 18'd0, 18'd855, 18'd0, -18'd1505, 18'd0, 18'd2478, 18'd0,
        -18'd3900, 18'd0, 18'd5990, 18'd0, -18'd9187, 18'd0, 18'd14632, 18'd0, -18'd26536, 18'd0, 18'd83009, 18'd131071, 18'd83009,
        18'd0, -18'd26536, 18'd0, 18'd14632, 18'd0, -18'd9187, 18'd0, 18'd5990, 18'd0, -18'd3900, 18'd0, 18'd2478, 18'd0, -18'd1505,
        18'd0, 18'd855, 18'd0, -18'd440, 18'd0, 18'd194, 18'd0, -18'd62};

      axi_fir_filter_dec #(
          .WIDTH(24),
          .COEFF_WIDTH(18),
          .NUM_COEFFS(47),
          .COEFFS_VEC(HB_COEFS),
          .BLANK_OUTPUT(0)
        ) ffd0 (
        .clk(clk), .reset(reset || sync_in),

        .i_tdata({adc_i_dsp_cout, adc_q_dsp_cout}),
        .i_tlast(1'b1),
        .i_tvalid(adc_dsp_cout_stb),
        .i_tready(),

        .o_tdata({adc_i_dec, adc_q_dec}),
        .o_tlast(),
        .o_tvalid(adc_hb_stb),
        .o_tready(1'b1));

      assign adc_dsp_stb = realmode_decim ? adc_hb_stb : adc_comp_stb;
      assign adc_i_dsp   = realmode_decim ? adc_i_dec : adc_i_comp;
      assign adc_q_dsp   = realmode_decim ? adc_q_dec : adc_q_comp;

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
