###############################################################################
# Pin mapping for motherboard components
###############################################################################

### Other I/O
set_property PACKAGE_PIN A22 [get_ports AVR_CS_R]
set_property IOSTANDARD LVCMOS33 [get_ports AVR_CS_R]
set_property PACKAGE_PIN B22 [get_ports AVR_IRQ]
set_property IOSTANDARD LVCMOS33 [get_ports AVR_IRQ]
set_property PACKAGE_PIN C22 [get_ports AVR_MISO_R]
set_property IOSTANDARD LVCMOS33 [get_ports AVR_MISO_R]
set_property PACKAGE_PIN A21 [get_ports AVR_MOSI_R]
set_property IOSTANDARD LVCMOS33 [get_ports AVR_MOSI_R]
set_property PACKAGE_PIN D22 [get_ports AVR_SCK_R]
set_property IOSTANDARD LVCMOS33 [get_ports AVR_SCK_R]

set_property PACKAGE_PIN E21 [get_ports ONSWITCH_DB]
set_property IOSTANDARD LVCMOS33 [get_ports ONSWITCH_DB]

set_property PACKAGE_PIN Y9 [get_ports GPS_PPS]
set_property IOSTANDARD LVCMOS18 [get_ports GPS_PPS]

set_property PACKAGE_PIN D18 [get_ports PPS_EXT_IN]
set_property IOSTANDARD LVCMOS33 [get_ports PPS_EXT_IN]

set_property PACKAGE_PIN E16 [get_ports {PL_GPIO[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[0]}]
set_property PACKAGE_PIN C18 [get_ports {PL_GPIO[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[1]}]
set_property PACKAGE_PIN D17 [get_ports {PL_GPIO[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[2]}]
set_property PACKAGE_PIN D16 [get_ports {PL_GPIO[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[3]}]
set_property PACKAGE_PIN D15 [get_ports {PL_GPIO[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[4]}]
set_property PACKAGE_PIN E15 [get_ports {PL_GPIO[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PL_GPIO[5]}]
set_property PULLDOWN TRUE [get_ports {PL_GPIO*}]
