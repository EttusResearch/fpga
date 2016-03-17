//
// Copyright 2016 Ettus Research
//
// Encodes CVITA packet header fields into a header word

module cvita_hdr_encoder (
  input [1:0] pkt_type, input eob, input has_time,
  input [11:0] seqnum, input [15:0] pkt_len, input [31:0] sid,
  input [63:0] vita_time,
  output [127:0] header
);

  assign header = {pkt_type, has_time, eob, seqnum, pkt_len, sid, vita_time};

endmodule
