//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: PkgStreamEndpointBfm
//
// Description: This package includes high-level bus functional models (BFMs)
// for communicating with RFNoC. This includes the following:
//
//   - ChdrStreamBfm: Model for the AXIS CHDR interface of a Transport Adapter
//                    or Stream Endpoint.
//
//   - CtrlStreamBfm: Model for the AXIS CTRL interface of a Stream Endpoint.
//
//   - ChdrEndpointBfm: Model for a Stream Endpoint, which includes both a
//                      ChdrStreamBfm and a CtrlStreamBfm.
//



//-----------------------------------------------------------------------------
// AXI-Stream BFM Package
//-----------------------------------------------------------------------------

package PkgStreamEndpointBfm;

  import PkgChdrUtils::*;
  import PkgChdrBfm::*;
  import PkgAxisCtrlBfm::*;


  //---------------------------------------------------------------------------
  // Block Context
  //---------------------------------------------------------------------------
  //
  // This class contains the information necessary to communicate with an RFNoC 
  // block's data and control interfaces. A BlockContext object should be 
  // created and then referenced when sending a packet to a NoC block.
  //
  //---------------------------------------------------------------------------

  class BlockContext;

    // Class constructor to create a new block controller instance.
    //
    //   dst_port:  Destination port to which the block's control interface is
    //              connected.
    //   dst_epid:  Destination endpoint ID for the endpoint that the block is
    //              connected to.
    //
    function new(ctrl_port_t dst_port, chdr_epid_t dst_epid = 0);
      this.dst_epid = dst_epid;
      this.dst_port = dst_port;
    endfunction : new

    // Data plane properties
    chdr_seq_num_t seq_num[chdr_pkt_type_t] = '{ default: 0 };
    chdr_epid_t    dst_epid;

    // Control plane properties
    ctrl_port_t dst_port;

  endclass : BlockContext



  //---------------------------------------------------------------------------
  // CHDR Stream BFM
  //---------------------------------------------------------------------------
  //
  // This class models an AXIS CHDR interface, such as that on a Transport
  // Adapter or in a Stream Endpoint.
  //
  //---------------------------------------------------------------------------

  class ChdrStreamBfm #(CHDR_W = 64) extends ChdrBfm #(CHDR_W);
    chdr_epid_t src_epid;
    ctrl_port_t src_port;

    // Class constructor to create a new BFM instance.
    //
    //   m_chdr:    Interface for the master connection (BFM's CHDR output)
    //   s_chdr:    Interface for the slave connection (BFM's CHDR input)
    //   src_epid:  Source endpoint ID to use in generated CHDR packets
    //   src_port:  Source port to use in generated CHDR control packets
    //
    function new(
      virtual AxiStreamIf #(CHDR_W).master m_chdr,
      virtual AxiStreamIf #(CHDR_W).slave  s_chdr,
      chdr_epid_t src_epid,
      ctrl_port_t src_port
    );
      super.new(m_chdr, s_chdr);
      this.src_epid = src_epid;
      this.src_port = src_port;
    endfunction : new


    // Send a CHDR control packet with a read request and get the response.
    //
    //   block:  Handle to the block controller object
    //   addr:   Address for the read request
    //   word:   Data word that was returned in response to the read
    //
    task reg_read (
        input  BlockContext   block,
        input  ctrl_address_t addr,
        output ctrl_word_t    word
    );
      ChdrPacket         chdr_packet;
      chdr_header_t      chdr_header;
      chdr_ctrl_header_t ctrl_header;
      ctrl_op_word_t     ctrl_op_word;
      ctrl_word_t        ctrl_data[$];
      chdr_word_t        ctrl_timestamp;

      // Create the control payload
      ctrl_header = '{
        src_epid : src_epid,
        seq_num  : block.seq_num[CHDR_CONTROL],
        num_data : 1,
        src_port : src_port,
        dst_port : block.dst_port,
        default  : 0
      };
      ctrl_op_word = '{
        op_code     : CTRL_OP_READ,
        byte_enable : ~0,
        address     : addr,
        default     : 0
      };
      ctrl_data = { 0 };

      // Create the CHDR packet
      chdr_packet = new();
      chdr_header = '{
        seq_num  : block.seq_num[CHDR_CONTROL],
        pkt_type : CHDR_CONTROL,
        dst_epid : block.dst_epid,
        default  : 0
      };
      chdr_packet.write_ctrl(chdr_header, ctrl_header, ctrl_op_word, ctrl_data);

      block.seq_num[CHDR_CONTROL]++;

      // Send the CHDR control packet and get the response
      put_chdr(chdr_packet);
      get_chdr(chdr_packet);
      chdr_packet.read_ctrl(chdr_header, ctrl_header, ctrl_op_word, ctrl_data, ctrl_timestamp);
      word = ctrl_data[0];

      assert(chdr_header.pkt_type == CHDR_CONTROL &&
             ctrl_header.is_ack == 1 &&
             ctrl_op_word.status == CTRL_STS_OKAY) else begin
        $error("ChdrStreamBfm::reg_read: Did not receive CTRL_STS_OKAY status");
      end
    endtask : reg_read


    // Send a CHDR control packet with a write request and get the response.
    //
    //   block:  Handle to the block controller object
    //   addr:   Address for the write request
    //   word:   Data word for the write request
    //
    task reg_write (
      BlockContext   block,
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      ChdrPacket         chdr_packet;
      chdr_header_t      chdr_header;
      chdr_ctrl_header_t ctrl_header;
      ctrl_op_word_t     ctrl_op_word;
      ctrl_word_t        ctrl_data[$];
      chdr_word_t        ctrl_timestamp;

      // Create the control payload
      ctrl_header = '{
        src_epid : src_epid,
        seq_num  : block.seq_num[CHDR_CONTROL],
        num_data : 1,
        src_port : src_port,
        dst_port : block.dst_port,
        default  : 0
      };
      ctrl_op_word = '{
        op_code     : CTRL_OP_WRITE,
        byte_enable : ~0,
        address     : addr,
        default     : 0
      };
      ctrl_data = { word };

      // Create the CHDR packet
      chdr_packet = new();
      chdr_header = '{
        seq_num  : block.seq_num[CHDR_CONTROL],
        pkt_type : CHDR_CONTROL,
        dst_epid : dst_epid,
        default  : 0
      };

      block.seq_num[CHDR_CONTROL]++;

      // Send the CHDR control packet and get the response
      chdr_packet.write_ctrl(chdr_header, ctrl_header, ctrl_op_word, ctrl_data);
      put_chdr(chdr_packet);
      get_chdr(chdr_packet);
      chdr_packet.read_ctrl(chdr_header, ctrl_header, ctrl_op_word, ctrl_data, ctrl_timestamp);

      assert(ctrl_header.is_ack && ctrl_op_word.status == CTRL_STS_OKAY) else
        $error("ChdrStreamBfm::reg_write: Did not receive CTRL_STS_OKAY status");
    endtask : reg_write


    // Send a CHDR data packet.
    //
    //   block:      Handle to the block controller object.
    //   data:       Data words to insert into the CHDR packet.
    //   metadata:   Metadata words to insert into the CHDR packet. Omit this
    //               argument (or set to an empty array) to not include
    //               metadata.
    //   timestamp:  Timestamp to insert into the CHDR packet. Omit this
    //               argument (or set to an unknown value, as in X or Z) to not
    //               include a timestamp.
    //
    task send (
      BlockContext block,
      chdr_word_t  data[$],
      chdr_word_t  metadata[$] = {},
      chdr_word_t  timestamp = 'X
    );
      ChdrPacket      chdr_packet;
      chdr_header_t   chdr_header;
      chdr_pkt_type_t pkt_type;

      // Build packet
      pkt_type = $isunknown(timestamp) ? CHDR_DATA_NO_TS : CHDR_DATA_WITH_TS;
      chdr_packet = new();
      chdr_header = '{
        seq_num  : block.seq_num[pkt_type]++,
        pkt_type : pkt_type,
        dst_epid : dst_epid,
        default  : 0
      };
      chdr_packet.write_raw(chdr_header, data, metadata, timestamp);

      // Send the packet
      put_chdr(chdr_packet);
    endtask : send


    // Receive a CHDR data packet and extract its contents.
    //
    //   data:              Data words from the received CHDR packet.
    //   metadata:          Metadata words from the received CHDR packet. This
    //                      will be an empty array if there was no metadata.
    //   timestamp:         Timestamp from the received CHDR packet. If there
    //                      was no timestamp, then this will be X.
    //   data_byte_length:  The number of data bytes in the CHDR packet. This
    //                      is useful if the data is not a multiple of the
    //                      chdr_word_t size.
    //
    task recv_adv (
      output chdr_word_t data[$],
      output chdr_word_t metadata[$],
      output chdr_word_t timestamp,
      output int         data_byte_length
    );
      ChdrPacket chdr_packet;
      get_chdr(chdr_packet);

      data = chdr_packet.data;
      metadata = chdr_packet.metadata;
      if (chdr_packet.header.pkt_type == CHDR_DATA_WITH_TS)
        timestamp = chdr_packet.timestamp;
      else
        timestamp = 'X;
      data_byte_length = chdr_packet.data_bytes();
    endtask : recv_adv


    // Receive a CHDR data packet and extract the data. Any metadata or
    // timestamp, if present, are discarded.
    //
    //   data:  Data words from the received CHDR packet.
    //
    task recv(output chdr_word_t data[$]);
      ChdrPacket chdr_packet;
      get_chdr(chdr_packet);
      data = chdr_packet.data;
    endtask : recv


  endclass : ChdrStreamBfm



  //---------------------------------------------------------------------------
  // CTRL Stream BFM
  //---------------------------------------------------------------------------
  //
  // This class models an AXIS CTRL interface, such as that in a Stream
  // Endpoint.
  //
  //---------------------------------------------------------------------------

  class CtrlStreamBfm extends AxisCtrlBfm;
    chdr_epid_t src_epid;
    ctrl_port_t src_port;

    // Class constructor to create a new BFM instance.
    //
    //   m_chdr:    Interface for the master connection (BFM's AXIS output)
    //   s_chdr:    Interface for the slave connection (BFM's AXIS input)
    //   src_port:  Source port to use in generated control packets
    //
    function new(
      virtual AxiStreamIf #(32).master m_chdr,
      virtual AxiStreamIf #(32).slave  s_chdr,
      ctrl_port_t src_port
    );
      super.new(m_chdr, s_chdr);
      this.src_epid = src_epid;
      this.src_port = src_port;
    endfunction : new


    // Send an AXIS-Ctrl read request packet and get the response.
    //
    //   block:      Handle to the block controller object
    //   addr:       Address for the read request
    //   word:       Data word that was returned in response to the read
    //
    task reg_read (
        input  BlockContext   block,
        input  ctrl_address_t addr,
        output ctrl_word_t    word
    );
      AxisCtrlPacket ctrl_packet;

      // Create the AXIS-Ctrl packet
      ctrl_packet = new();
      ctrl_packet.header = '{
        seq_num  : block.seq_num[CHDR_CONTROL]++,
        num_data : 1,
        src_port : src_port,
        dst_port : block.dst_port,
        default  : 0
      };
      ctrl_packet.op_word = '{
        op_code     : CTRL_OP_READ,
        byte_enable : ~0,
        address     : addr,
        default     : 0
      };
      ctrl_packet.data = { 0 };

      // Send the control packet and get the response
      put_ctrl(ctrl_packet);
      get_ctrl(ctrl_packet);
      word = ctrl_packet.data[0];

      assert(ctrl_packet.header.is_ack == 1 &&
             ctrl_packet.op_word.status == CTRL_STS_OKAY) else begin
        $error("CtrlStreamBfm::reg_read: Did not receive CTRL_STS_OKAY status");
      end
    endtask : reg_read


    // Send an AXIS-Ctrl write request packet and get the response.
    //
    //   block:      Handle to the block controller object
    //   addr:       Address for the write request
    //   word:       Data word to write
    //
    task reg_write (
      BlockContext   block,
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      AxisCtrlPacket ctrl_packet;

      // Create the AXIS-Ctrl packet
      ctrl_packet = new();
      ctrl_packet.header = '{
        seq_num  : block.seq_num[CHDR_CONTROL]++,
        num_data : 1,
        src_port : src_port,
        dst_port : block.dst_port,
        default  : 0
      };
      ctrl_packet.op_word = '{
        op_code     : CTRL_OP_WRITE,
        byte_enable : ~0,
        address     : addr,
        default     : 0
      };

      // Send the packet and get the response
      ctrl_packet.data = { word };
      put_ctrl(ctrl_packet);
      get_ctrl(ctrl_packet);
      word = ctrl_packet.data[0];

      assert(ctrl_packet.header.is_ack == 1 &&
             ctrl_packet.op_word.status == CTRL_STS_OKAY) else begin
        $error("CtrlStreamBfm::reg_write: Did not receive CTRL_STS_OKAY status");
      end
    endtask : reg_write

  endclass : CtrlStreamBfm



  //---------------------------------------------------------------------------
  // Stream Endpoint BFM
  //---------------------------------------------------------------------------
  //
  // This class models a Stream Endpoint's AXIS CHDR and AXIS CTRL interfaces
  // for the purpose of simulating communication with RFNoC blocks.
  //
  //---------------------------------------------------------------------------

  class StreamEndpointBfm #(CHDR_W = 64);
    ChdrStreamBfm chdr;
    CtrlStreamBfm ctrl;

    // Class constructor to create a new BFM instance.
    //
    //   m_chdr:    Interface for the CHDR master connection (EP's AXIS CHDR data output)
    //   s_chdr:    Interface for the CHDR slave connection (EP's AXIS CHDR data input)
    //   m_ctrl:    Interface for the CTRL master connection (EP's AXIS-Ctrl output)
    //   s_ctrl:    Interface for the CTRL slave connection (EP's AXIS-Ctrl input)
    //   src_epid:  Source endpoint ID to use in generated CHDR packets
    //   src_port:  Source port to use in generated control packets
    //
    function new(
        virtual AxiStreamIf #(CHDR_W).master m_chdr,
        virtual AxiStreamIf #(CHDR_W).slave  s_chdr,
        virtual AxiStreamIf #(32).master     m_ctrl,
        virtual AxiStreamIf #(32).slave      s_ctrl,
        chdr_epid_t src_epid,
        ctrl_port_t src_port
    );
      chdr = new(m_chdr, s_chdr, src_epid, src_port);
      ctrl = new(m_ctrl, s_ctrl, src_port);
    endfunction : new


    // Start the data and control BFM's processes running.
    task run();
      chdr.run();
      ctrl.run();
    endtask : run


    // Send a CHDR data packet out the CHDR data interface.
    //
    //   block:      Handle to the block controller object.
    //   data:       Data words to insert into the CHDR packet.
    //   metadata:   Metadata words to insert into the CHDR packet. Omit this
    //               argument (or set to an empty array) to not include
    //               metadata.
    //   timestamp:  Timestamp to insert into the CHDR packet. Omit this
    //               argument (or set to an unknown value, as in X or Z) to not
    //               include a timestamp.
    //
    task send (
      BlockContext block,
      chdr_word_t  data[$],
      chdr_word_t  metadata[$] = {},
      chdr_word_t  timestamp = 'X
    );
      chdr.send(block, data, metadata, timestamp);
    endtask : send


    // Receive a CHDR data packet on the CHDR data interface and extract its
    // contents.
    //
    //   data:              Data words from the received CHDR packet.
    //   metadata:          Metadata words from the received CHDR packet. This
    //                      will be an empty array if there was no metadata.
    //   timestamp:         Timestamp from the received CHDR packet. If there
    //                      was no timestamp, then this will be X.
    //   data_byte_length:  The number of data bytes in the CHDR packet. This
    //                      is useful if the data is not a multiple of the
    //                      chdr_word_t size.
    //
    task recv_adv (
      output chdr_word_t data[$],
      output chdr_word_t metadata[$],
      output chdr_word_t timestamp,
      output int         data_byte_length
    );
      chdr.recv_adv(data, metadata, timestamp, data_byte_length);
    endtask : recv_adv


    // Receive a CHDR data packet on the CHDR data interface and extract the
    // data. Any metadata or timestamp, if present, are discarded.
    //
    //   data:  Data words from the received CHDR packet
    //
    task recv(output chdr_word_t data[$]);
      chdr.recv(data);
    endtask : recv


    // Send a read request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   block:  Handle to the block controller object
    //   addr:   Address for the read request
    //   word:   Data word that was returned in response to the read
    //
    task reg_read (
        input  BlockContext   block,
        input  ctrl_address_t addr,
        output ctrl_word_t    word
    );
      ctrl.reg_read(block, addr, word);
    endtask : reg_read


    // Send a a write request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   block:  Handle to the block controller object
    //   addr:   Address for the write request
    //   word:   Data word to write
    //
    task reg_write (
      BlockContext   block,
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      ctrl.reg_write(block, addr, word);
    endtask : reg_write

  endclass : StreamEndpointBfm


endpackage : PkgStreamEndpointBfm
