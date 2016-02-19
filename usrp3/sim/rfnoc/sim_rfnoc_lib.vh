//
// Copyright 2015 Ettus Research
//
// RFNoC sim lib's main goals are to provide macros so the user can easily build up a RFNoC design
// and provide a fully compliant (i.e. has packetization, flow control) RFNoC interface to the user's
// test bench. The RFNoC interface comes from a Export I/O RFNoC block that exposes NoC Shell and
// AXI Wrapper interfaces via the block's toplevel port list.
//
// Block Diagram:
//   -------------------------------------------------------------      -----------------------------
//  |                      AXI Crossbar                           |    |  bus_clk, bus_rst generator |
//   -------------------------------------------------------------      -----------------------------
//         ||                         ||                       ||       -----------------------------
//   -------------   --------------------------------------    ||      |  ce_clk, ce_rst generator   |
//  |             | |             noc_block_tb             |   ||       -----------------------------
//  |  User DUT   | |       (Export I/O RFNoC Block)       | tb_cvita
//  | RFNoC Block | |                                      |
//  |             | |  ----------------------------------  |
//   -------------  | |            NoC Shell             | |
//                  | |                                  | |
//                  | |   block     block                | |
//                  | |   port 0    port 1  cmdout ackin | |
//                  |  ----------------------------------  |
//                  |       ||        ||       |     |     |
//                  |  -------------  ||       |     |     |
//                  | | AXI Wrapper | ||       |     |     |
//                  |  -------------  ||       |     |     |
//                   -------||--------||-------|-----|-----
//                          ||        ||       |     |
//                   -------||--------||-------|-----|----------
//                  |  tb_axis_data   ||       |   tb_cvita_ack |
//                  |                 ||    tb_cvita_cmd        |
//                  |            tb_cvita_data                  |
//                  |                                           |
//                  |             User Test Bench               |
//                   -------------------------------------------
//
// Usage: Include sim_rfnoc_lib.sv, setup prerequisites with `RFNOC_SIM_INIT(), and add RFNoC blocks
//        with `RFNOC_ADD_BLOCK(). Connect RFNoC blocks into a flow graph using `RFNOC_CONNECT().
//
// Example:
// `include "sim_rfnoc_lib.vh"
//  module rfnoc_testbench();
//    `RFNOC_SIM_INIT(2,100,50); // Simulation will have two RFNoC blocks, 100 MHz bus_clk, 50 MHz ce_clk
//    `RFNOC_ADD_BLOCK(noc_block_fir,0); // Instantiate FIR and connect to crossbar port 0
//    `RFNOC_ADD_BLOCK(noc_block_fft,1); // Instantiate FFT and connect to crossbar port 1
//    initial begin
//      `RFNOC_CONNECT(noc_block_tb,noc_block_fir,1024);  // Connect test bench to FIR. Note the special block 'noc_block_tb' which is added in `RFNOC_SIM_INIT()
//      `RFNOC_CONNECT(noc_block_fir,noc_block_fft,1024); // Connect FIR to FFT. Packet size 256
//    end
//  endmodule
//
// Warning: Most of the macros create specifically named signals used by other macros

