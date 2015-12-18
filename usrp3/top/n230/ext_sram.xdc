#
# We constrain RAM_CLK to work at 125MHz to be conservative
#
create_generated_clock -name RAM_CLK -source [get_ports SFPX_CLK_P] -multiply_by 1 [get_ports RAM_CLK]
# No real path from RAM_CLK to internal clock(s)
set_clock_groups -group [get_clocks RAM_CLK] -group  [get_clocks bus_clk] -asynchronous

set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_D*]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_D*]
set_input_delay -clock [get_clocks RAM_CLK] -max 4.8 [get_ports RAM_D*]
set_input_delay -clock [get_clocks RAM_CLK] -min -1.5 [get_ports RAM_D*]

set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_A*]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_A*]

set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_CENn]
set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_WEn]
set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_OEn]
set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_LDn]
set_output_delay -clock [get_clocks RAM_CLK] -max 1.5 [get_ports RAM_CE1n]

set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_CENn]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_WEn]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_OEn]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_LDn]
set_output_delay -clock [get_clocks RAM_CLK] -min -0.5 [get_ports RAM_CE1n]

#
# Ext SRAM
#
set_property IOSTANDARD LVCMOS25 [get_ports RAM_*]

set_property IOB TRUE [get_ports RAM_D*]
set_property DRIVE 8 [get_ports RAM_D*]

