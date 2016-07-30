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
*     (c) Copyright 1995-2014 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier: xilinx.com:ip:div_gen:4.0           *
*                                                                              *
*     This core provides division using one of two algorithms. The Radix-2     *
*     algorithm provides a fabric solution suitable for smaller operand        *
*     division, and High Radix algorithm provides a solution based upon        *
*     XtremeDSP slices and so is well suited to larger operands (that is       *
*     above about 16 bits wide).                                               *
*******************************************************************************/

// Interfaces:
//    M_AXIS_DOUT
//    aclk_intf
//    aresetn_intf
//    aclken_intf
//    S_AXIS_DIVISOR
//    S_AXIS_DIVIDEND

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
divide_int32 your_instance_name (
  .aclk(aclk), // input aclk
  .aresetn(aresetn), // input aresetn
  .s_axis_divisor_tvalid(s_axis_divisor_tvalid), // input s_axis_divisor_tvalid
  .s_axis_divisor_tready(s_axis_divisor_tready), // output s_axis_divisor_tready
  .s_axis_divisor_tlast(s_axis_divisor_tlast), // input s_axis_divisor_tlast
  .s_axis_divisor_tdata(s_axis_divisor_tdata), // input [31 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(s_axis_dividend_tvalid), // input s_axis_dividend_tvalid
  .s_axis_dividend_tready(s_axis_dividend_tready), // output s_axis_dividend_tready
  .s_axis_dividend_tlast(s_axis_dividend_tlast), // input s_axis_dividend_tlast
  .s_axis_dividend_tdata(s_axis_dividend_tdata), // input [31 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid), // output m_axis_dout_tvalid
  .m_axis_dout_tready(m_axis_dout_tready), // input m_axis_dout_tready
  .m_axis_dout_tlast(m_axis_dout_tlast), // output m_axis_dout_tlast
  .m_axis_dout_tdata(m_axis_dout_tdata) // output [63 : 0] m_axis_dout_tdata
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file divide_int32.v when simulating
// the core, divide_int32. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

