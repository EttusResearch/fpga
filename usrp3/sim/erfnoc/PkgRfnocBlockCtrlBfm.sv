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
} backend_config_v1_t;

typedef struct packed {
  bit [445:0] reserved0;
  bit         flush_done;
  bit         flush_active;
  bit [31:0]  noc_id;
  bit [5:0]   mtu;
  bit [5:0]   ctrl_fifosize;
  bit [5:0]   num_data_o;
  bit [5:0]   num_data_i;
  bit [7:0]   proto_ver;
} backend_status_v1_t;

typedef union packed {
  backend_config_v1_t v1;
} backend_config_t;

typedef union packed {
  backend_status_v1_t v1;
} backend_status_t;


interface RfnocBackendIf(
  input wire logic chdr_clk,
  input wire logic ctrl_clk
);
  backend_config_t cfg;
  backend_status_t sts;

  modport master (
    input  chdr_clk,
    input  ctrl_clk,
    output cfg,
    input  sts
  );
  modport slave (
    input  chdr_clk,
    input  ctrl_clk,
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
  import PkgRfnocItemUtils::*;

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
    //   data:        Data words from the received CHDR packet.
    //   data_bytes:  The number of data bytes in the CHDR packet. This
    //                is useful if the data is not a multiple of the
    //                chdr_word_t size.
    //
    task recv(output chdr_word_t data[$], output int data_bytes);
      ChdrPacket chdr_packet;
      get_chdr(chdr_packet);
      data = chdr_packet.data;
      data_bytes = chdr_packet.data_bytes();
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
        $fatal(1, "RegisterIfaceBfm::reg_read: Did not receive CTRL_STS_OKAY status");
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
        $fatal(1, "RegisterIfaceBfm::reg_write: Did not receive CTRL_STS_OKAY status");
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

  class RfnocBlockCtrlBfm #(CHDR_W = 64);

    local virtual RfnocBackendIf.master backend;
    local RegisterIfaceBfm              ctrl;
    local ChdrDataStreamBfm             m_data[$];
    local ChdrDataStreamBfm             s_data[$];
    local bit                           running;

    localparam CMD_PROP_CYC = 5;

    // Class constructor to create a new BFM instance.
    //
    //   backend:   Interface for the backend signals of a block
    //   m_ctrl:    Interface for the CTRL master connection (EP's AXIS-Ctrl output)
    //   s_ctrl:    Interface for the CTRL slave connection (EP's AXIS-Ctrl input)
    //   dst_port:  Destination port to use in generated control packets
    //   src_port:  Source port to use in generated control packets
    //
    function new(
      virtual RfnocBackendIf.master    backend,
      virtual AxiStreamIf #(32).master m_ctrl,
      virtual AxiStreamIf #(32).slave  s_ctrl,
      input   ctrl_port_t              dst_port = 10'd2,
      input   ctrl_port_t              src_port = 10'd1
    );
      this.backend = backend;
      this.ctrl = new(m_ctrl, s_ctrl, dst_port, src_port);
      this.running = 0;
    endfunction : new

    // Add a master data port. This should connect to a DUT input
    function int add_master_data_port(
      virtual AxiStreamIf #(CHDR_W).master m_chdr
    );
      ChdrDataStreamBfm bfm = new(m_chdr, null);
      m_data.push_back(bfm);
      return m_data.size() - 1;
    endfunction : add_master_data_port

    // Add a slave data port. This should connect to a DUT output
    function int add_slave_data_port(
      virtual AxiStreamIf #(CHDR_W).slave s_chdr
    );
      ChdrDataStreamBfm bfm = new(null, s_chdr);
      s_data.push_back(bfm);
      return s_data.size() - 1;
    endfunction : add_slave_data_port

    // Start the data and control BFM's processes running.
    task run();
      assert (backend.sts.v1.proto_ver == 1) else begin
        $fatal(1, "The connected block has an incompatible backend interface");
      end
      if (!running) begin
        ctrl.run();
        foreach (m_data[i]) 
          m_data[i].run();
        foreach (s_data[i]) 
          s_data[i].run();
        running = 1;
      end
    endtask : run

    // Get static info about the block
    function logic [7:0] get_proto_ver();
      return backend.sts.v1.proto_ver;
    endfunction : get_proto_ver

    function logic [31:0] get_noc_id();
      return backend.sts.v1.noc_id;
    endfunction : get_noc_id

    function logic [5:0] get_num_data_i();
      return backend.sts.v1.num_data_i;
    endfunction : get_num_data_i

    function logic [5:0] get_num_data_o();
      return backend.sts.v1.num_data_o;
    endfunction : get_num_data_o

    function logic [5:0] get_ctrl_fifosize();
      return backend.sts.v1.ctrl_fifosize;
    endfunction : get_ctrl_fifosize

    function logic [5:0] get_mtu();
      return backend.sts.v1.mtu;
    endfunction : get_mtu

    // Soft-Reset the CHDR path 
    //
    //   rst_cyc: Number of cycles to wait for reset completion
    //
    task reset_chdr(input int rst_cyc = 100);
      assert (running) else begin
        $fatal(1, "Cannot call flush_and_reset until RfnocBlockCtrlBfm is running");
      end

      // Assert soft_chdr_rst then wait
      // Note: soft_chdr_rst must be driven in the ctrl_clk domain
      @(posedge backend.ctrl_clk);
      backend.cfg.v1.soft_chdr_rst = 1;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      backend.cfg.v1.soft_chdr_rst = 0;
      @(posedge backend.ctrl_clk);
      repeat (rst_cyc) @(posedge backend.ctrl_clk);
    endtask : reset_chdr

    // Soft-Reset the Control path 
    //
    //   rst_cyc: Number of cycles to wait for reset completion
    //
    task reset_ctrl(input int rst_cyc = 100);
      assert (running) else begin
        $fatal(1, "Cannot call flush_and_reset until RfnocBlockCtrlBfm is running");
      end

      // Assert soft_ctrl_rst then wait
      @(posedge backend.ctrl_clk);
      backend.cfg.v1.soft_ctrl_rst = 1;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      backend.cfg.v1.soft_ctrl_rst = 0;
      repeat (rst_cyc) @(posedge backend.ctrl_clk);
    endtask : reset_ctrl

    // Flush the data ports of the block
    //
    //   idle_cyc: Number of idle cycles before done is asserted
    //
    task flush(input logic [31:0] idle_cyc = 100);
      assert (running) else begin
        $fatal(1, "Cannot call flush until RfnocBlockCtrlBfm is running");
      end

      // Set flush timeout then wait
      backend.cfg.v1.flush_timeout = idle_cyc;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge backend.chdr_clk);
      // Start flush then wait for done
      @(posedge backend.ctrl_clk);
      backend.cfg.v1.flush_en = 1;
      @(posedge backend.ctrl_clk);
      while (~backend.sts.v1.flush_done) @(posedge backend.ctrl_clk);
      // Deassert flush then wait
      backend.cfg.v1.flush_en = 0;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge backend.chdr_clk);
    endtask : flush

    // Flush the data ports of the block then reset the CHDR
    // path, wait then reset the ctrl path
    //
    //   idle_cyc: Number of idle cycles before done is asserted
    //   chdr_rst_cyc: Number of cycles to wait for chdr_rst completion
    //   ctrl_rst_cyc: Number of cycles to wait for ctrl_rst completion
    //
    task flush_and_reset(
      input logic [31:0] idle_cyc     = 100,
      input int          chdr_rst_cyc = 100,
      input int          ctrl_rst_cyc = 100
    );
      assert (running) else begin
        $fatal(1, "Cannot call flush_and_reset until RfnocBlockCtrlBfm is running");
      end

      // Set flush timeout then wait
      backend.cfg.v1.flush_timeout = idle_cyc;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge backend.chdr_clk);
      // Start flush then wait for done
      @(posedge backend.ctrl_clk);
      backend.cfg.v1.flush_en = 1;
      @(posedge backend.ctrl_clk);
      while (~backend.sts.v1.flush_done) @(posedge backend.ctrl_clk);
      // Assert chdr_rst then wait
      reset_chdr(chdr_rst_cyc);
      // Assert ctrl_rst then wait
      reset_ctrl(ctrl_rst_cyc);
      // Deassert flush then wait
      backend.cfg.v1.flush_en = 0;
      repeat (CMD_PROP_CYC) @(posedge backend.ctrl_clk);
      repeat (CMD_PROP_CYC) @(posedge backend.chdr_clk);
    endtask : flush_and_reset


    // Send a CHDR data packet out the CHDR data interface.
    //
    //   port:       Port to send the CHDR packet on.
    //   data:       Data words to insert into the CHDR packet.
    //   data_bytes: Size of data in bytes. If omitted or -1, data_bytes will
    //               be calculated based on the number of words in data.
    //   metadata:   Metadata words to insert into the CHDR packet. Omit this
    //               argument (or set to an empty array) to not include
    //               metadata.
    //   timestamp:  Timestamp to insert into the CHDR packet. Omit this
    //               argument (or set to an unknown value, as in X or Z) to not
    //               include a timestamp.
    //
    task send(
      input int         port,
      input chdr_word_t data[$],
      input int         data_bytes = -1,
      input chdr_word_t metadata[$] = {},
      input chdr_word_t timestamp = 'X
    );
      assert (running) else begin
        $fatal(1, "Cannot call send until RfnocBlockCtrlBfm is running");
      end
      assert (port >= 0 && port < m_data.size()) else begin
        $fatal(1, "Invalid master port number");
      end

      m_data[port].send(data, data_bytes, metadata, timestamp);
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
    task recv_adv(
      input  int         port,
      output chdr_word_t data[$],
      output int         data_bytes,
      output chdr_word_t metadata[$],
      output chdr_word_t timestamp
    );
      assert (running) else begin
        $fatal(1, "Cannot call recv_adv until RfnocBlockCtrlBfm is running");
      end
      assert (port >= 0 && port < s_data.size()) else begin
        $fatal(1, "Invalid slave port number");
      end

      s_data[port].recv_adv(data, data_bytes, metadata, timestamp);
    endtask : recv_adv


    // Receive a CHDR data packet on the CHDR data interface and extract the
    // data. Any metadata or timestamp, if present, are discarded.
    //
    //   port:        Port number for the block to receive from
    //   data:        Data words from the received CHDR packet
    //   data_bytes:  The number of data bytes in the CHDR packet. This
    //                is useful if the data is not a multiple of the
    //                chdr_word_t size.
    //
    task recv(
      input  int         port,
      output chdr_word_t data[$],
      output int         data_bytes
    );
      assert (running) else begin
        $fatal(1, "Cannot call recv until RfnocBlockCtrlBfm is running");
      end
      assert (port >= 0 && port < s_data.size()) else begin
        $fatal(1, "Invalid port number");
      end

      s_data[port].recv(data, data_bytes);
    endtask : recv

    // Send a read request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   addr:   Address for the read request
    //   word:   Data word that was returned in response to the read
    //
    task reg_read(
      input  ctrl_address_t addr,
      output ctrl_word_t    word
    );
      assert (running) else begin
        $fatal(1, "Cannot call reg_read until RfnocBlockCtrlBfm is running");
      end

      ctrl.reg_read(addr, word);
    endtask : reg_read


    // Send a a write request packet on the AXIS-Ctrl interface and get the
    // response.
    //
    //   addr:   Address for the write request
    //   word:   Data word to write
    //
    task reg_write(
      ctrl_address_t addr,
      ctrl_word_t    word
    );
      assert (running) else begin
        $fatal(1, "Cannot call reg_write until RfnocBlockCtrlBfm is running");
      end

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