set_property PACKAGE_PIN H20 [get_ports RAM_D[35]]
set_property PACKAGE_PIN J17 [get_ports RAM_D[34]]
set_property PACKAGE_PIN H22 [get_ports RAM_D[33]]
set_property PACKAGE_PIN K17 [get_ports RAM_D[32]]
set_property PACKAGE_PIN J22 [get_ports RAM_D[31]]
set_property PACKAGE_PIN K21 [get_ports RAM_D[30]]
set_property PACKAGE_PIN K22 [get_ports RAM_D[29]]
set_property PACKAGE_PIN L18 [get_ports RAM_D[28]]
set_property PACKAGE_PIN L21 [get_ports RAM_D[27]]
set_property PACKAGE_PIN N18 [get_ports RAM_D[26]]
set_property PACKAGE_PIN M20 [get_ports RAM_D[25]]
set_property PACKAGE_PIN M21 [get_ports RAM_D[24]]
set_property PACKAGE_PIN M22 [get_ports RAM_D[23]]
set_property PACKAGE_PIN M18 [get_ports RAM_D[22]]
set_property PACKAGE_PIN M17 [get_ports RAM_D[21]]
set_property PACKAGE_PIN N22 [get_ports RAM_D[20]]
set_property PACKAGE_PIN N20 [get_ports RAM_D[19]]
set_property PACKAGE_PIN N19 [get_ports RAM_D[18]]
set_property PACKAGE_PIN G20 [get_ports RAM_D[17]]
set_property PACKAGE_PIN H18 [get_ports RAM_D[16]]
set_property PACKAGE_PIN G18 [get_ports RAM_D[15]]
set_property PACKAGE_PIN H17 [get_ports RAM_D[14]]
set_property PACKAGE_PIN G17 [get_ports RAM_D[13]]
set_property PACKAGE_PIN J16 [get_ports RAM_D[12]]
set_property PACKAGE_PIN G16 [get_ports RAM_D[11]]
set_property PACKAGE_PIN H15 [get_ports RAM_D[10]]
set_property PACKAGE_PIN G15 [get_ports RAM_D[9]]
set_property PACKAGE_PIN M13 [get_ports RAM_D[8]]
set_property PACKAGE_PIN L13 [get_ports RAM_D[7]]
set_property PACKAGE_PIN K13 [get_ports RAM_D[6]]
set_property PACKAGE_PIN H13 [get_ports RAM_D[5]]
set_property PACKAGE_PIN G13 [get_ports RAM_D[4]]
set_property PACKAGE_PIN J14 [get_ports RAM_D[3]]
set_property PACKAGE_PIN H14 [get_ports RAM_D[2]]
set_property PACKAGE_PIN K14 [get_ports RAM_D[1]]
set_property PACKAGE_PIN J15 [get_ports RAM_D[0]]
#
# Top 3 Address bits ied low in FPGA
#
set_property PACKAGE_PIN D22 [get_ports RAM_A[20]]
set_property PACKAGE_PIN D21 [get_ports RAM_A[19]]
set_property PACKAGE_PIN B22 [get_ports RAM_A[18]]
set_property PACKAGE_PIN G21 [get_ports RAM_A[17]]
set_property PACKAGE_PIN F20 [get_ports RAM_A[16]]
set_property PACKAGE_PIN F19 [get_ports RAM_A[15]]
set_property PACKAGE_PIN E22 [get_ports RAM_A[14]]
set_property PACKAGE_PIN D20 [get_ports RAM_A[13]]
set_property PACKAGE_PIN C22 [get_ports RAM_A[12]]
set_property PACKAGE_PIN C20 [get_ports RAM_A[11]]
set_property PACKAGE_PIN B21 [get_ports RAM_A[10]]
set_property PACKAGE_PIN B20 [get_ports RAM_A[9]]
set_property PACKAGE_PIN A19 [get_ports RAM_A[8]]
set_property PACKAGE_PIN A13 [get_ports RAM_A[7]]
set_property PACKAGE_PIN A18 [get_ports RAM_A[6]]
set_property PACKAGE_PIN A20 [get_ports RAM_A[5]]
set_property PACKAGE_PIN A21 [get_ports RAM_A[4]]
set_property PACKAGE_PIN F18 [get_ports RAM_A[3]]
set_property PACKAGE_PIN G22 [get_ports RAM_A[2]]
set_property PACKAGE_PIN E21 [get_ports RAM_A[1]]
set_property PACKAGE_PIN E18 [get_ports RAM_A[0]]
set_property DRIVE 8 [get_ports RAM_A*]
set_property IOB TRUE [get_ports RAM_A[17]]
set_property IOB TRUE [get_ports RAM_A[16]]
set_property IOB TRUE [get_ports RAM_A[15]]
set_property IOB TRUE [get_ports RAM_A[14]]
set_property IOB TRUE [get_ports RAM_A[13]]
set_property IOB TRUE [get_ports RAM_A[12]]
set_property IOB TRUE [get_ports RAM_A[11]]
set_property IOB TRUE [get_ports RAM_A[10]]
set_property IOB TRUE [get_ports RAM_A[9]]
set_property IOB TRUE [get_ports RAM_A[8]]
set_property IOB TRUE [get_ports RAM_A[7]]
set_property IOB TRUE [get_ports RAM_A[6]]
set_property IOB TRUE [get_ports RAM_A[5]]
set_property IOB TRUE [get_ports RAM_A[4]]
set_property IOB TRUE [get_ports RAM_A[3]]
set_property IOB TRUE [get_ports RAM_A[2]]
set_property IOB TRUE [get_ports RAM_A[1]]
set_property IOB TRUE [get_ports RAM_A[0]]
#
# These pins tied low in FPGA
#
set_property DRIVE 4 [get_ports RAM_BWn*]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_BW*]
set_property PACKAGE_PIN D14 [get_ports RAM_BWn[3]]
set_property PACKAGE_PIN B16 [get_ports RAM_BWn[2]]
set_property PACKAGE_PIN A16 [get_ports RAM_BWn[1]]
set_property PACKAGE_PIN B15 [get_ports RAM_BWn[0]]
#
# These pins tied low in FPGA
#
set_property DRIVE 4  [get_ports RAM_ZZ]
set_property PACKAGE_PIN J19 [get_ports RAM_ZZ]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_ZZ]
#
# These pins tied low in FPGA
#
set_property DRIVE 4  [get_ports RAM_LDn]
set_property PACKAGE_PIN B13 [get_ports RAM_LDn]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_LDn]
#
# These pins tied low in FPGA
#
set_property DRIVE 4  [get_ports RAM_OEn]
set_property PACKAGE_PIN A14 [get_ports RAM_OEn]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_OEn]
#
#
#
set_property DRIVE 8 [get_ports RAM_WEn]
set_property IOB TRUE [get_ports RAM_WEn]
set_property PACKAGE_PIN A15 [get_ports RAM_WEn]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_WEn]
#
#  These pins tied low in FPGA
#
set_property PACKAGE_PIN C13 [get_ports RAM_CENn]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_CENn]
#
#
#
set_property DRIVE 8 [get_ports RAM_CE1n]
set_property IOB TRUE [get_ports RAM_CE1n]
set_property PACKAGE_PIN D15 [get_ports RAM_CE1n]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_CE1n]
#
# This pins uses ODDR cell...implicitly in IOB
#
set_property DRIVE 8 [get_ports RAM_CLK]
set_property PACKAGE_PIN J20 [get_ports RAM_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports RAM_CLK]
