# Generation 3 USRP Build Documentation

## Dependencies and Requirements

### Dependencies

The USRP FPGA build system requires a UNIX-like environment with the following dependencies

- [Xilinx ISE 14.7](http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/design-tools/v2012_4---14_7.html)
- [GNU Make](https://www.gnu.org/software/make/)
- (Recommended) [GNU Bash](https://www.gnu.org/software/bash/)

### Requirements

- [Xilinx ISE Platform Requirements](http://www.xilinx.com/support/documentation/sw_manuals/xilinx14_7/irn.pdf)

### What FPGA does my USRP have?

- USRP B200: Spartan 6 XC6SLX75
- USRP B210: Spartan 6 XC6SLX150
- USRP X300: Kintex 7 XC7K325T
- USRP X310: Kintex 7 XC7K410T
- USRP E310: Zynq-7000 XC7Z020

## Build Instructions

- Download and install [Xilinx ISE 14.7](http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/design-tools/v2012_4---14_7.html)
  + You may need to acquire an implementation license to build some USRP designs.
    Please check the Xilinx Requirements document above for the FPGA technology used by your USRP device.

- To add xtclsh to the PATH and to setup up the Xilinx build environment run
  + `source <install_dir>/Xilinx/14.7/ISE_DS/settings64.sh` (64-bit platform)
  + `source <install_dir>/Xilinx/14.7/ISE_DS/settings32.sh` (32-bit platform)

- Navigate to `usrp3/top/{project}` where project is:
  + b200: For USRP B200 and USRP B210
  + x300: For USRP X300 and USRP X310
  + e300: For USRP E310

- To build a binary configuration bitstream run `make <target>`
  where the target is specific to each product. To get a list of supported targets run
  `make help`.

- The build output will be specific to the product and will be located in the
  `usrp3/top/{project}/build` directory. Run `make help` for more information.

### B2x0 Targets and Outputs

#### Supported Targets
- B200:  Builds the USRP B200 design.
- B210:  Builds the USRP B210 design.

#### Outputs
- `build/usrp_<product>_fpga.bit` : Configuration bitstream with header
- `build/usrp_<product>_fpga.bin` : Configuration bitstream without header
- `build/usrp_<product>_fpga.syr` : Xilinx system report
- `build/usrp_<product>_fpga.twr` : Xilinx timing report

### X3x0 Targets and Outputs

#### Supported Targets
- X310_1G:  USRP X310. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
- X300_1G:  USRP X300. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
- X310_HG:  USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
- X300_HG:  USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
- X310_XG:  USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
- X300_XG:  USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
- X310_HGS: USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
- X300_HGS: USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
- X310_XGS: USRP X310. 10GigE on both SFP+ ports. SRAM TX FIFO.
- X300_XGS: USRP X300. 10GigE on both SFP+ ports. SRAM TX FIFO.

#### Outputs
- `build/usrp_<product>_fpga_<image_type>.bit` :    Configuration bitstream with header
- `build/usrp_<product>_fpga_<image_type>.bin` :    Configuration bitstream without header
- `build/usrp_<product>_fpga_<image_type>.lvbitx` : Configuration bitstream for PCIe (NI-RIO)
- `build/usrp_<product>_fpga_<image_type>.syr` :    Xilinx system report
- `build/usrp_<product>_fpga_<image_type>.twr` :    Xilinx timing report

### E310 Targets and Outputs

#### Supported Targets
- E310:  Builds the USRP E310 design.

#### Outputs
- `build/usrp_<product>_fpga.bit` : Configuration bitstream with header
- `build/usrp_<product>_fpga.bin` : Configuration bitstream without header
- `build/usrp_<product>_fpga.syr` : Xilinx system report
- `build/usrp_<product>_fpga.twr` : Xilinx timing report

### Additional Build Options

It is possible to make a target and specific additional options in the form VAR=VALUE in
the command. For example: `make B210 PROJECT_ONLY=1`

Here are the supported options:

- `PROJECT_ONLY=1` : Only create a Xilinx project for the specified target(s). Useful for use with the ISE GUI.
- `EXPORT_ONLY=1` :  Export build targets from a GUI build to the build directory. Requires the project in build-\*_\* to be built.

