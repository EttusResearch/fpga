/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2015 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier: xilinx.com:ip:fir_compiler:6.3      *
*                                                                              *
*     The Xilinx FIR Compiler LogiCORE is a module for generation of high      *
*     speed, compact filter implementations that can be configured to          *
*     implement many different filtering functions. The core is fully          *
*     synchronous, using a single clock, and is highly parameterizable,        *
*     allowing designers to control the filter type, data and coefficient      *
*     widths, the number of filter taps, the number of channels, etc.          *
*     Multi-rate operation is supported. The core is delivered through the     *
*     Xilinx CORE Generator System and integrates seamlessly with the          *
*     Xilinx design flow.                                                      *
*******************************************************************************/

// Interfaces:
//    event_s_data_tlast_missing_intf
//    event_s_data_tlast_unexpected_intf
//    event_s_data_chanid_incorrect_intf
//    event_s_config_tlast_missing_intf
//    event_s_config_tlast_unexpected_intf
//    event_s_reload_tlast_missing_intf
//    event_s_reload_tlast_unexpected_intf
//    S_AXIS_RELOAD
//    aclk_intf
//    aresetn_intf
//    aclken_intf
//    S_AXIS_DATA
//    M_AXIS_DATA
//    S_AXIS_CONFIG

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
simple_fir your_instance_name (
  .aresetn(aresetn), // input aresetn
  .aclk(aclk), // input aclk
  .s_axis_data_tvalid(s_axis_data_tvalid), // input s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready), // output s_axis_data_tready
  .s_axis_data_tlast(s_axis_data_tlast), // input s_axis_data_tlast
  .s_axis_data_tdata(s_axis_data_tdata), // input [31 : 0] s_axis_data_tdata
  .s_axis_config_tvalid(s_axis_config_tvalid), // input s_axis_config_tvalid
  .s_axis_config_tready(s_axis_config_tready), // output s_axis_config_tready
  .s_axis_config_tdata(s_axis_config_tdata), // input [7 : 0] s_axis_config_tdata
  .s_axis_reload_tvalid(s_axis_reload_tvalid), // input s_axis_reload_tvalid
  .s_axis_reload_tready(s_axis_reload_tready), // output s_axis_reload_tready
  .s_axis_reload_tlast(s_axis_reload_tlast), // input s_axis_reload_tlast
  .s_axis_reload_tdata(s_axis_reload_tdata), // input [31 : 0] s_axis_reload_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid), // output m_axis_data_tvalid
  .m_axis_data_tready(m_axis_data_tready), // input m_axis_data_tready
  .m_axis_data_tlast(m_axis_data_tlast), // output m_axis_data_tlast
  .m_axis_data_tuser(m_axis_data_tuser), // output [0 : 0] m_axis_data_tuser
  .m_axis_data_tdata(m_axis_data_tdata), // output [95 : 0] m_axis_data_tdata
  .event_s_reload_tlast_missing(event_s_reload_tlast_missing), // output event_s_reload_tlast_missing
  .event_s_reload_tlast_unexpected(event_s_reload_tlast_unexpected) // output event_s_reload_tlast_unexpected
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file simple_fir.v when simulating
// the core, simple_fir. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

