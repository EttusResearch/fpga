//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: PkgRfnocBlockCtrlBfm
//
// Description: This package includes high-level bus functional models (BFMs)
// for communicating with RFNoC. This includes the following:
//
//   - ChdrDataStreamBfm: Model for the AXIS CHDR interface of a Transport Adapter
//                    or Stream Endpoint.
//
//   - RegisterIfaceBfm: Model for the AXIS CTRL interface of a Stream Endpoint.
//
//   - RfnocBlockCtrlBfm: Model for a software block controller, which includes both a
//                      ChdrDataStreamBfm and a RegisterIfaceBfm.
//


//-----------------------------------------------------------------------------
// SV Interface for the RFNoC Backend Iface
//-----------------------------------------------------------------------------

typedef struct packed {
  bit [476:0] reserved0;
  bit         soft_chdr_rst;
  bit         soft_ctrl_rst;
  bit         flush_en;
  bit [31:0]  flush_timeout;
} backend_config_t;

typedef struct packed {
  bit [453:0] reserved0;
  bit         flush_done;
  bit         flush_active;
  bit [5:0]   mtu;
  bit [5:0]   ctrl_fifosize;
  bit [5:0]   num_data_o;
  bit [5:0]   num_data_i;
  bit [31:0]  noc_id;
} backend_status_t;

interface RfnocBackendIf(
  input wire logic chdr_clk,
  input wire logic ctrl_clk
);
  logic            chdr_rst;
  logic            ctrl_rst;
  backend_config_t cfg;
  backend_status_t sts;

  modport master (
    input  chdr_clk,
    input  ctrl_clk,
    output chdr_rst,
    output ctrl_rst,
    output cfg,
    input  sts
  );
  modport slave (
    input  chdr_clk,
    input  ctrl_clk,
    input  chdr_rst,
    input  ctrl_rst,
    input  cfg,
    output sts
  );
endinterface : RfnocBackendIf

//-----------------------------------------------------------------------------
// RFNoC Block Controller Bus Functional Model
//-----------------------------------------------------------------------------

