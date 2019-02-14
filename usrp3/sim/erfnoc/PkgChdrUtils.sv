//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: PkgChdrUtils
//
// Description: Various types, constants, and functions for interacting with 
// the RFNoC CHDR bus infrastructure.
//



package PkgChdrUtils;


  //---------------------------------------------------------------------------
  // Type Definitions
  //---------------------------------------------------------------------------

  // The fundamental unit of the CHDR bus, which is always a multiple of 64-bits
  typedef logic [63:0] chdr_word_t;

  // A word of the AXIS-Ctrl (control) bus, which is always 32 bits
  typedef logic [31:0] ctrl_word_t;

  // CHDR packet fields
  typedef bit [ 5:0] chdr_flags_t;    // CHDR Flags field
  typedef bit [ 2:0] chdr_pkt_type_t; // CHDR PktType field
  typedef bit [15:0] chdr_seq_num_t;  // CHDR SeqNum field
  typedef bit [15:0] chdr_epid_t;     // CHDR EPID field

  // AXIS-Ctrl packet fields
  typedef bit  [9:0] ctrl_seq_num_t;  // AXIS-Ctrl SeqNum field
  typedef bit  [3:0] ctrl_num_data_t; // AXIS-Ctrl NumData field
  typedef bit  [9:0] ctrl_port_t;     // AXIS-Ctrl source/destination port field
  typedef bit [15:0] ctrl_epid_t;     // AXIS-Ctrl EPID field
  typedef bit  [1:0] ctrl_status_t;   // AXIS-Ctrl Status field
  typedef bit  [3:0] ctrl_opcode_t;   // AXIS-Ctrl OpCode field
  typedef bit  [3:0] ctrl_byte_en_t;  // AXIS-Ctrl ByteEnable field
  typedef bit [19:0] ctrl_address_t;  // AXIS-Ctrl Address field

  // CHDR Status packet fields
  typedef bit [3:0] chdr_strs_status_t;  // CHDR stream status packet status field

  // CHDR Control packet fields
  typedef bit [3:0] chdr_strc_opcode_t;  // CHDR stream command packet opcode filed

  // CHDR Management packet field
  typedef bit [2:0] chdr_mgmt_width_t;   // CHDR management packet CHDR Width field
  typedef bit [7:0] chdr_mgmt_opcode_t;  // CHDR management packet OpCode field


  //---------------------------------------------------------------------------
  // Protocol Constants
  //---------------------------------------------------------------------------

  // CHDR packet PktType field values
  const chdr_pkt_type_t PKT_TYPE_MANAGEMENT          = 0;
  const chdr_pkt_type_t PKT_TYPE_STREAM_STATUS       = 1;
  const chdr_pkt_type_t PKT_TYPE_STREAM_COMMAND      = 2;
  const chdr_pkt_type_t PKT_TYPE_CONTROL_TRANSACTION = 4;
  const chdr_pkt_type_t PKT_TYPE_DATA_WO_TIMESTAMP   = 6;
  const chdr_pkt_type_t PKT_TYPE_DATA_WITH_TIMESTAMP = 7;

  // CHDR packet Flags field values
  const chdr_flags_t CHDR_FLAGS_NONE  = 6'b000000;
  const chdr_flags_t CHDR_FLAGS_EOV   = 6'b000001;
  const chdr_flags_t CHDR_FLAGS_EOB   = 6'b000010;
  const chdr_flags_t CHDR_FLAGS_USER0 = 6'b000100;
  const chdr_flags_t CHDR_FLAGS_USER1 = 6'b001000;
  const chdr_flags_t CHDR_FLAGS_USER2 = 6'b010000;
  const chdr_flags_t CHDR_FLAGS_USER3 = 6'b100000;

  // AXIS-Ctrl packet OpCode field values
  const ctrl_opcode_t CTRL_OPCODE_SLEEP = 0;
  const ctrl_opcode_t CTRL_OPCODE_WRITE = 1;
  const ctrl_opcode_t CTRL_OPCODE_READ  = 2;

  // AXIS-Ctrl packet Status field values
  const ctrl_status_t CTRL_STATUS_OKAY    = 0;
  const ctrl_status_t CTRL_STATUS_CMDERR  = 1;
  const ctrl_status_t CTRL_STATUS_TSERR   = 2;
  const ctrl_status_t CTRL_STATUS_WARNING = 3;

  // CHDR status packet Status field values
  const chdr_strs_status_t CHDR_STRS_STATUS_OKAY    = 0;
  const chdr_strs_status_t CHDR_STRS_STATUS_CMDERR  = 1;
  const chdr_strs_status_t CHDR_STRS_STATUS_SEQERR  = 2;
  const chdr_strs_status_t CHDR_STRS_STATUS_DATAERR = 3;
  const chdr_strs_status_t CHDR_STRS_STATUS_RTERR   = 4;

  // CHDR command packet OpCode field values
  const chdr_strc_opcode_t CHDR_STRC_OPCODE_INIT   = 0;
  const chdr_strc_opcode_t CHDR_STRC_OPCODE_PING   = 1;
  const chdr_strc_opcode_t CHDR_STRC_OPCODE_RESYNC = 2;

  // CHDR management packet Width field values
  const chdr_mgmt_width_t CHDR_MGMT_WIDTH_64  = 0;
  const chdr_mgmt_width_t CHDR_MGMT_WIDTH_128 = 1;
  const chdr_mgmt_width_t CHDR_MGMT_WIDTH_256 = 2;
  const chdr_mgmt_width_t CHDR_MGMT_WIDTH_512 = 3;

  // CHDR management packet OpCode field values
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_NOP         = 0;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_ADVERTISE   = 1;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_SEL_DEST    = 2;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_CFG_ROUTER  = 3;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_INFO_REQ    = 4;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_INFO_RESP   = 5;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_CFG_WR_REQ  = 6;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_CFG_RD_REQ  = 7;
  const chdr_mgmt_opcode_t CHDR_MGMT_OP_CFG_RD_RESP = 8;


  //---------------------------------------------------------------------------
  // Packet Data Structures
  //---------------------------------------------------------------------------

  // CHDR packet header
  typedef struct packed {
    bit [ 5:0] flags;
    bit [ 2:0] pkt_type;
    bit [ 6:0] num_mdata;
    bit [15:0] seq_num;
    bit [15:0] length;
    bit [15:0] dst_epid;
  } chdr_header_t;


  // AXIS-Ctrl packet header
  typedef struct packed {
    // Word 1
    bit [ 5:0] reserved_1;
    bit [ 9:0] rem_dst_port;
    bit [15:0] rem_dst_epid;
    // Word 0
    bit [ 0:0] is_ack;
    bit [ 0:0] has_time;
    bit [ 5:0] seq_num;
    bit [ 3:0] num_data;
    bit [ 9:0] src_port;
    bit [ 9:0] dst_port;
  } axis_ctrl_header_t;

  // AXIS-Ctrl packet header
  typedef struct packed {
    bit [ 1:0] status;
    bit [ 1:0] reserved_0;
    bit [ 3:0] op_code;
    bit [ 3:0] byte_enable;
    bit [19:0] address;
  } ctrl_op_word_t;

  // Ctrl packet header when in the payload of a CHDR packet
  typedef struct packed {
    bit [15:0] reserved_0;
    bit [15:0] src_epid;
    bit [ 0:0] is_ack;
    bit [ 0:0] has_time;
    bit [ 5:0] seq_num;
    bit [ 3:0] num_data;
    bit [ 9:0] src_port;
    bit [ 9:0] dst_port;
  } chdr_ctrl_header_t;


  // CHDR stream status packet payload
  typedef struct packed {
    // Word 3
    bit [47:0] status_info;
    bit [15:0] buff_info;
    // Word 2
    bit [63:0] xfer_count_bytes;
    // Word 1
    bit [39:0] xfer_count_pkts;
    bit [23:0] capacity_pkts;
    // Word 0
    bit [39:0] capacity_bytes;
    bit [ 3:0] reserved;
    bit [ 3:0] status;
    bit [15:0] src_epid;
  } chdr_str_status_t;


  // CHDR stream command packet payload
  typedef struct packed {
    // Word 1
    bit [63:0] num_bytes;
    // Word 0
    bit [39:0] num_pkts;
    bit [ 3:0] op_data;
    bit [ 3:0] op_code;
    bit [15:0] src_epid;
  } chdr_str_command_t;


  // CHDR management packet header
  typedef struct packed {
    bit [15:0] prot_ver;
    bit [ 2:0] chdr_width;
    bit [18:0] reserved;
    bit [ 9:0] num_hops;
    bit [15:0] src_epid;
  } chdr_mgmt_header_t;


  // CHDR management packet operation
  typedef struct packed {
    bit [47:0] op_payload;
    bit [ 7:0] op_code;
    bit [ 7:0] ops_pending;
  } chdr_mgmt_op_t;


  // CHDR management packet
  typedef struct {
    chdr_mgmt_header_t header;
    chdr_mgmt_op_t     ops[$];
  } chdr_mgmt_t;



  //---------------------------------------------------------------------------
  // Functions
  //---------------------------------------------------------------------------

  // Returns 1 if the queues have the same contents, otherwise returns 0. This 
  // function is equivalent to (a == b), but this doesn't work correctly yet in 
  // Vivado 2018.3.
  function automatic bit chdr_word_queues_equal(ref chdr_word_t a[$], ref chdr_word_t b[$]);
    chdr_word_t x, y;
    if (a.size() != b.size()) return 0;
    foreach (a[i]) begin
      x = a[i];
      y = b[i];
      if (x != y) return 0;
    end
    return 1;
  endfunction : chdr_word_queues_equal


  // Returns 1 if the queues have the same contents, otherwise returns 0. This 
  // function is equivalent to (a == b), but this doesn't work correctly yet in 
  // Vivado 2018.3.
  function automatic bit chdr_mgmt_op_queues_equal(ref chdr_mgmt_op_t a[$], ref chdr_mgmt_op_t b[$]);
    chdr_mgmt_op_t x, y;
    if (a.size() != b.size()) return 0;
    foreach (a[i]) begin
      x = a[i];
      y = b[i];
      if (x != y) return 0;
    end
    return 1;
  endfunction : chdr_mgmt_op_queues_equal


endpackage : PkgChdrUtils
