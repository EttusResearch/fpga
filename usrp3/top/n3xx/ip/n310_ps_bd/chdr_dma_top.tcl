set scriptDir [file dirname [info script]]

source "$scriptDir/chdr_dma_rx.tcl"
source "$scriptDir/chdr_dma_tx.tcl"

# Hierarchical cell: dma
proc create_hier_cell_dma { parentCell nameHier numPorts } {

  if { $parentCell eq "" || $nameHier eq "" || $numPorts eq "" } {
     puts "ERROR: create_hier_cell_dma() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  if { $numPorts < 2 } {
     puts "ERROR: numPorts invalid: $numPorts"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  #########################
  # Pin list
  #########################
  create_bd_intf_pin -mode Master -vlnv ettus.com:interfaces:chdr_rtl:1.0 o_cvita_dma
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_RX_DMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_TX_DMA
  create_bd_intf_pin -mode Slave -vlnv ettus.com:interfaces:chdr_rtl:1.0 i_cvita_dma
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_rx_dmac
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_tx_dmac
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_regfile
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_dma_rx_mapper

  create_bd_pin -dir I bus_clk
  create_bd_pin -dir I bus_rstn
  create_bd_pin -dir I clk40
  create_bd_pin -dir I clk40_rstn
  create_bd_pin -dir O rx_irq
  create_bd_pin -dir O tx_irq

  #########################
  # Instantiate IPs
  #########################
  # Create instance: rx
  create_hier_cell_rx_dma $hier_obj rx $numPorts

  # Create instance: tx
  create_hier_cell_tx_dma $hier_obj tx $numPorts

  set axis_to_cvita_0 [ create_bd_cell -type ip -vlnv ettus.com:ip:axis_to_cvita:1.0 axis_to_cvita_0]

  # Used to set frame size of RX DMA engines
  set axi_regfile_0 [ create_bd_cell -type ip -vlnv ettus.com:ip:axi_regfile:1.0 axi_regfile_0 ]
  set_property -dict [ list \
CONFIG.NUM_REGS $numPorts \
 ] $axi_regfile_0

  set ps_dma_rx_mapper [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 ps_dma_rx_mapper ]
  set_property -dict [ list \
CONFIG.ECC_TYPE {0} \
CONFIG.PROTOCOL {AXI4LITE} \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $ps_dma_rx_mapper

  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {4} \
 ] $xlslice_0

  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {3} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {32} \
CONFIG.DOUT_WIDTH {4} \
 ] $xlslice_1

  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {9} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {12} \
CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_3

  set cvita_dest_lookup_0 [ create_bd_cell -type ip -vlnv ettus.com:ip:cvita_dest_lookup:1.0 cvita_dest_lookup_0 ]

  set cvita_to_axis_0 [ create_bd_cell -type ip -vlnv ettus.com:ip:cvita_to_axis:1.0 cvita_to_axis_0 ]

  set util_reduced_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 util_reduced_logic_0 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {or} \
CONFIG.C_SIZE $numPorts \
 ] $util_reduced_logic_0

  set util_reduced_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 util_reduced_logic_1 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {or} \
