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
*     Generated from core with identifier: xilinx.com:ip:xfft:8.0              *
*                                                                              *
*     The Fast Fourier Transform (FFT) is a computationally efficient          *
*     algorithm for computing the Discrete Fourier Transform (DFT). The FFT    *
*     Core can compute 8 to 65536-point forward or inverse complex             *
*     transforms on up to 12 parallel channels. The input data is a vector     *
*     of complex values represented as two's-complement numbers 8 to 34        *
*     bits wide or single precision floating point numbers 32 bits wide.       *
*     The phase factors can be 8 to 34 bits wide. All memory is on-chip        *
*     using either Block RAM or Distributed RAM. Three arithmetic types are    *
*     available: full-precision unscaled, scaled fixed-point, and              *
*     block-floating point. Several parameters are run-time configurable:      *
*     the point size, the choice of forward or inverse transform, and the      *
*     scaling schedule. Four architectures are available to provide a          *
*     tradeoff between size and transform time.                                *
*******************************************************************************/

// Interfaces:
//    event_frame_started_intf
//    event_tlast_unexpected_intf
//    event_tlast_missing_intf
//    event_fft_overflow_intf
//    event_status_channel_halt_intf
//    event_data_in_channel_halt_intf
//    event_data_out_channel_halt_intf
//    S_AXIS_DATA
//    aclk_intf
//    aresetn_intf
//    aclken_intf
//    M_AXIS_STATUS
//    M_AXIS_DATA
//    S_AXIS_CONFIG

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
streaming_fft your_instance_name (
  .aclk(aclk), // input aclk
  .aresetn(aresetn), // input aresetn
  .s_axis_config_tdata(s_axis_config_tdata), // input [23 : 0] s_axis_config_tdata
  .s_axis_config_tvalid(s_axis_config_tvalid), // input s_axis_config_tvalid
  .s_axis_config_tready(s_axis_config_tready), // output s_axis_config_tready
  .s_axis_data_tdata(s_axis_data_tdata), // input [31 : 0] s_axis_data_tdata
  .s_axis_data_tvalid(s_axis_data_tvalid), // input s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready), // output s_axis_data_tready
  .s_axis_data_tlast(s_axis_data_tlast), // input s_axis_data_tlast
  .m_axis_data_tdata(m_axis_data_tdata), // output [31 : 0] m_axis_data_tdata
  .m_axis_data_tuser(m_axis_data_tuser), // output [15 : 0] m_axis_data_tuser
  .m_axis_data_tvalid(m_axis_data_tvalid), // output m_axis_data_tvalid
  .m_axis_data_tready(m_axis_data_tready), // input m_axis_data_tready
  .m_axis_data_tlast(m_axis_data_tlast), // output m_axis_data_tlast
  .event_frame_started(event_frame_started), // output event_frame_started
  .event_tlast_unexpected(event_tlast_unexpected), // output event_tlast_unexpected
  .event_tlast_missing(event_tlast_missing), // output event_tlast_missing
  .event_status_channel_halt(event_status_channel_halt), // output event_status_channel_halt
  .event_data_in_channel_halt(event_data_in_channel_halt), // output event_data_in_channel_halt
  .event_data_out_channel_halt(event_data_out_channel_halt) // output event_data_out_channel_halt
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file streaming_fft.v when simulating
// the core, streaming_fft. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

