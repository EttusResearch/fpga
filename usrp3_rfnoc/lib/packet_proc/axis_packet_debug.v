//
// Copyright 2014 Ettus Research LLC
//

module axis_packet_debug
  #(
    parameter EXPECTED_SID = 32'h0000_0050
    )
  (
   input          clk,
   input          reset,
   input          clear,

   //Packet In
   input [63:0]   tdata,
   input          tlast,
   input          tvalid,
   input          tready,

   //Per packet info
   output reg           pkt_strobe,
   output reg [15:0]    length,
   output reg [63:0]    checksum,
   output reg           bad_sid,
   //Statistics
   output reg [31:0]    pkt_count
);

   localparam ST_HEADER = 1'b0;
   localparam ST_DATA   = 1'b1;

   //Packet state logic
   reg   pkt_state;
   always @(posedge clk) begin
      if (reset) begin
         pkt_state <= ST_HEADER;
      end else if (tvalid & tready) begin
         pkt_state <= tlast ? ST_HEADER : ST_DATA;
      end
   end

   //Trigger logic
   always @(posedge clk)
      if (reset)
         pkt_strobe <= 1'b0;
      else
         pkt_strobe <= tvalid && tready && tlast;

   //Length capture
   always @(posedge clk)
      if (reset || (tvalid && tready && tlast))
         length <= 16'd0;
      else
         if (tvalid & tready)
            length <= length + 16'd8;

   //Checksum capture
   always @(posedge clk)
      if (reset || (tvalid && tready && tlast) )
         checksum <= 64'd0;
      else
         if (tvalid & tready)
            checksum <= checksum ^ tdata;

   //Counts
   always @(posedge clk)
      if (reset | clear) begin
         pkt_count <= 32'd0;
      end else begin
         if (tvalid && tready && tlast) begin
            pkt_count <= pkt_count + 32'd1;
         end
      end

   // Check for unexpected SID
   always @(posedge clk)
      if (reset | clear) begin
	 bad_sid <= 1'b0;
      end else if ((pkt_state == ST_HEADER) && tvalid && tready ) begin
	 bad_sid <= tdata[31:0] != EXPECTED_SID;
      end else begin
	 bad_sid <= 1'b0;
      end

endmodule // cvita_packet_debug
