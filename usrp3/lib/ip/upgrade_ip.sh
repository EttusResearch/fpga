#/bin/bash

export PART_NAME=xc7k410tffg900-2
export XCI_FILES=`find . | grep .xci | xargs`

vivado -mode batch -source ../../tools/scripts/viv_upgrade_ip.tcl -log upgrade_ip.log -nojournal

find . -name "*.veo" -exec rm {} \;
find . -name "*.xml" -exec rm {} \;
rm -f upgrade_ip.cumulative_upgrade_log
touch upgrade_ip.cumulative_upgrade_log
find . -name "*.upgrade_log" -exec cat {} >> upgrade_ip.cumulative_upgrade_log \;
find . -name "*.upgrade_log" -exec rm {} \;

