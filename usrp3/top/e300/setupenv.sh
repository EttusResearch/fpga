#!/bin/bash
#

function help {
    cat <<EOHELP

Usage: source setupenv.sh [--help|-h] [--vivado-path=<PATH>] [--modelsim-path=<PATH>]

--vivado-path   : Path to the base install directory for Xilinx Vivado
                  (Default: /opt/Xilinx/Vivado)
--modelsim-path : Path to the base install directory for Modelsim (optional simulation tool)
                  (Default: /opt/mentor/modelsim)
--help -h       : Shows this message.

This script sets up the environment required to build FPGA images for the Ettus Research
${DEVICE_NAME}. It will also optionally set up the the environment to run the
Modelsim simulator (although this tool is not required).

Required tools: Xilinx Vivado $VIVADO_VER (Synthesis and Simulation)
Optional toold: Mentor Graphics Modelsim (Simulation)

EOHELP
}

# Global defaults
VIVADO_BASE_PATH="/opt/Xilinx/Vivado"
MODELSIM_BASE_PATH="/opt/mentor/modelsim"
VIVADO_VER=2015.2
DEVICE_NAME="USRP-E3xx"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Go through cmd line options
_MODELSIM_REQUESTED=0
for i in "$@"
do
case $i in
    -h|--help)
        help
        return 0
        ;;
    --vivado-path=*)
        VIVADO_BASE_PATH="${i#*=}"
    ;;
    --modelsim-path=*)
        MODELSIM_BASE_PATH="${i#*=}"
        _MODELSIM_REQUESTED=1
    ;;
    *)
        echo "ERROR: Unrecognized option: $i"
        help
        return 1
    ;;
esac
done

# Ensure that the script is sourced
if [[ $BASH_SOURCE = $0 ]]; then
    echo "ERROR: This script must be sourced."
    help
    exit 1
fi

# Vivado environment setup
export VIVADO_PATH=$VIVADO_BASE_PATH/$VIVADO_VER

# Detect platform bitness
if [ "$(uname -m)" = "x86_64" ]; then
    BITNESS="64"
else
    BITNESS="32"
fi

# Source Xilinx scripts
echo "Setting up E3xx FPGA build environment (${BITNESS}-bit)..."
$VIVADO_PATH/settings${BITNESS}.sh
$VIVADO_PATH/.settings${BITNESS}-Vivado.sh
${VIVADO_PATH/Vivado/Vivado_HLS}/.settings${BITNESS}-Vivado_High_Level_Synthesis.sh
/opt/Xilinx/DocNav/.settings${BITNESS}-DocNav.sh

# Optional Modelsim environment setup
export MODELSIM_PATH=$MODELSIM_BASE_PATH/modeltech/bin
export SIM_COMPLIBDIR=$VIVADO_PATH/modelsim

function build_simlibs {
    mkdir -p $VIVADO_PATH/modelsim
    pushd $VIVADO_PATH/modelsim
    CMD_PATH=`mktemp XXXXXXXX.vivado_simgen.tcl`
    echo "compile_simlib -force -simulator modelsim -family all -language all -library all -directory $VIVADO_PATH/modelsim" > $CMD_PATH
    vivado -mode batch -source $CMD_PATH -nolog -nojournal
    rm -f $CMD_PATH
    popd
}

VIV_HW_UTILS=$REPO_BASE_PATH/tools/scripts/viv_hardware_utils.tcl

function viv_hw_console {
    vivado -mode tcl -source $VIV_HW_UTILS -nolog -nojournal
}

function viv_jtag_list {
    vivado -mode batch -source $VIV_HW_UTILS -nolog -nojournal -tclargs list | grep -v -E '(^$|^#|\*\*)'
}

function viv_jtag_program {
    if [ "$1" == "" ]; then
        echo "Downloads a bitfile to an FPGA device using Vivado"
        echo ""
        echo "Usage: viv_jtag_program <Bitfile Path> [<Device Address> = 0:0]"
        echo "- <Bitfile Path>: Path to a .bit FPGA configuration file"
        echo "- <Device Address>: Address to the device in the form <Target>:<Device>"
        echo "                    Run viv_jtag_list to get a list of connected devices"
        return
    fi
    if [ "$2" == "" ]; then
        vivado -mode batch -source $VIV_HW_UTILS -nolog -nojournal -tclargs program $1 | grep -v -E '(^$|^#|\*\*)'
    else
        vivado -mode batch -source $VIV_HW_UTILS -nolog -nojournal -tclargs program $1 $2 | grep -v -E '(^$|^#|\*\*)'
    fi
}

# Update PATH
export PATH=$(echo ${PATH} | tr ':' '\n' | awk '$0 !~ "/Vivado/"' | paste -sd:)
export PATH=${PATH}:$VIVADO_PATH:$VIVADO_PATH/bin:$MODELSIM_PATH

# Sanity checks
if [ -d "$VIVADO_PATH/bin" ]; then
    echo "- Vivado: Found ($VIVADO_PATH/bin)"
else
    echo "- Vivado: Not found! (ERROR.. Builds and simulations will not work)"
    return 1
fi
if [ -d "$MODELSIM_PATH" ]; then
    echo "- Modelsim: Found ($MODELSIM_PATH)"
    if [ -e "$VIVADO_PATH/modelsim/modelsim.ini" ]; then
        echo "- Modelsim Compiled Libs: Found ($VIVADO_PATH/modelsim)"
    else
        echo "- Modelsim Compiled Libs: Not found! (Run build_simlibs to generate them.)"
    fi
else
    if [ "$_MODELSIM_REQUESTED" -eq 1 ]; then
        echo "- Modelsim: Not found! (WARNING.. Simulations with vsim will not work)"
    fi
fi

echo
echo "Environment successfully initialized."
return 0
