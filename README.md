USRP FPGA HDL Source
====================

Welcome to the USRP FPGA HDL source code tree! This repository contains
free & open-source FPGA HDL for the Universal Software Radio Peripheral
(USRP&trade;) SDR platform, created and sold by Ettus Research. Most of
the source is written in Verilog and the rest is in VHDL.

## Product Generations

#### Generation 1

* Directory: __usrp1__
* Devices: USRP Classic Only
* Tools: Quartus from Altera

#### Generation 2

* Directory: __usrp2__
* Devices: USRP N2X0, USRP B100, USRP E1X0, USRP2
* Tools: ISE from Xilinx, GNU make

#### Generation 3

* Directory: __usrp3__
* Devices: USRP B2X0, USRP X Series, USRP E3X0
* Tools: ISE from Xilinx, GNU make

## Build Instructions

### Supported Platforms

The USRP FPGA build system requires a UNIX-like environment with GNU make and
Xilinx ISE or Altera Quartus (for Gen1). Platform requirements are only imposed
by the individual FPGA build tools being used. Please look at the generation specific
tools above for more information.

### Building Generation 1 Designs

* Download and install Altera Quartus from https://www.altera.com/download/sw/dnl-sw-index.jsp
* The top-level project is located in ``usrp1/toplevel/usrp_std/``. Build it using Quartus.

### Building Generation 2 Designs

* Download and install __Xilinx ISE 12.2__ from http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/design-tools/v12_2.html
* To add xtclsh to the PATH and to setup up the Xilinx build environment run
  ``source <install dir>/Xilinx/12.2/ISE_DS/settings64.sh`` for 64-bit platforms or
  ``source <install dir>/Xilinx/12.2/ISE_DS/settings32.sh`` for 32-bit platforms.
* Navigate ``to usrp2/top/{project}`` where project is B100, E1x0, N2x0 or USRP2
* To build a binary configuration bitstream run ``make -f Makefile.<device> bin``
* The build output will be a product specific binary file in the ``usrp2/top/{project}/build``
  directory.

### Building Generation 3 Designs

* Download and install __Xilinx ISE 14.7__ from http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/design-tools/v2012_4---14_7.html
* To add xtclsh to the PATH and to setup up the Xilinx build environment run
  ``source <install dir>/Xilinx/14.7/ISE_DS/settings64.sh`` for 64-bit platforms or
  ``source <install dir>/Xilinx/14.7/ISE_DS/settings32.sh`` for 32-bit platforms.
* Navigate ``to usrp3/top/{project}`` where project is b200, x300, or e300
* To build a binary configuration bitstream run ``make <target>``
  where the target is specific to each product. To get a list of supported targets run
  ``make help``.
* The build output will be specific to the product and will be located in the
  ``usrp3/top/{project}/build`` directory. Run ``make help`` for more information.

## Customizing the HDL

### Adding DSP logic to Generation 2 products

As part of the USRP FPGA build-framework, there are several convenient places
for users to insert custom DSP modules into the transmit and receive chains.

* Before the DDC module
* After the DDC module
* Replace the DDC module
* Before the DUC module
* After the DUC module
* Replace of the DUC module
* As an RX packet engine
* As an TX packet engine

#### Customizing the top level makefile

Each USRP device has a makefile associated with it. This makefile contains all
of the necessary build rules. When making a customized FPGA design, start by
copying the current makefile for your device. Makefiles can be found in the
usrp2/top/{product}/Makefile.*

Edit your new makefile:
* Set BUILD_DIR to a unique directory name
* Set CUSTOM_SRCS for your verilog sources
* Set CUSTOM_DEFS (see section below)

#### Inserting custom modules

CUSTOM_DEFS is a string of space-separate key-value pairs. Set the CUSTOM_DEFS
variable so the FPGA fabric glue will substitute your custom modules into the
DSP chain.

Example:
```
CUSTOM_DEFS = "TX_ENG0_MODULE=my_tx_engine RX_ENG0_MODULE=my_rx_engine"
```
Where my_tx_engine and my_rx_engine are the names of custom verilog modules.

The following module definition keys are possible (X is a DSP number):

* ``TX_ENG<X>_MODULE``: Set the module for the transmit chain engine.
* ``RX_ENG<X>_MODULE``: Set the module for the receive chain engine.
* ``RX_DSP<X>_MODULE``: Set the module for the transmit dsp chain.
* ``TX_DSP<X>_MODULE``: Set the module for the receive dsp chain.

Examples of custom modules can be found in usrp2/custom/*.v
