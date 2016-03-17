##################################################################
# Tcl script to create the II-X6 HDL Vivado project for simulations
#
# Usage: at the Tcl console manually set the argv to set the PROJECT_DIR and PROJECT_NAME and
# then source this file. E.g.
#
# set argv [list "/home/cryan/Programming/FPGA" "II-X6-sim"] or
# or  set argv [list "C:/Users/qlab/Documents/Xilinx Projects/" "II-X6-sim"]
# source create_sim_project.tcl
#
# from Vivado batch mode use the -tclargs to pass argv
# vivado -mode batch -source create_sim_project.tcl -tclargs "/home/cryan/Programming/FPGA" "II-X6-sim"
##################################################################

#parse arguments
set PROJECT_DIR [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]

#Figure out the script path
set SCRIPT_PATH [file normalize [info script]]
set REPO_PATH [file dirname $SCRIPT_PATH]/../

create_project -force $PROJECT_NAME $PROJECT_DIR/$PROJECT_NAME -part xc7a200tfbg676-2
set_property "default_lib" "xil_defaultlib" [current_project]
set_property "sim.ip.auto_export_scripts" "1" [current_project]
set_property "simulator_language" "Mixed" [current_project]
set_property "target_language" "VHDL" [current_project]

add_files -fileset sim_1 $REPO_PATH/src/KernelIntegrator.vhd
add_files -fileset sim_1 $REPO_PATH/src/BBN_QDSP_pkg.vhd
add_files -fileset sim_1 $REPO_PATH/deps/VHDL-Components/src/DelayLine.vhd
add_files -fileset sim_1 $REPO_PATH/deps/VHDL-Components/src/ComplexMultiplier.vhd


add_files -fileset sim_1 $REPO_PATH/test/KernelIntegrator_tb.vhd

update_compile_order -fileset sim_1
