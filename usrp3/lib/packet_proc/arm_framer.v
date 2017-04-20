//
// Copyright 2017 Ettus Research
//

module arm_framer (

  input             clk,
  input             reset,
  input             clear,
  input  [63:0]     s_axis_tdata,
  input  [3:0]      s_axis_tuser,
  input             s_axis_tlast,
  input             s_axis_tvalid,
  output reg        s_axis_tready,
  output reg [63:0] m_axis_tdata,
  output reg  [3:0] m_axis_tuser,
  output reg        m_axis_tlast,
  output reg        m_axis_tvalid,
  input             m_axis_tready
);

  localparam START  = 2'b00;
  localparam IN_PKT = 2'b01;
  localparam EXTRA  = 2'b10;

  reg  [63:0] s_axis_tdata_reg;
  reg  [3:0]  s_axis_tuser_reg;
  reg         s_axis_tvalid_reg;
  reg         s_axis_tlast_reg;

  wire        new_line;
  reg  [1:0]  state;
  reg  [47:0] holding_reg;
  reg  [2:0]  holding_user;

  assign new_line = (s_axis_tuser_reg[2:0] > 3'b010) || (s_axis_tuser_reg[2:0] == 3'b000);
  assign valid_beat = s_axis_tvalid_reg & m_axis_tready;

  always @(posedge clk) begin
    if (reset | clear) begin
      s_axis_tdata_reg  <= 64'b0;
      s_axis_tvalid_reg <= 1'b0;
      s_axis_tlast_reg  <= 1'b0;
      s_axis_tuser_reg  <= 3'b0;
    end else begin
      s_axis_tdata_reg  <= s_axis_tdata;
      s_axis_tvalid_reg <= (m_axis_tready & (state == START))? 1'b0: s_axis_tvalid;
      s_axis_tlast_reg  <= s_axis_tlast;
      s_axis_tuser_reg  <= s_axis_tuser;
    end
  end

  // States
  always @(posedge clk) begin
    if (reset | clear) begin
      state <= 2'b0;
      holding_reg <= 16'b0;
      holding_user <= 3'b000;
    end else
      case (state)
        START :
          if (valid_beat) begin
            state <= IN_PKT;
            holding_reg  <= s_axis_tdata_reg[47:0];
            holding_user <= s_axis_tuser_reg[2:0];
        end

        IN_PKT : begin
          if (valid_beat & s_axis_tready) begin
            holding_reg  <= s_axis_tdata_reg[47:0];
            holding_user <= s_axis_tuser_reg[2:0];
          end
          if (valid_beat & s_axis_tlast_reg)
            state  <=  new_line ? EXTRA : START;
        end

        EXTRA : begin
          holding_reg <= 16'b0;
          holding_user <= 3'b000;
          if (m_axis_tready)
            state  <= START;
        end

        default   :
          state  <= START;
      endcase
  end

  // Outputs
  always @(*) begin
      m_axis_tdata  = 64'b0;
      m_axis_tvalid = 1'b0;
      m_axis_tlast  = 1'b0;
      m_axis_tuser  = 3'b0;
      s_axis_tready = 1'b1;

      case (state)
        START : begin
            m_axis_tdata  = {48'b0, s_axis_tdata_reg[63:48]};
            m_axis_tvalid = s_axis_tvalid_reg;
            m_axis_tlast  = s_axis_tlast_reg;
            m_axis_tuser  = 4'b0;
            s_axis_tready = m_axis_tready;
        end

        IN_PKT : begin
            m_axis_tdata  = {holding_reg, s_axis_tdata_reg[63:48]};
            m_axis_tvalid = s_axis_tvalid_reg;
            m_axis_tlast  = ~new_line ? s_axis_tlast_reg : 1'b0;
            m_axis_tuser  = (~new_line & s_axis_tlast_reg) ? (4'b0111 & {1'b0, s_axis_tuser_reg[2:0] + 3'b110}) : 4'b0;
            s_axis_tready = m_axis_tready;
          end

        EXTRA : begin
            m_axis_tdata  = {holding_reg, 16'b0};
            m_axis_tvalid = 1'b1;
            m_axis_tlast  = 1'b1;
            m_axis_tuser  = {1'b0, holding_user + 3'b110};
            s_axis_tready = 1'b0;
        end

      endcase
  end

endmodule
