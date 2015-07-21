//
// Copyright 2015 Ettus Research LLC
//

`include "sim_clks_rsts.vh"
`include "sim_cvita_lib.sv"
`include "sim_set_rb_lib.sv"

  // NoC Shell Registers
  // 8-bit address space, but use 32-bits for convenience
  // One register per block port, spaced by 16 for (up to) 16 block ports
  localparam [31:0] SR_FLOW_CTRL_CYCS_PER_ACK_BASE = 0;
  localparam [31:0] SR_FLOW_CTRL_PKTS_PER_ACK_BASE = 16;
  localparam [31:0] SR_FLOW_CTRL_WINDOW_SIZE_BASE  = 32;
  localparam [31:0] SR_FLOW_CTRL_WINDOW_EN_BASE    = 48;
  // One register per noc shell
  localparam [31:0] SR_FLOW_CTRL_CLR_SEQ           = 126;
  localparam [31:0] SR_NOC_SHELL_READBACK          = 127;
  // Next destination as allocated by the user, one per block port
  localparam [31:0] SR_NEXT_DST_BASE               = 128;
  localparam [31:0] SR_AXI_CONFIG_BASE             = 129;
  localparam [31:0] SR_READBACK_ADDR               = 255;

  `ifndef _RFNOC_SIM_LIB
  `define _RFNOC_SIM_LIB

  // Setup a RFNoC simulation. Creates clocks (bus_clk, ce_clk), resets (bus_rst, ce_rst), an
  // AXI crossbar, and Export IO RFNoC block instance. Export IO is a special RFNoC block used
  // to expose the internal NoC Shell / AXI wrapper interfaces to the test bench.
  //
  // Several of the called macros instantiate signals with hard coded names for the test bench
  // to use.
  //
  // Usage: `RFNOC_SIM_INIT()
  // where
  //   - num_rfnoc_blocks:           Number of RFNoC blocks in simulation. Max 15.
  //   - bus_clk_freq, ce_clk_freq:  Bus, RFNoC block clock frequencies
  //
  `define RFNOC_SIM_INIT(num_rfnoc_blocks, bus_clk_freq, ce_clk_freq) \
     // Setup clock, reset \
    `DEFINE_CLK(bus_clk, bus_clk_freq, 50); \
    `DEFINE_RESET(bus_rst, 0, 1000); \
    `DEFINE_CLK(ce_clk, ce_clk_freq, 50); \
    `DEFINE_RESET(ce_rst, 0, 1000); \
    `INST_AXI_CROSSBAR(0, num_rfnoc_blocks+1); \
    `CONNECT_RFNOC_BLOCK_EXPORT_IO(num_rfnoc_blocks)

  // Instantiates an AXI crossbar and related signals. Instantiates several signals
  // starting with the prefix 'xbar_'.
  //
  // Usage: `INST_AXI_CROSSBAR()
  // where
  //   - xbar_name:     Instance name of crossbar. Also affects the naming of several generated signals.
  //   - _xbar_addr:    Crossbar address
  //   - _num_ports:    Number of crossbar ports
  //
  `define INST_AXI_CROSSBAR(_xbar_addr, _num_ports) \
    localparam [7:0] xbar_addr = _xbar_addr; \
    axis_t #(.DWIDTH(64)) xbar_s_cvita[0:_num_ports-1](.clk(bus_clk)); \
    axis_t #(.DWIDTH(64)) xbar_m_cvita[0:_num_ports-1](.clk(bus_clk)); \
    settings_bus_t #(.AWIDTH(16)) xbar_set_bus(.clk(bus_clk)); \
    readback_bus_t #(.AWIDTH(16)) xbar_rb_bus(.clk(bus_clk)); \
    // Crossbar \
    axi_crossbar_intf #( \
      .BASE(0), .FIFO_WIDTH(64), .DST_WIDTH(16), \
      .NUM_PORTS(_num_ports)) \
    axi_crossbar ( \
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0), \
      .local_addr(xbar_addr), \
      .s_cvita(xbar_s_cvita), \
      .m_cvita(xbar_m_cvita), \
      .set_bus(xbar_set_bus), \
      .rb_bus(xbar_rb_bus))

  // Instantiate and connect a RFNoC block to a crossbar. Expects clock & reset
  // signals to be defined with the names ce_clk & ce_rst. Generally used with
  // RFNOC_SIM_INIT().
  //
  // Usage: `CONNECT_RFNOC_BLOCK()
  // where
  //  - noc_block_name:  Name of RFNoC block to instantiate, i.e. noc_block_fft
  //  - port_num:        Crossbar port to connect RFNoC block to 
  //
  `define CONNECT_RFNOC_BLOCK(noc_block_name, port_num) \
    `CONNECT_RFNOC_BLOCK_X(noc_block_name, port_num, ce_clk, ce_rst,)

  // Instantiate and connect a RFNoC block to a crossbar. Includes extra parameters
  // for custom clock / reset signals and 
  //
  // Usage: `CONNECT_RFNOC_BLOCK_X()
  // where
  //  - noc_block_name:  Name of RFNoC block to instantiate, i.e. noc_block_fft
  //  - port_num:        Crossbar port to connect block to 
  //  - ce_clk, ce_rst:  RFNoC block clock and reset
  //  - append:          Append to instance name, useful if instantiating 
  //                     several of the same kind of RFNoC block and need unique
  //                     instance names. Otherwise leave blank.
  //
  `define CONNECT_RFNOC_BLOCK_X(noc_block_name, port_num, ce_clk, ce_rst, append) \
    localparam [15:0] sid_``noc_block_name``append = {xbar_addr,4'd0+port_num,4'd0}; \
    // Setup module \
    noc_block_name \
    noc_block_name``append ( \
      .bus_clk(bus_clk), \
      .bus_rst(bus_rst), \
      .ce_clk(ce_clk), \
      .ce_rst(ce_rst), \
      .i_tdata(xbar_m_cvita[port_num].tdata), \
      .i_tlast(xbar_m_cvita[port_num].tlast), \
      .i_tvalid(xbar_m_cvita[port_num].tvalid), \
      .i_tready(xbar_m_cvita[port_num].tready), \
      .o_tdata(xbar_s_cvita[port_num].tdata), \
      .o_tlast(xbar_s_cvita[port_num].tlast), \
      .o_tvalid(xbar_s_cvita[port_num].tvalid), \
      .o_tready(xbar_s_cvita[port_num].tready), \
      .debug());

  // Instantiate and connect the export I/O RFNoC block to a crossbar. Export I/O is a block that exports
  // the internal NoC Shell & AXI Wrapper I/O to the port list. The block is useful for test benches to
  // use to interact with other RFNoC blocks via the standard RFNoC user interfaces.
  // 
  // Instantiates several signals starting with the prefix 'tb_'.
  //
  // Usage: `CONNECT_RFNOC_BLOCK_EXPORT_IO()
  // where
  //  - port_num:        Crossbar port to connect block to
  //
  `define CONNECT_RFNOC_BLOCK_EXPORT_IO(port_num) \
    localparam [15:0] sid_tb = {xbar_addr,4'd0+port_num,4'd0}; \
    logic [15:0] tb_next_dst; \
    settings_bus_t #(.AWIDTH(8)) tb_set_bus(.clk(ce_clk)); \
    readback_bus_t #(.AWIDTH(8)) tb_rb_bus(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_export_io_s_cvita_data(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_export_io_m_cvita_data(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_export_io_cvita_cmd(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_export_io_cvita_ack(.clk(ce_clk)); \
    axis_t noc_block_export_io_m_axis_data(.clk(ce_clk)); \
    axis_t noc_block_export_io_m_axis_config(.clk(ce_clk)); \
    axis_t noc_block_export_io_s_axis_data(.clk(ce_clk)); \
    // Setup class instances for testbench to use \
    cvita_bus tb_cvita_data; \
    cvita_master tb_cvita_cmd; \
    cvita_slave tb_cvita_ack; \
    axis_bus tb_axis_data; \
    axis_slave tb_axis_config; \
    initial begin \
      tb_cvita_data = new(noc_block_export_io_s_cvita_data,noc_block_export_io_m_cvita_data); \
      tb_cvita_cmd = new(noc_block_export_io_cvita_cmd); \
      tb_cvita_ack = new(noc_block_export_io_cvita_ack); \
      tb_axis_data = new(noc_block_export_io_s_axis_data,noc_block_export_io_m_axis_data); \
      tb_axis_config = new(noc_block_export_io_m_axis_config); \
    end \
    // Setup module \
    noc_block_export_io \
    noc_block_export_io ( \
      .bus_clk(bus_clk), \
      .bus_rst(bus_rst), \
      .ce_clk(ce_clk), \
      .ce_rst(ce_rst), \
      .s_cvita(xbar_m_cvita[port_num]), \
      .m_cvita(xbar_s_cvita[port_num]), \
      .set_bus(tb_set_bus), \
      .rb_bus(tb_rb_bus), \
      .s_cvita_data(noc_block_export_io_s_cvita_data), \
      .m_cvita_data(noc_block_export_io_m_cvita_data), \
      .cvita_cmd(noc_block_export_io_cvita_cmd), \
      .cvita_ack(noc_block_export_io_cvita_ack), \
      .sid(sid_tb), \
      .next_dst(tb_next_dst), \
      .m_axis_data(noc_block_export_io_m_axis_data), \
      .m_axis_config(noc_block_export_io_m_axis_config), \
      .s_axis_data(noc_block_export_io_s_axis_data), \
      .debug());

  `endif