CONFIG.C_SIZE $numPorts \
 ] $util_reduced_logic_1

  #########################
  # Wiring
  #########################
  # Clocks and resets
  connect_bd_net -net bus_clk_1 \
     [get_bd_pins bus_clk] \
     [get_bd_pins cvita_dest_lookup_0/clk] \
     [get_bd_pins cvita_to_axis_0/clk] \
     [get_bd_pins axis_to_cvita_0/clk] \
     [get_bd_pins ps_dma_rx_mapper/s_axi_aclk] \
     [get_bd_pins rx/bus_clk] \
     [get_bd_pins tx/bus_clk]
  connect_bd_net -net bus_rstn_1 \
     [get_bd_pins bus_rstn] \
     [get_bd_pins ps_dma_rx_mapper/s_axi_aresetn] \
     [get_bd_pins rx/bus_rstn] \
     [get_bd_pins tx/bus_rstn]
  connect_bd_net -net clk40_1 \
     [get_bd_pins clk40] \
     [get_bd_pins rx/clk40] \
     [get_bd_pins tx/clk40] \
     [get_bd_pins axi_regfile_0/S_AXI_ACLK] 
  connect_bd_net -net clk40_rstn_1 \
     [get_bd_pins clk40_rstn] \
     [get_bd_pins axi_regfile_0/S_AXI_ARESETN] \
     [get_bd_pins rx/clk40_rstn] \
     [get_bd_pins tx/clk40_rstn]

  # AXI buses
  connect_bd_intf_net -intf_net s_axi_rx_dmac_1 \
     [get_bd_intf_pins s_axi_rx_dmac] \
     [get_bd_intf_pins rx/s_axi_rx_dmac]
  connect_bd_intf_net -intf_net rx_dma_M_AXI_RX_DMA \
     [get_bd_intf_pins M_AXI_RX_DMA] \
     [get_bd_intf_pins rx/M_AXI_RX_DMA]
  connect_bd_intf_net -intf_net s_axi_tx_dmac_1 \
     [get_bd_intf_pins s_axi_tx_dmac] \
     [get_bd_intf_pins tx/s_axi_tx_dmac]
  connect_bd_intf_net -intf_net tx_M_AXI_TX_DMA \
     [get_bd_intf_pins M_AXI_TX_DMA] \
     [get_bd_intf_pins tx/M_AXI_TX_DMA]
  connect_bd_intf_net -intf_net s_axi_regfile_1 \
     [get_bd_intf_pins s_axi_regfile] \
     [get_bd_intf_pins axi_regfile_0/S_AXI]
  connect_bd_intf_net -intf_net s_axi_dma_rx_mapper_1 \
     [get_bd_intf_pins s_axi_dma_rx_mapper] \
     [get_bd_intf_pins ps_dma_rx_mapper/S_AXI]

  # RX CHDR chain
  connect_bd_intf_net -intf_net i_cvita_dma_1 \
     [get_bd_intf_pins i_cvita_dma] \
     [get_bd_intf_pins cvita_dest_lookup_0/i]
  connect_bd_intf_net -intf_net cvita_dest_lookup_0_o \
     [get_bd_intf_pins cvita_dest_lookup_0/o] \
     [get_bd_intf_pins cvita_to_axis_0/i]
  connect_bd_intf_net -intf_net cvita_to_axis_m_axis \
     [get_bd_intf_pins cvita_to_axis_0/m_axis] \
     [get_bd_intf_pins rx/S_AXIS_DMA]
  connect_bd_net -net cvita_dest_lookup_dest \
     [get_bd_pins cvita_dest_lookup_0/o_tdest] \
     [get_bd_pins rx/s_axis_tdest]

  # TX CHDR
  connect_bd_intf_net -intf_net tx_M_AXIS_DMA \
     [get_bd_intf_pins tx/M_AXIS_DMA] \
     [get_bd_intf_pins axis_to_cvita_0/s_axis]
  connect_bd_intf_net -intf_net o_cvita_dma_1 \
     [get_bd_intf_pins axis_to_cvita_0/o] \
     [get_bd_intf_pins o_cvita_dma]

  # BRAM ctrl -> cvita_dest
  connect_bd_net -net axi_bram_ctrl_0_bram_rst_a \
     [get_bd_pins cvita_dest_lookup_0/rst] \
     [get_bd_pins ps_dma_rx_mapper/bram_rst_a]
  connect_bd_net -net axi_bram_ctrl_0_bram_we_a \
     [get_bd_pins ps_dma_rx_mapper/bram_we_a] \
     [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axi_bram_ctrl_0_bram_wrdata_a \
     [get_bd_pins ps_dma_rx_mapper/bram_wrdata_a] \
     [get_bd_pins xlslice_1/Din]
  connect_bd_net -net ps_dma_rx_mapper_bram_addr_a \
     [get_bd_pins ps_dma_rx_mapper/bram_addr_a] \
     [get_bd_pins xlslice_3/Din]
  connect_bd_net -net cvita_dest_set_addr \
     [get_bd_pins cvita_dest_lookup_0/set_addr] \
     [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net cvita_set_data \
     [get_bd_pins cvita_dest_lookup_0/set_data] \
     [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net cvita_set_stb \
     [get_bd_pins cvita_dest_lookup_0/set_stb] \
     [get_bd_pins xlslice_0/Dout]

  # IRQs and Frame Sizes
  connect_bd_net -net frame_sizes \
     [get_bd_pins axi_regfile_0/regs] \
     [get_bd_pins rx/mtu_regs]
  connect_bd_net -net rx_irq1 \
     [get_bd_pins rx/irq] \
     [get_bd_pins util_reduced_logic_0/Op1]
  connect_bd_net -net tx_irq1 \
     [get_bd_pins tx/irq] \
     [get_bd_pins util_reduced_logic_1/Op1]
  connect_bd_net -net util_reduced_logic_0_Res \
     [get_bd_pins rx_irq] \
     [get_bd_pins util_reduced_logic_0/Res]
  connect_bd_net -net util_reduced_logic_1_Res \
     [get_bd_pins tx_irq] \
     [get_bd_pins util_reduced_logic_1/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}


