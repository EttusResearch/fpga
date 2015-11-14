#!/bin/bash

VIVADO_VER=2015.2
DEVICE_NAME="USRP-X3x0"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

source $REPO_BASE_PATH/tools/scripts/setupenv_base.sh