`include "sim_clks_rsts.vh"
`include "sim_cvita_lib.sv"
`include "sim_set_rb_lib.sv"

  // NoC Shell Registers
  // 8-bit address space, but use 32-bits for convenience
  // One register per block port, spaced by 16 for (up to) 16 block ports
  localparam [31:0] SR_FLOW_CTRL_CYCS_PER_ACK      = 0;
  localparam [31:0] SR_FLOW_CTRL_PKTS_PER_ACK      = 1;
  localparam [31:0] SR_FLOW_CTRL_WINDOW_SIZE       = 2;
  localparam [31:0] SR_FLOW_CTRL_WINDOW_EN         = 3;
  localparam [31:0] SR_ERROR_POLICY                = 4;
  localparam [31:0] SR_SRC_SID                     = 5;
  localparam [31:0] SR_NEXT_DST_SID                = 6;
  localparam [31:0] SR_RESP_IN_DST_SID             = 7;
  localparam [31:0] SR_RESP_OUT_DST_SID            = 8;
  localparam [31:0] SR_RB_ADDR_USER                = 124;
  localparam [31:0] SR_CLEAR_RX_FC                 = 125;
  localparam [31:0] SR_CLEAR_TX_FC                 = 126;
  localparam [31:0] SR_RB_ADDR                     = 127;
  // Next destination as allocated by the user, one per block port
  localparam [31:0] SR_AXI_CONFIG_BASE             = 129;
  localparam [31:0] SR_USER_RB_ADDR                = 255;

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
  //   - num_rfnoc_blocks:              Number of RFNoC blocks in simulation. Max 14.
  //   - bus_clk_period, ce_clk_period: Bus, RFNoC block clock frequencies
  //
  `define RFNOC_SIM_INIT(num_rfnoc_blocks, bus_clk_period, ce_clk_period) \
     // Setup clock, reset \
    `DEFINE_CLK(bus_clk, bus_clk_period, 50); \
    `DEFINE_RESET(bus_rst, 0, 1000); \
    `DEFINE_CLK(ce_clk, ce_clk_period, 50); \
    `DEFINE_RESET(ce_rst, 0, 1000); \
    `RFNOC_ADD_AXI_CROSSBAR(0, num_rfnoc_blocks+2); \
    `RFNOC_ADD_TESTBENCH_BLOCK(tb,num_rfnoc_blocks); \
    `RFNOC_ADD_CVITA_PORT(tb_cvita,num_rfnoc_blocks+1);

  // Instantiates an AXI crossbar and related signals. Instantiates several signals
  // starting with the prefix 'xbar_'.
  //
  // Usage: `INST_AXI_CROSSBAR()
  // where
  //   - xbar_name:     Instance name of crossbar. Also affects the naming of several generated signals.
  //   - _xbar_addr:    Crossbar address
  //   - _num_ports:    Number of crossbar ports
  //
  `define RFNOC_ADD_AXI_CROSSBAR(_xbar_addr, _num_ports) \
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
      .rb_bus(xbar_rb_bus));

  // Instantiate and connect a RFNoC block to a crossbar. Expects clock & reset
  // signals to be defined with the names ce_clk & ce_rst. Generally used with
  // RFNOC_SIM_INIT().
  //
  // Usage: `RFNOC_ADD_BLOCK()
  // where
  //  - noc_block_name:  Name of RFNoC block to instantiate, i.e. noc_block_fft
  //  - port_num:        Crossbar port to connect RFNoC block to 
  //
  `define RFNOC_ADD_BLOCK(noc_block_name, port_num) \
    `RFNOC_ADD_BLOCK_X(noc_block_name, port_num, ce_clk, ce_rst,)

  // Instantiate and connect a RFNoC block to a crossbar. Includes extra parameters
  // for custom clock / reset signals and expanding the RFNoC block's name.
  //
  // Usage: `RFNOC_ADD_BLOCK_X()
  // where
  //  - noc_block_name:  Name of RFNoC block to instantiate, i.e. noc_block_fft
  //  - port_num:        Crossbar port to connect block to 
  //  - ce_clk, ce_rst:  RFNoC block clock and reset
  //  - append:          Append to instance name, useful if instantiating 
  //                     several of the same kind of RFNoC block and need unique
  //                     instance names. Otherwise leave blank.
  //
  `define RFNOC_ADD_BLOCK_X(noc_block_name, port_num, ce_clk, ce_rst, append) \
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
  // Usage: `RFNOC_ADD_TESTBENCH_BLOCK()
  // where
  //  - name:            Instance name
  //  - port_num:        Crossbar port to connect block to
  //
  `define RFNOC_ADD_TESTBENCH_BLOCK(name, port_num) \
    settings_bus_t #(.AWIDTH(8)) noc_block_``name``_set_bus(.clk(ce_clk)); \
    readback_bus_t #(.AWIDTH(8)) noc_block_``name``_rb_bus(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_``name``_s_cvita_data(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_``name``_m_cvita_data(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_``name``_cvita_cmd(.clk(ce_clk)); \
    axis_t #(.DWIDTH(64)) noc_block_``name``_cvita_ack(.clk(ce_clk)); \
    axis_t noc_block_``name``_m_axis_data(.clk(ce_clk)); \
    axis_t noc_block_``name``_m_axis_config(.clk(ce_clk)); \
    axis_t noc_block_``name``_s_axis_data(.clk(ce_clk)); \
    // User test bench signals \
    localparam [15:0] sid_noc_block_``name = {xbar_addr,4'd0+port_num,4'd0}; \
    cvita_bus    name``_cvita_data; \
    cvita_master name``_cvita_cmd; \
    cvita_slave  name``_cvita_ack; \
    axis_bus     name``_axis_data; \
    axis_slave   name``_axis_config; \
    // Setup class instances for testbench to use & module flow control \
    initial begin \
      name``_cvita_data = new(noc_block_``name``_s_cvita_data,noc_block_``name``_m_cvita_data); \
      name``_cvita_cmd = new(noc_block_``name``_cvita_cmd); \
      name``_cvita_ack = new(noc_block_``name``_cvita_ack); \
      name``_axis_data = new(noc_block_``name``_s_axis_data,noc_block_``name``_m_axis_data); \
      name``_axis_config = new(noc_block_``name``_m_axis_config); \
    end \
    // Setup module \
    noc_block_export_io \
    noc_block_``name ( \
      .bus_clk(bus_clk), \
      .bus_rst(bus_rst), \
      .ce_clk(ce_clk), \
      .ce_rst(ce_rst), \
      .s_cvita(xbar_m_cvita[port_num]), \
      .m_cvita(xbar_s_cvita[port_num]), \
      .set_bus(noc_block_``name``_set_bus), \
      .rb_bus(noc_block_``name``_rb_bus), \
      .s_cvita_data(noc_block_``name``_s_cvita_data), \
      .m_cvita_data(noc_block_``name``_m_cvita_data), \
      .cvita_cmd(noc_block_``name``_cvita_cmd), \
      .cvita_ack(noc_block_``name``_cvita_ack), \
      .m_axis_data(noc_block_``name``_m_axis_data), \
      .m_axis_config(noc_block_``name``_m_axis_config), \
      .s_axis_data(noc_block_``name``_s_axis_data), \
      .debug());

  // Instantiate and connect a cvita_bus instance directly to the crossbar.
  // Warning: This port will have no flow control or other functionality provided by NoC Shell.
  //
  // Usage: `RFNOC_ADD_CVITA_PORT()
  // where
  //  - port_num:        Crossbar port to connect to
  //
  `define RFNOC_ADD_CVITA_PORT(name,port_num) \
    cvita_bus name; \
    localparam [15:0] sid_``name = {xbar_addr,4'd0+port_num,4'd0}; \
    initial begin \
      name = new(xbar_s_cvita[port_num],xbar_m_cvita[port_num]); \
    end

  // Connecting two RFNoC blocks requires setting up flow control and
  // their next destination registers.
  //
  // Usage: `RFNOC_CONNECT()
  // where
  //  - from_noc_block_name:   Name of producer (or upstream) RFNoC block
  //  - to_noc_block_name:     Name of consuming (or downstream) RFNoC block
  //  - pkt_size:              Maximum expected packet size in bytes
  //
  `define RFNOC_CONNECT(from_noc_block_name,to_noc_block_name,pkt_size) \
    `RFNOC_CONNECT_BLOCK_PORT(from_noc_block_name,0,to_noc_block_name,0,pkt_size);

  // Setup RFNoC block flow control per block port
  //
  // Usage: `RFNOC_CONNECT_BLOCK_PORT()
  // where
  //  - from_noc_block_name:   Name of producer (or upstream) RFNoC block
  //  - from_block_port:       Block port of producer RFNoC block
  //  - to_noc_block_name:     Name of consumer (or downstream) RFNoC block
  //  - to_block_port:         Block port of consumer RFNoC block
  //  - pkt_size:              Maximum expected packet size in bytes
  //
  `define RFNOC_CONNECT_BLOCK_PORT(from_noc_block_name,from_block_port,to_noc_block_name,to_block_port,pkt_size) \
    // Set block stream IDs \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_SRC_SID, 16'd0, 16'(sid_``from_noc_block_name + from_block_port)}}); \
    tb_cvita.drop_pkt();  // Don't care about response packets \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h1, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``to_noc_block_name + to_block_port), timestamp:64'h0})}, \
                      {SR_SRC_SID, 16'd0, 16'(sid_``to_noc_block_name + to_block_port)}}); \
    tb_cvita.drop_pkt(); \
    // Send a flow control response packet on every received packet \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h2, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``to_noc_block_name + to_block_port), timestamp:64'h0})}, \
                      {SR_FLOW_CTRL_PKTS_PER_ACK, 32'h8000_0001}}); \
    tb_cvita.drop_pkt(); \
    // Set up window size \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h3, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_FLOW_CTRL_WINDOW_SIZE, \
                      // Subtract 1 to account for +1 in source_flow_control.v \
                      32'((8*2**(``to_noc_block_name``.noc_shell.STR_SINK_FIFOSIZE[(to_block_port+1)*8-1:to_block_port*8]))/pkt_size)-32'd1}}); \
    tb_cvita.drop_pkt(); \
    // Enable window \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h4, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_FLOW_CTRL_WINDOW_EN, 32'h0000_0001}}); \
    tb_cvita.drop_pkt(); \
    // Set next destination stream ID \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h5, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_NEXT_DST_SID, 32'(sid_``to_noc_block_name + to_block_port)}}); \
    tb_cvita.drop_pkt(); \
    // Set both response destination stream IDs, default to test bench block \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h6, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_RESP_IN_DST_SID, 32'(sid_noc_block_tb)}}); \
    tb_cvita.drop_pkt(); \
    tb_cvita.push_pkt({{flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h7, length:8, src_sid:sid_tb_cvita, dst_sid:(sid_``from_noc_block_name + from_block_port), timestamp:64'h0})}, \
                      {SR_RESP_OUT_DST_SID, 32'(sid_noc_block_tb)}}); \
    tb_cvita.drop_pkt();

  `endif