package PkgRfnocBlockCtrlBfm;

  import PkgChdrUtils::*;
  import PkgChdrBfm::*;
  import PkgAxisCtrlBfm::*;

  //---------------------------------------------------------------------------
  // CHDR Stream BFM
  //---------------------------------------------------------------------------
  //
  // This class models an AXIS CHDR interface, such as that on a Transport
  // Adapter or in a Stream Endpoint.
  //
  //---------------------------------------------------------------------------

  class ChdrDataStreamBfm #(CHDR_W = 64) extends ChdrBfm #(CHDR_W);
    chdr_seq_num_t seq_num;

    // Class constructor to create a new BFM instance.
    //
    //   m_chdr:    Interface for the master connection (BFM's CHDR output)
    //   s_chdr:    Interface for the slave connection (BFM's CHDR input)
    //
    function new(
      virtual AxiStreamIf #(CHDR_W).master m_chdr,
      virtual AxiStreamIf #(CHDR_W).slave  s_chdr
    );
      super.new(m_chdr, s_chdr);
      this.seq_num  = '0;
    endfunction : new

    // Send a CHDR data packet.
    //
    //   data:       Data words to insert into the CHDR packet.
    //   metadata:   Metadata words to insert into the CHDR packet. Omit this
    //               argument (or set to an empty array) to not include
    //               metadata.
    //   timestamp:  Timestamp to insert into the CHDR packet. Omit this
    //               argument (or set to an unknown value, as in X or Z) to not
    //               include a timestamp.
    //
    task send (
      input chdr_word_t data[$],
      input int         data_bytes = -1,
      input chdr_word_t metadata[$] = {},
      input chdr_word_t timestamp = 'X
    );
      ChdrPacket      chdr_packet;
      chdr_header_t   chdr_header;
      chdr_pkt_type_t pkt_type;

      // Build packet
      pkt_type = $isunknown(timestamp) ? CHDR_DATA_NO_TS : CHDR_DATA_WITH_TS;
      chdr_packet = new();
      chdr_header = '{
        seq_num  : seq_num++,
        pkt_type : pkt_type,
        dst_epid : dst_epid,
        default  : 0
      };
      chdr_packet.write_raw(chdr_header, data, metadata, timestamp, data_bytes);

      // Send the packet
      put_chdr(chdr_packet);
    endtask : send


    // Receive a CHDR data packet and extract its contents.
    //
    //   data:        Data words from the received CHDR packet.
    //   data_bytes:  The number of data bytes in the CHDR packet. This
    //                is useful if the data is not a multiple of the
    //                chdr_word_t size.
    //   metadata:    Metadata words from the received CHDR packet. This
    //                will be an empty array if there was no metadata.
    //   timestamp:   Timestamp from the received CHDR packet. If there
    //                was no timestamp, then this will be X.
    //
    task recv_adv (
      output chdr_word_t data[$],
      output int         data_bytes,
      output chdr_word_t metadata[$],
      output chdr_word_t timestamp
    );
      ChdrPacket chdr_packet;
      get_chdr(chdr_packet);

      data = chdr_packet.data;
      metadata = chdr_packet.metadata;
      if (chdr_packet.header.pkt_type == CHDR_DATA_WITH_TS)
        timestamp = chdr_packet.timestamp;
      else
        timestamp = 'X;
      data_bytes = chdr_packet.data_bytes();
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

  endclass : ChdrDataStreamBfm



  //---------------------------------------------------------------------------
  // CTRL Stream BFM
  //---------------------------------------------------------------------------
  //
  // This class models an AXIS CTRL interface, such as that in a Stream
  // Endpoint.
  //
  //---------------------------------------------------------------------------

  class RegisterIfaceBfm extends AxisCtrlBfm;
    ctrl_port_t    dst_port;
    ctrl_port_t    src_port;
    ctrl_seq_num_t seq_num;

    // Class constructor to create a new BFM instance.
    //
    //   m_chdr:    Interface for the master connection (BFM's AXIS output)
    //   s_chdr:    Interface for the slave connection (BFM's AXIS input)
    //   src_port:  Source port to use in generated control packets
    //
    function new(
      virtual AxiStreamIf #(32).master m_chdr,
      virtual AxiStreamIf #(32).slave  s_chdr,
      ctrl_port_t dst_port,
      ctrl_port_t src_port
    );
      super.new(m_chdr, s_chdr);
      this.dst_port = dst_port;
      this.src_port = src_port;
      this.seq_num  = '0;
    endfunction : new


    // Send an AXIS-Ctrl read request packet and get the response.
    //
    //   addr:       Address for the read request
    //   word:       Data word that was returned in response to the read
    //
    task reg_read (
      input  ctrl_address_t addr,
      output ctrl_word_t    word
    );
      AxisCtrlPacket ctrl_packet;

      // Create the AXIS-Ctrl packet
      ctrl_packet = new();
      ctrl_packet.header = '{
        seq_num  : seq_num++,
        num_data : 1,
        src_port : src_port,
        dst_port : dst_port,
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
        $error("RegisterIfaceBfm::reg_read: Did not receive CTRL_STS_OKAY status");
      end
    endtask : reg_read


    // Send an AXIS-Ctrl write request packet and get the response.
    //
    //   addr:       Address for the write request
    //   word:       Data word to write
    //
    task reg_write (
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      AxisCtrlPacket ctrl_packet;

      // Create the AXIS-Ctrl packet
      ctrl_packet = new();
      ctrl_packet.header = '{
        seq_num  : seq_num++,
        num_data : 1,
        src_port : src_port,
        dst_port : dst_port,
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
        $error("RegisterIfaceBfm::reg_write: Did not receive CTRL_STS_OKAY status");
      end
    endtask : reg_write

  endclass : RegisterIfaceBfm


  //---------------------------------------------------------------------------
  // Block Controller BFM
  //---------------------------------------------------------------------------
  //
  // This class models a block controller in software
  //
  //---------------------------------------------------------------------------

  class RfnocBlockCtrlBfm #(CHDR_W = 64, NUM_PORTS = 1);
    localparam CMD_PROP_CYC = 5;

    local ChdrDataStreamBfm             chdr[0:NUM_PORTS-1];
    local RegisterIfaceBfm              ctrl;
    local virtual RfnocBackendIf.master bkend;

    // Class constructor to create a new BFM instance.
    //
    //   src_port:  Source port to use in generated control packets
    //   m_ctrl:    Interface for the CTRL master connection (EP's AXIS-Ctrl output)
    //   s_ctrl:    Interface for the CTRL slave connection (EP's AXIS-Ctrl input)
    //   m_chdr:    Array of interfaces for the CHDR master connection (EP's AXIS CHDR data output)
    //   s_chdr:    Array of interfaces for the CHDR slave connection (EP's AXIS CHDR data input)
    //
    function new(
      virtual RfnocBackendIf.master        backend,
      virtual AxiStreamIf #(32).master     m_ctrl,
      virtual AxiStreamIf #(32).slave      s_ctrl,
      virtual AxiStreamIf #(CHDR_W).master m_chdr[0:NUM_PORTS-1],
      virtual AxiStreamIf #(CHDR_W).slave  s_chdr[0:NUM_PORTS-1],
      input   ctrl_port_t                  dst_port = 2,
      input   ctrl_port_t                  src_port = 1
    );
      ctrl = new(m_ctrl, s_ctrl, dst_port, src_port);
      bkend = backend;
      bkend.chdr_rst = 0;
      bkend.ctrl_rst = 0;
      for (int i = 0; i < NUM_PORTS; i++) begin
        chdr[i] = new(m_chdr[i], s_chdr[i]);
      end
    endfunction : new

    // Start the data and control BFM's processes running.
    task run();
      for (int i = 0; i < NUM_PORTS; i++) 
        chdr[i].run();
      ctrl.run();
    endtask : run

    // Get static info about the block from the block
    task get_block_info(
      output logic [31:0] noc_id,
      output logic  [5:0] num_data_i,
      output logic  [5:0] num_data_o,
      output logic  [5:0] ctrl_fifosize,
      output logic  [5:0] mtu
    );
      noc_id = bkend.sts.noc_id;
      num_data_i = bkend.sts.num_data_i;
      num_data_o = bkend.sts.num_data_o;
      ctrl_fifosize = bkend.sts.ctrl_fifosize;
      mtu = bkend.sts.mtu;
    endtask : get_block_info

    // Flush the data ports of the block
    //
    //   idle_cyc: Number of idle cycles before done is asserted
    //
    task flush(
      input logic [31:0] idle_cyc = 100
    );
      // Set flush timeout then wait
      bkend.cfg.flush_timeout = idle_cyc;
      repeat (CMD_PROP_CYC) @(posedge bkend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge bkend.chdr_clk);
      // Start flush then wait for done
      @(posedge bkend.ctrl_clk);
      bkend.cfg.flush_en = 1;
      @(posedge bkend.ctrl_clk);
      while (~bkend.sts.flush_done) @(posedge bkend.ctrl_clk);
      // Deassert flush then wait
      bkend.cfg.flush_en = 0;
      repeat (CMD_PROP_CYC) @(posedge bkend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge bkend.chdr_clk);
    endtask : flush

    // Flush the data ports of the block then reset the CHDR
    // path, wait then reset the ctrl path
    //
    //   idle_cyc: Number of idle cycles before done is asserted
    //
    task flush_and_reset(
      input logic [31:0] idle_cyc     = 100,
      input int          chdr_rst_cyc = 100,
      input int          ctrl_rst_cyc = 100
    );
      // Set flush timeout then wait
      bkend.cfg.flush_timeout = idle_cyc;
      repeat (CMD_PROP_CYC) @(posedge bkend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge bkend.chdr_clk);
      // Start flush then wait for done
      @(posedge bkend.ctrl_clk);
      bkend.cfg.flush_en = 1;
      @(posedge bkend.ctrl_clk);
      while (~bkend.sts.flush_done) @(posedge bkend.ctrl_clk);
      // Assert chdr_rst then wait
      @(posedge bkend.chdr_clk);
      bkend.chdr_rst = 1;
      @(posedge bkend.chdr_clk);
      bkend.chdr_rst = 0;
      repeat (chdr_rst_cyc) @(posedge bkend.chdr_clk);
      // Assert chdr_rst then wait
      @(posedge bkend.ctrl_clk);
      bkend.ctrl_rst = 1;
      @(posedge bkend.ctrl_clk);
      bkend.ctrl_rst = 0;
      repeat (ctrl_rst_cyc) @(posedge bkend.ctrl_clk);
      // Deassert flush then wait
      bkend.cfg.flush_en = 0;
      repeat (CMD_PROP_CYC) @(posedge bkend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge bkend.chdr_clk);
    endtask : flush_and_reset


    // Send a CHDR data packet out the CHDR data interface.
    //
    //   data:       Data words to insert into the CHDR packet.
    //   metadata:   Metadata words to insert into the CHDR packet. Omit this
    //               argument (or set to an empty array) to not include
    //               metadata.
    //   timestamp:  Timestamp to insert into the CHDR packet. Omit this
    //               argument (or set to an unknown value, as in X or Z) to not
    //               include a timestamp.
    //
    task send (
      input int         port,
      input chdr_word_t data[$],
      input int         data_bytes = -1,
      input chdr_word_t metadata[$] = {},
      input chdr_word_t timestamp = 'X
    );
      chdr[port].send(data, data_bytes, metadata, timestamp);
    endtask : send

    // Receive a CHDR data packet on the CHDR data interface and extract its
    // contents.
    //
    //   data:        Data words from the received CHDR packet.
    //   metadata:    Metadata words from the received CHDR packet. This
    //                will be an empty array if there was no metadata.
    //   timestamp:   Timestamp from the received CHDR packet. If there
    //                was no timestamp, then this will be X.
    //   data_bytes:  The number of data bytes in the CHDR packet. This
    //                is useful if the data is not a multiple of the
    //                chdr_word_t size.
    //
    task recv_adv (
      input  int         port,
      output chdr_word_t data[$],
      output int         data_bytes,
      output chdr_word_t metadata[$],
      output chdr_word_t timestamp
    );
      chdr[port].recv_adv(data, data_bytes, metadata, timestamp);
    endtask : recv_adv


    // Receive a CHDR data packet on the CHDR data interface and extract the
    // data. Any metadata or timestamp, if present, are discarded.
    //
    //   data:  Data words from the received CHDR packet
    //
    task recv(input int port, output chdr_word_t data[$]);
      chdr[port].recv(data);
    endtask : recv

    // Send a read request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   addr:   Address for the read request
    //   word:   Data word that was returned in response to the read
    //
    task reg_read (
      input  ctrl_address_t addr,
      output ctrl_word_t    word
    );
      ctrl.reg_read(addr, word);
    endtask : reg_read


    // Send a a write request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   addr:   Address for the write request
    //   word:   Data word to write
    //
    task reg_write (
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      ctrl.reg_write(addr, word);
    endtask : reg_write

    // Compare data vectors
    static function bit compare_data(
      input chdr_word_t lhs[$],
      input chdr_word_t rhs[$],
      input int         bytes = -1
    );
      int bytes_left;
      if (lhs.size() != rhs.size()) return 0;
      bytes_left = (bytes > 0) ? bytes : ((lhs.size()*$size(chdr_word_t))/8);
      for (int i = 0; i < lhs.size(); i++) begin
        chdr_word_t mask = {$size(chdr_word_t){1'b1}};
        if (bytes_left < $size(chdr_word_t)/8) begin
          mask = (1 << (bytes_left * 8)) - 1;
        end else if (bytes_left < 0) begin
          return 1;
        end
        if ((lhs[i] & mask) != (rhs[i] & mask)) return 0;
      end
      return 1;
    endfunction : compare_data

  endclass : RfnocBlockCtrlBfm


endpackage : PkgRfnocBlockCtrlBfm
