//
// Copyright 2016 Ettus Research
//
// Decodes header word into individual CVITA packet header fields

module cvita_hdr_decoder (
  input [127:0] header,
  output [1:0] pkt_type, output eob, output has_time,
  output [11:0] seqnum, output [15:0] pkt_len, output [31:0] sid,
  output [63:0] vita_time
);

  wire [63:0] hdr[0:1];
  assign hdr[0] = header[127:64];
  assign hdr[1] = header[63:0];

  assign pkt_type  = hdr[0][63:62];
  assign has_time  = hdr[0][61];
  assign eob       = hdr[0][60];
  assign seqnum    = hdr[0][59:48];
  assign pkt_len   = hdr[0][47:32];
  assign sid       = hdr[0][31:0];
  assign vita_time = hdr[1];

endmodule