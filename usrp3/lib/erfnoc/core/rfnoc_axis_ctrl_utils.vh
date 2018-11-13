//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

// =============================================================
//  AXIS-Ctrl Bitfields
// =============================================================

// -----------------------
//  Line 0: HDR_0
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 31       has_time   Does the transaction have a timestamp?
// 30:29    <Reserved>
// 28:26    num_data   Number of data words
// 25:10    dst_epid   Endpoint ID of the destination of this msg
// 9:0      dst_port   Ctrl XB Port that the destination block is on 

// -----------------------
//  Line 1: HDR_1
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 31:26    seq_num    Sequence number
// 25:10    src_epid   Endpoint ID of the source of this msg
// 9:0      src_port   Ctrl XB Port that the source block is on 

// -----------------------
//  Line 2: TS_HI (Optional)
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 31:0     timestamp  Upper 32 bits of the timestamp

// -----------------------
//  Line 3: TS_LO (Optional)
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 31:0     timestamp  Lower 32 bits of the timestamp

// -----------------------
//  Line 4: OP Word
// -----------------------
// Bits     Name       Meaning
// ----     ----       -------
// 31       ack        Is this an acknoweledgment to a transaction?
// 30:29    status     The status of the ack
// 28       <Reserved>
// 27:24    opcode     Operation Code
// 23:20    byte_en    Byte enable strobe
// 19:0     address    Address for transaction

// AXIS-Ctrl Status
//
localparam [1:0] AXIS_CTRL_STS_OKAY    = 2'b00;
localparam [1:0] AXIS_CTRL_STS_CMDERR  = 2'b01;
localparam [1:0] AXIS_CTRL_STS_TSERR   = 2'b10;

// AXIS-Ctrl Opcode Definitions
//
localparam [3:0] AXIS_CTRL_OPCODE_SLEEP = 4'd0;
localparam [3:0] AXIS_CTRL_OPCODE_WRITE = 4'd1;
localparam [3:0] AXIS_CTRL_OPCODE_READ  = 4'd2;

// AXIS-Ctrl Getter Functions
//
function [0:0] axis_ctrl_get_has_time;
   input [31:0] header;
   axis_ctrl_has_time = header[31];
endfunction

function [2:0] axis_ctrl_get_num_data;
   input [31:0] header;
   axis_ctrl_get_num_data = header[28:26];
endfunction

function [15:0] axis_ctrl_get_epid;
   input [31:0] header;
   axis_ctrl_get_epid = header[25:10];
endfunction

function [9:0] axis_ctrl_get_port;
   input [31:0] header;
   axis_ctrl_get_port = header[9:0];
endfunction

function [0:0] axis_ctrl_get_ack;
   input [31:0] header;
   axis_ctrl_get_ack = header[31];
endfunction

function [1:0] axis_ctrl_get_status;
   input [31:0] header;
   axis_ctrl_get_status = header[30:29];
endfunction

function [3:0] axis_ctrl_get_opcode;
   input [31:0] header;
   axis_ctrl_get_opcode = header[27:24];
endfunction

function [3:0] axis_ctrl_get_byte_en;
   input [31:0] header;
   axis_ctrl_get_byte_en = header[23:20];
endfunction

function [19:0] axis_ctrl_get_address;
   input [31:0] header;
   axis_ctrl_get_address = header[19:0];
endfunction

// AXIS-Ctrl Setter Functions
//
function [31:0] axis_ctrl_build_hdr_0;
   input [0:0]  has_time;
   input [2:0]  num_data;
   input [15:0] dst_epid;
   input [9:0]  dst_port;
   axis_ctrl_build_hdr_0 = {has_time, 2'b00, num_data, dst_epid, dst_port};
endfunction

function [31:0] axis_ctrl_build_hdr_1;
   input [5:0]  seq_num;
   input [15:0] src_epid;
   input [9:0]  src_port;
   axis_ctrl_build_hdr_1 = {seq_num, src_epid, src_port};
endfunction

function [31:0] axis_ctrl_build_op_word;
   input [0:0]  ack;
   input [1:0]  status;
   input [3:0]  opcode;
   input [3:0]  byte_en;
   input [19:0] address;
   axis_ctrl_build_op_word = {ack, status, 1'b0, opcode, byte_en, address};
endfunction
