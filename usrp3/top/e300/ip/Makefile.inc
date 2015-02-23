${DCP} : %.dcp : %.xci
	export IP_FILE=$<;echo ${IP_FILE};vivado -mode batch -source ../rebuild_ip.tcl
