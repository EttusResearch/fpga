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
*     Generated from core with identifier: xilinx.com:ip:cordic:5.0            *
*                                                                              *
*     The Xilinx CORDIC LogiCORE is a module for generation of the             *
*     generalized coordinate rotational digital computer (CORDIC) algorithm    *
*     which iteratively solves trigonometric, hyperbolic and square root       *
*     equations. The core is fully synchronous using a single clock and has    *
*     AXI4 Stream compliant interfaces. Options include parameterizable        *
*     data width. The core supports either serial architecture for minimal     *
*     area implementations, or parallel architecture for speed                 *
*     optimization. The core is delivered through the Xilinx CORE Generator    *
*     System and integrates seamlessly with the Xilinx design flow.            *
*******************************************************************************/

// Interfaces:
//    S_AXIS_CARTESIAN
//    aclk_intf
//    aresetn_intf
//    aclken_intf
//    S_AXIS_PHASE
//    M_AXIS_DOUT

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
complex_to_magphase your_instance_name (
  .aclk(aclk), // input aclk
  .aresetn(aresetn), // input aresetn
  .s_axis_cartesian_tvalid(s_axis_cartesian_tvalid), // input s_axis_cartesian_tvalid
  .s_axis_cartesian_tready(s_axis_cartesian_tready), // output s_axis_cartesian_tready
  .s_axis_cartesian_tlast(s_axis_cartesian_tlast), // input s_axis_cartesian_tlast
  .s_axis_cartesian_tdata(s_axis_cartesian_tdata), // input [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid), // output m_axis_dout_tvalid
  .m_axis_dout_tready(m_axis_dout_tready), // input m_axis_dout_tready
  .m_axis_dout_tlast(m_axis_dout_tlast), // output m_axis_dout_tlast
  .m_axis_dout_tdata(m_axis_dout_tdata) // output [31 : 0] m_axis_dout_tdata
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file complex_to_magphase.v when simulating
// the core, complex_to_magphase. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

