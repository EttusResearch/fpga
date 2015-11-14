#!/bin/bash
#
# Copyright 2015 Ettus Research
#

#----------------------------------------------------------------------------
# Global defaults
#----------------------------------------------------------------------------
# Vivado specific
VIVADO_BASE_PATH="/opt/Xilinx/Vivado"

# Modelsim specific
MODELSIM_BASE_PATH="/opt/mentor/modelsim"
declare -a MODELSIM_VERSIONS
MODELSIM_VERSIONS=("DE" "SE")
declare -A MODELSIM_VER_PATHS
MODELSIM_VER_PATHS["DE"]="modelsim_dlx"
MODELSIM_VER_PATHS["SE"]="modeltech"
declare -A MODELSIM_VER_BITNESS
MODELSIM_VER_BITNESS["DE"]="32"
MODELSIM_VER_BITNESS["SE"]="64"

#----------------------------------------------------------------------------
# Validate prerequisites
#----------------------------------------------------------------------------
# Ensure required variables
if [ -z "$REPO_BASE_PATH" ]; then 
    echo "ERROR: Please define the variable REPO_BASE_PATH before calling this script"
    return 
fi
if [ -z "$VIVADO_VER" ]; then 
    echo "ERROR: Please define the variable VIVADO_VER before calling this script"
    return 
fi
if [ -z "$DEVICE_NAME" ]; then 
    echo "ERROR: Please define the variable DEVICE_NAME before calling this script"
    return 
fi

# Ensure that the script is sourced
if [[ $BASH_SOURCE = $0 ]]; then
    echo "ERROR: This script must be sourced."
    help
    exit 1
fi

#----------------------------------------------------------------------------
# Help message display function
#----------------------------------------------------------------------------
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
Optional tools: Mentor Graphics Modelsim (Simulation)

EOHELP
}

#----------------------------------------------------------------------------
# Setup and parse command line
#----------------------------------------------------------------------------
# Detect platform bitness
if [ "$(uname -m)" = "x86_64" ]; then
    BITNESS="64"
else
    BITNESS="32"
fi

# Go through cmd line options
MODELSIM_REQUESTED=0
MODELSIM_FOUND=0
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
        MODELSIM_REQUESTED=1
    ;;
    *)
        echo "ERROR: Unrecognized option: $i"
        help
        return 1
    ;;
esac
done

# Vivado environment setup
export VIVADO_PATH=$VIVADO_BASE_PATH/$VIVADO_VER

echo "Setting up a ${BITNESS}-bit FPGA build environment for the ${DEVICE_NAME}..."
#----------------------------------------------------------------------------
# Prepare Vivado environment
#----------------------------------------------------------------------------
if [ -d "$VIVADO_PATH/bin" ]; then
    echo "- Vivado: Found ($VIVADO_PATH/bin)"
else
    echo "- Vivado: Not found in $VIVADO_BASE_PATH (ERROR.. Builds and simulations will not work)"
    echo "          Use the --vivado-path option to override the search path"
    return 1
fi

$VIVADO_PATH/settings${BITNESS}.sh
$VIVADO_PATH/.settings${BITNESS}-Vivado.sh
${VIVADO_PATH/Vivado/Vivado_HLS}/.settings${BITNESS}-Vivado_High_Level_Synthesis.sh
/opt/Xilinx/DocNav/.settings${BITNESS}-DocNav.sh

#----------------------------------------------------------------------------
# Prepare Modelsim environment
#----------------------------------------------------------------------------
for i in "${MODELSIM_VERSIONS[@]}"
do
    if [ -d $MODELSIM_BASE_PATH/${MODELSIM_VER_PATHS[$i]} ]; then
        export MODELSIM_VER=$i
        export MODELSIM_PATH=$MODELSIM_BASE_PATH/${MODELSIM_VER_PATHS[$i]}/bin
        if [ ${MODELSIM_VER_BITNESS[$i]}="64" ]; then
            export MODELSIM_64BIT=1
        else
            export MODELSIM_64BIT=0
        fi
        export SIM_COMPLIBDIR=$VIVADO_PATH/modelsim${MODELSIM_VER_BITNESS[$i]}
        MODELSIM_FOUND=1
        break;
    fi
done

function build_simlibs {
    mkdir -p $SIM_COMPLIBDIR
    pushd $SIM_COMPLIBDIR
    CMD_PATH=`mktemp XXXXXXXX.vivado_simgen.tcl`
    if [ $MODELSIM_64BIT -eq 1 ]; then
        echo "compile_simlib -force -simulator modelsim -family all -language all -library all -directory $SIM_COMPLIBDIR" > $CMD_PATH
    else
        echo "compile_simlib -force -simulator modelsim -family all -language all -library all -32 -directory $SIM_COMPLIBDIR" > $CMD_PATH
    fi
    vivado -mode batch -source $CMD_PATH -nolog -nojournal
    rm -f $CMD_PATH
    popd
}

if [ $MODELSIM_FOUND -eq 1 ]; then
    echo "- Modelsim: Found ($MODELSIM_VER, ${MODELSIM_VER_BITNESS[$MODELSIM_VER]}-bit, $MODELSIM_PATH)"
    if [ -e "$SIM_COMPLIBDIR/modelsim.ini" ]; then
        echo "- Modelsim Compiled Libs: Found ($SIM_COMPLIBDIR)"
    else
        echo "- Modelsim Compiled Libs: Not found! (Run build_simlibs to generate them.)"
    fi
else
    if [ $MODELSIM_REQUESTED -eq 1 ]; then
        echo "- Modelsim: Not found in $MODELSIM_BASE_PATH (WARNING.. Simulations with vsim will not work)"
    fi
fi

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
export PATH=$(echo ${PATH} | tr ':' '\n' | awk '$0 !~ "/Vivado/"' | paste -sd:)
export PATH=${PATH}:$VIVADO_PATH:$VIVADO_PATH/bin:$MODELSIM_PATH

echo
echo "Environment successfully initialized."
return 0

# Cleanup
unset MODELSIM_VERSIONS
unset MODELSIM_VER_PATHS
unset MODELSIM_VER_BITNESS

#----------------------------------------------------------------------------
# Define hardware programming aliases
#----------------------------------------------------------------------------
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
