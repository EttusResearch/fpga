#
# Create New Empty XPS project for e200
#
xload new e200_ps.xmp
#
# Change technology for correct Zync device and board
#
xset arch zynq
xset dev xc7z020
xset package clg484
xset speedgrade -1
xset binfo ZC702

xset hier sub
xset hdl verilog
xset intstyle PA
xset flow ise
#
# Copy over empty .mhs file created at project initialization
# with existing master copy specifying full PS+PL config
#
exec cp $env(ZYNQ_PS_LIB)/e200_master.mhs e200_ps.mhs
exec cp $env(ZYNQ_PS_LIB)/ps7_e200_ps_prj.xml data/ps7_e200_ps_prj.xml
run resync
#
# Now save everything back to files so that .xmp and make files are updated.
#
save proj
#
# Ruuning DRC causes essential files to be generated that are dependacies for netlist generation
#
#run drc
#
# Run XST to generate ngc netlist files.
#
xset parallel_synthesis yes
#run stubgen
#run drc
run netlist

exit
