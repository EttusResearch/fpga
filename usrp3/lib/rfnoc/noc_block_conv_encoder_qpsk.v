//
// Copyright 2015 Ettus Research LLC
//

module noc_block_conv_encoder_qpsk #(
  // Fixed values / sizes to reduce resource utilization at expense of flexibility.
  // If any parameters are set to 0, then the equivalent MAX_* parameter is used instead.
  // I.e. if FIXED_K = 0 then MAX_K will be used to determine register sizes.
  parameter FIXED_K = 7,                        // Fixed code length
  parameter FIXED_G_UPPER = 7'b1011011,         // Bit vector, length of K, upper branch generating XOR taps, default is NASA standard (7, 1/2) taps
  parameter FIXED_G_LOWER = 7'b1111001,         // Bit vector, length of K, lower branch generating XOR taps, default is NASA standard (7, 1/2) taps
  parameter FIXED_PUNCTURE_CODE_RATE = 3,       // 1 = 1/2, 2 = 2/3, 3 = 3/4, etc.
  parameter FIXED_PUNCTURE_VECTOR = 6'b110110,  // Bit vector, length is 2x code rate, interleaved (i.e. default is rate 3/4 -> [1 0 1; 1 1 0] -> 6'b110110)
  parameter FIXED_BITS_PER_SYMBOL = 2,          // Number of bits per symbol, up to 32
  // Maximum limits when not using fixed values above. Actual value set via settings registers.
  parameter MAX_K = 7,                          // Variable code length up to maximum
  parameter MAX_BITS_PER_SYMBOL = 2,            // Maximum bits per symbol, up to 32
  parameter MAX_PUNCTURE_CODE_RATE = 7,         // 0 = No puncturing, 1 = 1/2, 2 = 2/3, 3 = 3/4, etc.
  parameter NOC_ID = 64'hC0ED_0000_0000_0000,
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
  localparam SR_READBACK = 255;

  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;
  wire [15:0] next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 1;

  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  reg         m_axis_data_tready;

  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;

  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

  axi_wrapper #(
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
    .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS),
    .SIMPLE_MODE(1),
    // Note actually resizing the packet, but instead using RESIZE_OUTPUT_PACKET to 
    // generate tlast automatically.
    .RESIZE_OUTPUT_PACKET(1))
  inst_axi_wrapper (
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
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tuser(),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

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

  localparam [7:0] SR_USER_RESET         = 131; // User reset to clear out conv. encoder
  localparam [7:0] SR_K                  = 132; // Code length (up to MAX_K)
  localparam [7:0] SR_G_UPPER            = 133; // Generator taps for upper branch
  localparam [7:0] SR_G_LOWER            = 134; // Generator taps for lower branch
  localparam [7:0] SR_REVERSE_BITS       = 135; // Reverse bit order into convolutional encoder (0 = MSB, 1 = LSB first)
  localparam [7:0] SR_PUNCTURE_CODE_RATE = 136;
  localparam [7:0] SR_PUNCTURE_VECTOR    = 137;
  localparam [7:0] SR_BITS_PER_SYMBOL    = 138; // Number of bits per symbol (i.e. QPSK = 2)
  localparam [7:0] SR_SYMBOL_LUT_ADDR    = 139; // Write address of symbol mapper lookup table
  localparam [7:0] SR_SYMBOL_LUT_DATA    = 140; // Write data to symbol mapper lookup table
  localparam [7:0] SR_SWAP_IQ            = 141; // Swap IQ output

  // Settings Registers
  wire user_reset;
  setting_reg #(
    .my_addr(SR_USER_RESET), .awidth(8), .width(1), .at_reset(0))
  sr_user_reset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(user_reset), .changed());

  localparam K_WIDTH = (FIXED_K == 0) ? MAX_K : FIXED_K;
  localparam G_WIDTH = ((FIXED_G_UPPER == 0) && (FIXED_G_LOWER == 0)) ? MAX_K : FIXED_K;
  wire [$clog2(K_WIDTH)-1:0] k;
  wire [K_WIDTH-1:0] g_upper, g_lower;
  generate
    if (FIXED_K == 0) begin
      setting_reg #(
        .my_addr(SR_K), .awidth(8), .width($clog2(K_WIDTH)), .at_reset(0))
      sr_k (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(k), .changed());
    end else begin
      assign k = FIXED_K;
    end

    if ((FIXED_G_UPPER == 0) && (FIXED_G_LOWER == 0)) begin
      setting_reg #(
        .my_addr(SR_G_UPPER), .awidth(8), .width(MAX_K), .at_reset(0))
      sr_g_upper (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(g_upper), .changed());
      setting_reg #(
        .my_addr(SR_G_LOWER), .awidth(8), .width(MAX_K), .at_reset(0))
      sr_g_lower (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(g_lower), .changed());
    end else begin
      assign g_upper = FIXED_G_UPPER;
      assign g_lower = FIXED_G_LOWER;
    end
  endgenerate

  wire reverse_bits;
  setting_reg #(
    .my_addr(SR_REVERSE_BITS), .awidth(8), .width(1), .at_reset(0))
  sr_fft_reset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(reverse_bits), .changed());
  wire swap_iq;
  setting_reg #(
    .my_addr(SR_SWAP_IQ), .awidth(8), .width(1), .at_reset(0))
  sr_swap_iq (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(swap_iq), .changed());

  localparam P_WIDTH = (FIXED_PUNCTURE_CODE_RATE == 0) ? MAX_PUNCTURE_CODE_RATE : FIXED_PUNCTURE_CODE_RATE;
  wire code_rate_stb;
  wire [$clog2(P_WIDTH)-1:0] code_rate;
  wire [2*P_WIDTH-1:0] puncture_vector;
  generate
    if (FIXED_PUNCTURE_CODE_RATE == 0) begin
      setting_reg #(
        .my_addr(SR_PUNCTURE_CODE_RATE), .awidth(8), .width($clog2(MAX_PUNCTURE_CODE_RATE)), .at_reset(0))
      sr_fft_reset (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(code_rate), .changed(code_rate_stb));
      setting_reg #(
        .my_addr(SR_PUNCTURE_VECTOR), .awidth(8), .width(2*MAX_PUNCTURE_CODE_RATE), .at_reset(0))
      sr_puncture_vector (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(puncture_vector), .changed());
    end else begin
      assign code_rate_stb = 1'b0;
      assign code_rate = FIXED_PUNCTURE_CODE_RATE;
      assign puncture_vector = FIXED_PUNCTURE_VECTOR;
    end
  endgenerate

  localparam BIT_WIDTH = (FIXED_BITS_PER_SYMBOL == 0) ? MAX_BITS_PER_SYMBOL : FIXED_BITS_PER_SYMBOL;
  wire [$clog2(BIT_WIDTH)-1:0] bits_per_symbol;
  generate
    if (FIXED_BITS_PER_SYMBOL == 0) begin
      setting_reg #(
        .my_addr(SR_BITS_PER_SYMBOL), .awidth(8), .width($clog2(MAX_BITS_PER_SYMBOL)), .at_reset(0))
      sr_bits_per_symbol (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(bits_per_symbol), .changed());
    end else begin
      assign bits_per_symbol = FIXED_BITS_PER_SYMBOL;
    end
  endgenerate

  wire [BIT_WIDTH-1:0] symbol_lut_wr_addr;
  setting_reg #(
    .my_addr(SR_SYMBOL_LUT_ADDR), .awidth(8), .width(BIT_WIDTH), .at_reset(0))
  sr_symbol_lut_wr_addr (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(symbol_lut_wr_addr), .changed());
  wire [31:0] symbol_lut_wr_data;
  wire symbol_lut_wr_data_stb;
  setting_reg #(
    .my_addr(SR_SYMBOL_LUT_DATA), .awidth(8), .width(32), .at_reset(0))
  sr_symbol_lut_wr_data (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(symbol_lut_wr_data), .changed(symbol_lut_wr_data_stb));

  // Readback registers
  always @*
    case(rb_addr)
      8'd0    : rb_data <= {63'd0, user_reset};
      8'd1    : rb_data <= {K_WIDTH};
      8'd2    : rb_data <= {G_WIDTH};
      8'd3    : rb_data <= {P_WIDTH};
      8'd4    : rb_data <= {BIT_WIDTH};
      default : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase


  ////////////////////////////////////////////////////////////
  //
  // DSP
  //
  ////////////////////////////////////////////////////////////

  // Convolutional Encoder
  reg shift_en;
  reg [4:0] shift_cnt;
  reg [$clog2(K_WIDTH)-1:0] warmup_cnt;
  reg [31:0] buff_shift_reg;
  reg [K_WIDTH-1:0] conv_shift_reg;
  wire bit_upper, bit_lower;
  wire [1:0] bit_tdata, bit_reg_tdata;
  reg bit_tvalid;
  wire bit_tready, bit_reg_tvalid, bit_reg_tready;

  wire [31:0] m_axis_data_tdata_reversed;
  genvar r;
  generate 
    for (r = 0; r < 32; r = r + 1) assign m_axis_data_tdata_reversed[31-r] = m_axis_data_tdata[r];
  endgenerate

  always @(posedge ce_clk) begin
    if (ce_rst | user_reset) begin
      m_axis_data_tready <= 1'b0;
      bit_tvalid         <= 1'b0;
      shift_en           <= 1'b0;
      conv_shift_reg     <= 'd0;
      buff_shift_reg     <= 'd0;
      shift_cnt          <= 0;
      warmup_cnt         <= 0;
    end else begin
      if (bit_tready && shift_en) begin
        // Output valid after conv_shift_reg has filled
        if (warmup_cnt == k-1) begin
          bit_tvalid                <= 1'b1;
        end else begin
          warmup_cnt                <= warmup_cnt + 1;
        end
        conv_shift_reg[K_WIDTH-1:1] <= conv_shift_reg[K_WIDTH-2:0];
        conv_shift_reg[0]           <= buff_shift_reg[31];
        buff_shift_reg[31:1]        <= buff_shift_reg[30:0];
        if (shift_cnt == 31) begin
          if (~(m_axis_data_tvalid & m_axis_data_tready)) begin
            shift_en                <= 1'b0;
            bit_tvalid              <= 1'b0;
          end
          shift_cnt                 <= 0;
        end else begin
          shift_cnt                 <= shift_cnt + 1;
        end
        if (shift_cnt == 30) begin
          m_axis_data_tready        <= 1'b1;
        end
      end
      if (~shift_en) begin
        m_axis_data_tready          <= 1'b1;
      end
      if (m_axis_data_tvalid & m_axis_data_tready) begin
        m_axis_data_tready          <= 1'b0;
        if (reverse_bits) begin
          buff_shift_reg            <= m_axis_data_tdata_reversed;
        end else begin
          buff_shift_reg            <= m_axis_data_tdata;
        end
        shift_en                    <= 1'b1;
      end
    end
  end

  // Since length K might be variable, generate a mask to AND with 
  // conv_shift_reg to limit which input bits will generate the encoded output bits.
  reg [K_WIDTH:0] k_mask;
  always @(posedge ce_clk) k_mask <= (1'b1 << k) - 1'b1;

  assign bit_upper = ^(g_upper & conv_shift_reg & k_mask);
  assign bit_lower = ^(g_lower & conv_shift_reg & k_mask);
  assign bit_tdata = {bit_upper,bit_lower};

  axi_fifo_flop2 #(.WIDTH(2)) axi_fifo_flop_conv_encoder (
    .clk(ce_clk), .reset(ce_rst | user_reset), .clear(1'b0),
    .i_tdata(bit_tdata),     .i_tvalid(bit_tvalid),     .i_tready(bit_tready),
    .o_tdata(bit_reg_tdata), .o_tvalid(bit_reg_tvalid), .o_tready(bit_reg_tready),
    .space(), .occupied());

  wire serialized_tdata, serialized_tvalid, serialized_tready;

  axi_serializer #(.WIDTH(2)) axi_serializer (
    .clk(ce_clk), .rst(ce_rst | user_reset), .reverse_input(1'b0),
    .i_tdata(bit_reg_tdata), .i_tlast(1'b0), .i_tvalid(bit_reg_tvalid), .i_tready(bit_reg_tready),
    .o_tdata(serialized_tdata), .o_tlast(), .o_tvalid(serialized_tvalid), .o_tready(serialized_tready));

  // Puncture
  wire punctured_tdata, punctured_tvalid, punctured_tready;
  reg  [$clog2(P_WIDTH):0] puncture_index;

  generate
    if ((FIXED_PUNCTURE_CODE_RATE == 0) && (MAX_PUNCTURE_CODE_RATE == 0)) begin
      assign punctured_tdata = serialized_tdata;
      assign punctured_tvalid = serialized_tvalid;
      assign serialized_tready = punctured_tready;
    end else begin
      always @(posedge ce_clk) begin
        if (ce_rst | user_reset) begin
          puncture_index     <= FIXED_PUNCTURE_CODE_RATE == 0 ? 'd0 : (code_rate << 1) - 1;
        end else begin
          if (serialized_tready & serialized_tvalid) begin
            if (puncture_index == 0) begin
              puncture_index <= (code_rate << 1) - 1;
            end else begin
              puncture_index <= puncture_index - 1;
            end
          end else if (code_rate_stb) begin
            puncture_index   <= (code_rate << 1) - 1;
          end
        end
      end

      wire puncture = puncture_vector[puncture_index];

      axi_fifo_flop #(.WIDTH(1)) axi_fifo_flop_punctured (
        .clk(ce_clk), .reset(ce_rst | user_reset), .clear(1'b0),
        .i_tdata(serialized_tdata), .i_tvalid(serialized_tvalid & puncture), .i_tready(serialized_tready),
        .o_tdata(punctured_tdata),  .o_tvalid(punctured_tvalid),             .o_tready(punctured_tready),
        .space(), .occupied());
    end
  endgenerate

  // Symbol Mapper
  wire [1:0] symbol_tdata;
  wire symbol_tvalid, symbol_tvalid_dly, symbol_tready;
  wire [31:0] sample, sample_tdata;
  wire sample_tvalid, sample_tready;

  axi_deserializer #(.WIDTH(2)) axi_deserializer (
    .clk(ce_clk), .rst(ce_rst | user_reset), .reverse_output(swap_iq),
    .i_tdata(punctured_tdata), .i_tlast(1'b0), .i_tvalid(punctured_tvalid), .i_tready(punctured_tready),
    .o_tdata(symbol_tdata), .o_tlast(), .o_tvalid(symbol_tvalid), .o_tready(symbol_tready));

  // Lookup table mapping bits / words to symbols
  ram_2port #(
    .DWIDTH(32),
    .AWIDTH(MAX_BITS_PER_SYMBOL))
  symbol_mapper_ram (
    .clka(ce_clk), .ena(1'b1), .wea(symbol_lut_wr_data_stb),
    .addra(symbol_lut_wr_addr), .dia(symbol_lut_wr_data), .doa(),
    .clkb(ce_clk), .enb(sample_tready & symbol_tvalid), .web(1'b0),
    .addrb(symbol_tdata), .dib(), .dob(sample));

  axi_fifo_flop2 #(.WIDTH(1)) axi_fifo_flop_delay_tvalid (
    .clk(ce_clk), .reset(ce_rst | user_reset), .clear(1'b0),
    .i_tdata(1'b0), .i_tvalid(symbol_tvalid),     .i_tready(),
    .o_tdata(),     .o_tvalid(symbol_tvalid_dly), .o_tready(symbol_tready),
    .space(), .occupied());

  axi_fifo_flop2 #(.WIDTH(32)) axi_fifo_flop_sample (
    .clk(ce_clk), .reset(ce_rst | user_reset), .clear(1'b0),
    .i_tdata(sample), .i_tvalid(symbol_tvalid_dly), .i_tready(symbol_tready),
    .o_tdata(sample_tdata),  .o_tvalid(sample_tvalid),    .o_tready(sample_tready),
    .space(), .occupied());

  assign s_axis_data_tdata = sample_tdata;
  assign s_axis_data_tvalid = sample_tvalid;
  assign s_axis_data_tlast = 1'b0;
  assign sample_tready = s_axis_data_tready;

endmodule
