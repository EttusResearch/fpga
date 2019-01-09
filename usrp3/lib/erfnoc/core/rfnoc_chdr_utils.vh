//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

// =============================================================
//  CHDR Bitfields
// =============================================================
//
// The Condensed Hierarchical Datagram for RFNoC (CHDR) is 
// a protocol that defines the fundamental unit of data transfer
// in an RFNoC network. 
// 
// -----------------------
//  Header
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 63:58    flags      Flags (bitfield)
// 57:55    pkt_type   Packet Type (enumeration)
// 54:48    num_mdata  Number of lines of metadata
// 47:32    seq_num    Sequence number for the packet
// 31:16    length     Length of the datagram in bytes
// 15:0     dst_epid   Destination Endpoint ID
// 
// 
// Packet Type
// -----------------------
// 3'd0     Management
// 3'd1     Stream Status
// 3'd2     Stream Command
// 3'd3     <Reserved>
// 3'd4     Control Transaction
// 3'd5     <Reserved>
// 3'd6     Data (without timestamp)
// 3'd7     Data (with timestamp)
//
// Flags
// -----------------------
// flags[0] EOV (End of Vector)
// flags[1] EOB (End of Burst)
// flags[2] User Defined
// flags[3] User Defined
// flags[4] User Defined
// flags[5] User Defined
// 

// CHDR Packet Types
//
localparam [2:0] CHDR_PKT_TYPE_MGMT    = 3'd0;
localparam [2:0] CHDR_PKT_TYPE_STRS    = 3'd1;
localparam [2:0] CHDR_PKT_TYPE_STRC    = 3'd2;
//localparam [2:0] RESERVED            = 3'd3;
localparam [2:0] CHDR_PKT_TYPE_CTRL    = 3'd4;
//localparam [2:0] RESERVED            = 3'd5;
localparam [2:0] CHDR_PKT_TYPE_DATA    = 3'd6;
localparam [2:0] CHDR_PKT_TYPE_DATA_TS = 3'd7;

// Flags
//
localparam [5:0] CHDR_FLAGS_NONE  = 6'b000000;
localparam [5:0] CHDR_FLAGS_EOV   = 6'b000001;
localparam [5:0] CHDR_FLAGS_EOB   = 6'b000010;
localparam [5:0] CHDR_FLAGS_USER0 = 6'b000100;
localparam [5:0] CHDR_FLAGS_USER1 = 6'b001000;
localparam [5:0] CHDR_FLAGS_USER2 = 6'b010000;
localparam [5:0] CHDR_FLAGS_USER3 = 6'b100000;

// CHDR Getter Functions
//
function [5:0] chdr_get_flags(input [63:0] header);
  chdr_get_flags = header[63:58];
endfunction

function [2:0] chdr_get_pkt_type(input [63:0] header);
  chdr_get_pkt_type = header[57:55];
endfunction

function [6:0] chdr_get_num_mdata(input [63:0] header);
  chdr_get_num_mdata = header[54:48];
endfunction

function [15:0] chdr_get_seq_num(input [63:0] header);
  chdr_get_seq_num = header[47:32];
endfunction

function [15:0] chdr_get_length(input [63:0] header);
  chdr_get_length = header[31:16];
endfunction

function [15:0] chdr_get_dst_epid(input [63:0] header);
  chdr_get_dst_epid = header[15:0];
endfunction

// CHDR Setter Functions
//
function [63:0] chdr_build_header(
  input [5:0]  flags,
  input [2:0]  pkt_type,
  input [6:0]  num_mdata,
  input [15:0] seq_num,
  input [15:0] length,
  input [15:0] dst_epid
);
  chdr_build_header = {flags, pkt_type, num_mdata, seq_num, length, dst_epid};
endfunction

function [63:0] chdr_set_flags(
  input [63:0] base_hdr,
  input [5:0]  flags
);
  chdr_set_flags = {flags, base_hdr[57:0]};
endfunction

function [63:0] chdr_set_pkt_type(
  input [63:0] base_hdr,
  input [2:0]  pkt_type
);
  chdr_set_pkt_type = {base_hdr[63:58], pkt_type, base_hdr[54:0]};
endfunction

function [63:0] chdr_set_num_mdata(
  input [63:0] base_hdr,
  input [6:0]  num_mdata
);
  chdr_set_num_mdata = {base_hdr[63:55], num_mdata, base_hdr[47:0]};
endfunction

function [63:0] chdr_set_seq_num(
  input [63:0] base_hdr,
  input [15:0] seq_num
);
  chdr_set_seq_num = {base_hdr[63:48], seq_num, base_hdr[31:0]};
endfunction

function [63:0] chdr_set_length(
  input [63:0] base_hdr,
  input [15:0] length
);
  chdr_set_length = {base_hdr[63:32], length, base_hdr[15:0]};
endfunction

function [63:0] chdr_set_dst_epid(
  input [63:0] base_hdr,
  input [15:0] dst_epid
);
  chdr_set_dst_epid = {base_hdr[63:16], dst_epid};
endfunction

// =============================================================
//  Data Packet Specific
// =============================================================

localparam [3:0] CONTEXT_FIELD_HDR    = 4'd0;
localparam [3:0] CONTEXT_FIELD_HDR_TS = 4'd1;
localparam [3:0] CONTEXT_FIELD_TS     = 4'd2;
localparam [3:0] CONTEXT_FIELD_MDATA  = 4'd3;

function [0:0] chdr_get_has_time(input [63:0] header);
  chdr_get_has_time = (chdr_get_pkt_type(header) == CHDR_PKT_TYPE_DATA_TS);
endfunction

