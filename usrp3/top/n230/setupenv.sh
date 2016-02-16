#!/bin/bash

VIVADO_VER=2015.4
DISPLAY_NAME="USRP-N230"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

declare -A PRODUCT_ID_MAP
PRODUCT_ID_MAP["N230"]="artix7/xc7a100t/fgg484/-2"

source $REPO_BASE_PATH/tools/scripts/setupenv_base.sh
