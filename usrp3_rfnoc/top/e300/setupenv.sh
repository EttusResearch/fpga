#!/bin/bash

VIVADO_VER=2015.4
DISPLAY_NAME="USRP-E3x0"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

declare -A PRODUCT_ID_MAP
PRODUCT_ID_MAP["E310"]="zynq/xc7z020/clg484/-1"
PRODUCT_ID_MAP["E310_SG3"]="zynq/xc7z020/clg484/-3"

source $REPO_BASE_PATH/tools/scripts/setupenv_base.sh
