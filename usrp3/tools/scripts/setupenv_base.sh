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
if [ -z "$DISPLAY_NAME" ]; then 
    echo "ERROR: Please define the variable DISPLAY_NAME before calling this script"
    return 
fi
if [ ${#PRODUCT_ID_MAP[@]} -eq 0 ]; then 
    echo "ERROR: Please define the variable PRODUCT_ID_MAP before calling this script"
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
${DISPLAY_NAME}. It will also optionally set up the the environment to run the
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

echo "Setting up a ${BITNESS}-bit FPGA build environment for the ${DISPLAY_NAME}..."
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
# Misc export variables
#----------------------------------------------------------------------------
export PATH=$(echo ${PATH} | tr ':' '\n' | awk '$0 !~ "/Vivado/"' | paste -sd:)
export PATH=${PATH}:$VIVADO_PATH:$VIVADO_PATH/bin:$MODELSIM_PATH

for prod in "${!PRODUCT_ID_MAP[@]}"; do
    IFS='/' read -r -a prod_tokens <<< "${PRODUCT_ID_MAP[$prod]}"
    if [ ${#prod_tokens[@]} -eq 4 ]; then 
        export XIL_ARCH_${prod}=${prod_tokens[0]}
        export XIL_PART_ID_${prod}=${prod_tokens[1]}/${prod_tokens[2]}/${prod_tokens[3]}
    else
        echo "ERROR: Invalid PRODUCT_ID_MAP entry: \"${PRODUCT_ID_MAP[$prod]}\". Must be <arch>/<part>/<pkg>/<sg>."
        return 1 
    fi
done

#----------------------------------------------------------------------------
# Define IP management aliases
#----------------------------------------------------------------------------
VIV_IP_UTILS=$REPO_BASE_PATH/tools/scripts/viv_ip_utils.tcl

function viv_create_ip {
    if [[ -z $1 || -z $2 || -z $3 || -z $4 ]]; then
        echo "Create a new Vivado IP instance and a Makefile for it"
        echo ""
        echo "Usage: viv_create_new_ip <IP Name> <IP Type> <Product> <IP Location>" 
        echo "- <IP Name>: Name of the IP instance"
        echo "- <IP VLNV>: The vendor, library, name, and version string for the IP as defined by Xilinx"
        echo "- <Product>: Product to generate IP for. Choose from: ${!PRODUCT_ID_MAP[@]}"
        echo "- <IP Location>: Base location for IP"
        return 1
    fi
    
    ip_name=$1
    ip_vlnv=$2
    IFS='/' read -r -a prod_tokens <<< "${PRODUCT_ID_MAP[$3]}"
    part_name=${prod_tokens[1]}${prod_tokens[2]}${prod_tokens[3]} 
    ip_dir=$4
    if [[ -d $ip_dir/$ip_name ]]; then
        echo "ERROR: IP $ip_dir/$ip_name already exists. Please choose a different name."
    else
        echo "Launching Vivado GUI..."
        vivado -mode gui -source $VIV_IP_UTILS -nolog -nojournal -tclargs create $ip_name $ip_vlnv $part_name $ip_dir
        echo "Generating Makefile..."
        python $REPO_BASE_PATH/tools/scripts/viv_gen_ip_makefile.py --ip_name=$ip_name --dest=$ip_dir/$ip_name
        echo "Done generating IP in $ip_dir/$ip_name"
    fi
}

function viv_modify_ip {
    if [[ -z $1 || -z $2 || -z $3 ]]; then
        echo "Modify an existing Vivado IP instance"
        echo ""
        echo "Usage: viv_modify_ip <IP Name> <Product> <IP Location>" 
        echo "- <IP Name>: Name of the IP instance"
        echo "- <Product>: Product to generate IP for. Choose from: ${!PRODUCT_ID_MAP[@]}"
        echo "- <IP Location>: Base location for IP"
        return 1
    fi
    
    ip_name=$1
    IFS='/' read -r -a prod_tokens <<< "${PRODUCT_ID_MAP[$2]}"
    part_name=${prod_tokens[1]}${prod_tokens[2]}${prod_tokens[3]} 
    ip_dir=$3
    if [[ -d $ip_dir/$ip_name ]]; then
        vivado -mode gui -source $VIV_IP_UTILS -nolog -nojournal -tclargs modify $ip_name unknown $part_name $ip_dir
    else
        echo "ERROR: IP $ip_dir/$ip_name not found."
    fi
}

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

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
unset MODELSIM_VERSIONS
unset MODELSIM_VER_PATHS
unset MODELSIM_VER_BITNESS

echo
echo "Environment successfully initialized."
return 0