#!/bin/bash
#

function help {
	cat <<EOHELP

Usage: source setupenv.sh [--help|-h] [--vivado-path=<PATH>] [--modelsim-path=<PATH>]

--help -h       - Shows this.
--vivado-path   - Path to the base install directory for Xilinx Vivado
                  (Default: /opt/Xilinx/Vivado)
--modelsim-path - Path to the base install directory for Modelsim (optional simulation tool)
                  (Default: /opt/mentor/modelsim)

This script sets up the environment required to build FPGA images for the Ettus Research
USRP-X300 and USRP-X310. It will also optionally set up the the environment to run the
Modelsim simulator (although this tool is not required).

Required Xilinx tools: Vivado $VIVADO_VER

EOHELP
}

# Global defaults
VIVADO_BASE_PATH="/opt/Xilinx/Vivado"
MODELSIM_BASE_PATH="/opt/mentor/modelsim"
VIVADO_VER=2014.4
MODELSIM_REQUESTED=0
# Go through cmd line options
for i in "$@"
do
case $i in
    -h|--help)
        help
        return
        ;;
    --vivado-path=*)
    VIVADO_BASE_PATH="${i#*=}"
    ;;
    --modelsim-path=*)
    MODELSIM_BASE_PATH="${i#*=}"
    MODELSIM_REQUESTED=1
    ;;
    *)
        echo Unrecognized option: $i
        echo
        help
        exit
        break
        ;;
esac
done

echo "Setting up X3x0 FPGA build environment..."

# Vivado environment setup
export VIVADO_PATH=$VIVADO_BASE_PATH/$VIVADO_VER

$VIVADO_PATH/settings64.sh
$VIVADO_PATH/.settings64-Vivado.sh
${VIVADO_PATH/Vivado/Vivado_HLS}/.settings64-Vivado_High_Level_Synthesis.sh
/opt/Xilinx/DocNav/.settings64-DocNav.sh

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
    if [ "$MODELSIM_REQUESTED" -eq 1 ]; then
        echo "- Modelsim: Not found! (WARNING.. Simulations with vsim will not work)"
    fi
fi

echo "Environment successfully initialized."
return 0
