#
# Create work library
#
vlib work
#
# Compile sources
#
vlog  C:/Users/osamu/Desktop/tinyEtherDeveloper/RTL_project/common/sim/tb_MAC_DEC.v
#
# Call vsim to invoke simulator
#
vsim -L  -gui -novopt work.
#
# Add waves
#
add wave *
#
# Run simulation
#
run 1000ns
#
# End