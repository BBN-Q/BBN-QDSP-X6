#Create a new ISE project for the BBN X6 firmware

# Initial author: Colm Ryan (cryan@bbn.com)
# Copyright 2015, Raytheon BBN Technologies

# Helpful to start with Project->Generate Tcl Script....
# Many of the function below modified from that starting point
# Also use make_ise.tcl from II

# Modify the variables below as necessary
set MY_PROJECT "X6-sx315t"
set PROJECTS_DIR "/home/cryan/Programming/FPGA"
set II_X6_DIR "/home/cryan/Programming/FPGA/II/X6_1000M_r1.7"
#set PROJECTS_DIR "C:/Users/qlab/Documents/Xilinx Projects"
#set II_X6_DIR "C:/Innovative/X6-1000M/Hardware/FrameWork Logic/X6_1000M_r1.7"

#Run at the tcl console with
# source create_project.tcl
# create_project

set DEV "sx315t"
#set to "-1" for lx240t boards we have
set DEV_SPEED "-2"
set PKG "ff1156"
set ARCH $DEV\-$PKG
#set to "x4" for lx240t
set PCIE_LANES "x8"
set REPO_ROOT [file normalize [pwd]/..]

proc create_project {} {

	global MY_PROJECT
	global PROJECTS_DIR

	puts "\nX6 create_project.tcl: Building $MY_PROJECT...\n"

	puts "Moving to $PROJECTS_DIR..."
	cd $PROJECTS_DIR

	puts "Making directory for project..."
	cd $PROJECTS_DIR
	if {[file isdirectory $MY_PROJECT]} {
		puts "Removing previous project..."
		file delete -force $MY_PROJECT
	}
	file mkdir $MY_PROJECT
	cd $MY_PROJECT

	project new $MY_PROJECT
	set_project_props
	add_source_files
	add_constraints

	puts "X6 create_project.tcl: project creation complete"
	puts "\nRun \"regenerate_ip\" to rebuild the IP cores (takes ~20 minutes)."
}

#
# set_project_props
#
# This procedure sets non-default project properties
#
proc set_project_props {} {

	global DEV
	global DEV_SPEED
	global PKG
	global II_X6_DIR
	global ARCH
	global PCIE_LANES

	puts "X6 create_project.tcl: Setting project properties..."

	set PCIE_IP     $II_X6_DIR/lib/ip/pcie/$PCIE_LANES/$ARCH
	set VFIFO_IP    $II_X6_DIR/lib/ip/vfifo/$ARCH/
	set ADC_IP      $II_X6_DIR/1000M/logic/rev_a/ip/ads5400_intf_phy
	set DAC_IP      $II_X6_DIR/1000M/logic/rev_a/ip/dac5682z_intf_phy
	set DAC_LAT_IP  $II_X6_DIR/1000M/logic/rev_a/ip/dac_lat_cal
	set CORE_DIRS   "$PCIE_IP|$VFIFO_IP|$ADC_IP|$DAC_IP|$DAC_LAT_IP"


	#Top level project properties
	project set family "Virtex6"
	project set device xc6v$DEV
	project set package $PKG
	project set speed $DEV_SPEED
	project set top_level_module_type "HDL"
	project set synthesis_tool "XST (VHDL/Verilog)"
	project set simulator "ISim (VHDL/Verilog)"
	project set "Preferred Language" "VHDL"
	project set "Enable Message Filtering" "false"

	#Specific process properties from II - but only those reported modified from the ISE script
	# XST properties
	project set "Optimization Goal" "Speed" -process "Synthesize - XST"
	project set "Keep Hierarchy" "Soft" -process "Synthesize - XST"
	project set "Register Balancing" "Yes" -process "Synthesize - XST"
	project set "Resource Sharing" "false" -process "Synthesize - XST"
	project set "Equivalent Register Removal" "false" -process "Synthesize - XST"
	project set "Max Fanout" "10000" -process "Synthesize - XST"
	project set "Cores Search Directories" $CORE_DIRS

	#Translate properties
	project set "Macro Search Path" $CORE_DIRS -process "Translate"

	# MAP properties
	project set "Generate Detailed MAP Report" "true" -process "Map"
	project set "Enable Multi-Threading" 2 -process "Map"
	project set "Placer Extra Effort" "Continue on Impossible" -process "Map"
	project set "Allow Logic Optimization Across Hierarchy" "true" -process "Map"

	#PAR properties
	project set "Enable Multi-Threading" 2 -process "Place & Route"
	project set "Placer Effort Level" "High"
	project set "Extra Effort (Highest PAR level only)" "Normal" -process "Place & Route"

	# Bitgen properties
	project set "Run Design Rules Checker (DRC)" "false" -process "Generate Programming File"
	project set "Other Bitgen Command Line Options" "-g StartupClk:CClk -g DriveDone:Yes" -process "Generate Programming File"

	#Top-level generics
	set NUM_LANES [string index $PCIE_LANES 1]
	project set "Generics, Parameters" "PCIE_LANES=$NUM_LANES,DEVICE=\"$DEV\""
}

proc add_source_files {} {

	global II_X6_DIR
	global REPO_ROOT
	global PROJECTS_DIR
	global MY_PROJECT

	puts "X6 create_project.tcl: Adding sources to project..."

	#II VHDL
	set II_LIB_COMMON $II_X6_DIR/lib/common
	set X6_1000_LOGIC $II_X6_DIR/1000M/logic/rev_a

	xfile add $II_LIB_COMMON/ii_crm.vhd
	xfile add $II_LIB_COMMON/ii_mmcm.vhd

	xfile add $II_LIB_COMMON/ii_regs_master.vhd
	xfile add $X6_1000_LOGIC/src/ii_regs_periph.vhd
	xfile add $II_LIB_COMMON/ii_regs_core.vhd

	xfile add $II_LIB_COMMON/ii_loader_top.vhd
	xfile add $II_LIB_COMMON/ii_loader.vhd
	xfile add $II_LIB_COMMON/ii_loader_regs.vhd

	xfile add $II_LIB_COMMON/ii_temp_control_top.vhd
	xfile add $II_LIB_COMMON/ii_lm96163_intf.vhd
	xfile add $II_LIB_COMMON/ii_lm96163_intf_phy.vhd
	xfile add $II_LIB_COMMON/ii_temp_control_regs.vhd
	xfile add $II_LIB_COMMON/ii_temp_control.vhd

	xfile add $II_LIB_COMMON/ii_flash_intf_top.vhd
	xfile add $II_LIB_COMMON/ii_flash_spi.vhd
	xfile add $II_LIB_COMMON/ii_flash_regs.vhd

	xfile add $II_LIB_COMMON/ii_alert_gen.vhd

	xfile add $II_LIB_COMMON/ii_alerts_top.vhd
	xfile add $II_LIB_COMMON/ii_alerts_regs.vhd
	xfile add $II_LIB_COMMON/ii_alerts.vhd
	xfile add $II_LIB_COMMON/ii_timestamp.vhd
	xfile add $II_LIB_COMMON/ii_xdom_pulse.vhd

	xfile add $II_LIB_COMMON/ii_packetizer_top.vhd
	xfile add $II_LIB_COMMON/ii_packetizer.vhd
	xfile add $II_LIB_COMMON/ii_packetizer_regs.vhd

	xfile add $II_LIB_COMMON/ii_vita_mvr_nx1.vhd

	xfile add $II_LIB_COMMON/ii_unsign_sat.vhd

	xfile add $II_LIB_COMMON/ii_vita_velo_pad.vhd
	xfile add $II_LIB_COMMON/ii_vita_mover.vhd
	xfile add $II_LIB_COMMON/ii_vita_checker.vhd

	xfile add $II_LIB_COMMON/ii_cdce72010_spi.vhd

	xfile add $II_LIB_COMMON/ii_sync_s1p4_intf.vhd
	xfile add $II_LIB_COMMON/ii_s1p4_iob.vhd
	xfile add $II_LIB_COMMON/ii_s1p4_fabric.vhd

	xfile add $II_LIB_COMMON/ii_trigger_top.vhd
	xfile add $II_LIB_COMMON/ii_trigger.vhd
	xfile add $II_LIB_COMMON/ii_trigger_pri.vhd

	xfile add $II_LIB_COMMON/ii_trig_alert.vhd

	#BBN VHDL
	xfile add $REPO_ROOT/ii_mods/ii_afe_intf_top.vhd
	xfile add $REPO_ROOT/ii_mods/ii_afe_intf_regs.vhd

	xfile add $REPO_ROOT/ii_mods/ii_dac5682z_intf_top.vhd
	xfile add $REPO_ROOT/ii_mods/ii_dac5682z_intf.vhd
	xfile add $X6_1000_LOGIC/src/ii_dac5682z_spi.vhd
	xfile add $X6_1000_LOGIC/src/ii_dac_test_gen.vhd
	xfile add $X6_1000_LOGIC/src/ii_dac_bitslip.vhd
	xfile add $II_LIB_COMMON/ii_offgain.vhd
	xfile add $II_LIB_COMMON/ii_sign_sat.vhd
	xfile add $II_LIB_COMMON/mult_add/ii_mult_add.vhd

	xfile add $REPO_ROOT/ii_mods/ii_ads5400_intf_top.vhd
	xfile add $REPO_ROOT/ii_mods/ii_ads5400_intf.vhd
	xfile add $X6_1000_LOGIC/src/ii_sample_sort.vhd

	xfile add $REPO_ROOT/src/PulseGenerator.vhd
	xfile add $REPO_ROOT/src/PulseGenerator_regs.vhd

	xfile add $REPO_ROOT/src/ADCDecimator.vhd
	xfile add $REPO_ROOT/src/axis_arb_mux_2.v
	xfile add $REPO_ROOT/src/axis_mux_2.v
	xfile add $REPO_ROOT/src/BBN_QDSP_pkg.vhd
	xfile add $REPO_ROOT/src/BBN_QDSP_regs.vhd
	xfile add $REPO_ROOT/src/BBN_QDSP_top.vhd
	xfile add $REPO_ROOT/src/BBN_QDSP_VitaMuxer.vhd
	xfile add $REPO_ROOT/src/Channelizer.vhd
	xfile add $REPO_ROOT/src/KernelIntegrator.vhd
	xfile add $REPO_ROOT/src/TestPattern.vhd
	xfile add $REPO_ROOT/src/VitaFramer.vhd
	xfile add $REPO_ROOT/src/VitaFramer_pkg.vhd
	xfile add $REPO_ROOT/src/VitaTimeStamp.vhd

	xfile add $REPO_ROOT/deps/verilog-axis/rtl/arbiter.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/priority_encoder.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_arb_mux_4.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_mux_4.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_adapter.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_register.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_srl_fifo.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_fifo.v
	xfile add $REPO_ROOT/deps/verilog-axis/rtl/axis_async_fifo.v

	xfile add $REPO_ROOT/deps/VHDL-Components/src/ComplexMultiplier.vhd
	xfile add $REPO_ROOT/deps/VHDL-Components/src/DelayLine.vhd
	xfile add $REPO_ROOT/deps/VHDL-Components/src/PolyphaseSSB.vhd
	xfile add $REPO_ROOT/deps/VHDL-Components/src/Synchronizer.vhd

	xfile add $REPO_ROOT/ii_mods/x6_1000m_top.vhd
	xfile add $REPO_ROOT/ii_mods/x6_1000m_pkg.vhd

	#Add IP cores with copy so when we generate them they don't barf files all over the repo
	#First II ones
	set ii_xco_files [list \
		$II_LIB_COMMON/coregen/sfifo_32x48_ft.xco \
		$II_LIB_COMMON/coregen/sfifo_512x128_bram.xco \
		$II_X6_DIR/1000M/logic/rev_a/coregen/afifo_512x64_bram.xco \
		$II_X6_DIR/1000M/logic/rev_a/coregen/dds_16b.xco \
	]
	foreach xcoFile $ii_xco_files {
		xfile add $xcoFile -copy
	}

	#Now BBN ones
	xfile add $REPO_ROOT/ip/*.xco -copy
	foreach coeFile [glob $REPO_ROOT/ip/*.coe] {
		file copy $coeFile $PROJECTS_DIR/$MY_PROJECT/ipcore_dir/
	}
	xfile add $REPO_ROOT/deps/VHDL-Components/ip/DDS_SSB.xco -copy

	#set the top module
	project set top "arch" "x6_1000m_top"
}

proc regenerate_ip {} {

	global PROJECTS_DIR
	global MY_PROJECT
	global DEV

	puts "X6 create_project.tcl: Regenerating IP cores. This can take a while..."

	if {[file exists $PROJECTS_DIR/$MY_PROJECT/ipcore_dir/coregen.cgp] == 0} {
		file copy $REPO_ROOT/ip/coregen.$DEV.cgp $PROJECTS_DIR/$MY_PROJECT/ipcore_dir/coregen.cgp
	}

	cd $PROJECTS_DIR/$MY_PROJECT/ipcore_dir

	foreach xcoFile [glob *.xco] {
		puts "$xcoFile...."
		catch {exec coregen -b $xcoFile -p coregen.cgp} msg
	}

	cd $PROJECTS_DIR/$MY_PROJECT
}

proc add_constraints {} {

	global II_X6_DIR
	global PCIE_LANES
	global ARCH
	global REPO_ROOT

	set X6_1000_SRC $II_X6_DIR/1000M/logic/rev_a/src

	#modifed by BBN
	xfile add $REPO_ROOT/constraints/x6_1000m.ucf

	#Original II ones
	xfile add $II_X6_DIR/lib/ip/pcie/$PCIE_LANES/$ARCH/ii_pcie_intf.ucf
	xfile add $II_X6_DIR/lib/ip/vfifo/$ARCH/ucf/ii_vfifo_c2.ucf
	xfile add $II_X6_DIR/lib/ip/vfifo/$ARCH/ucf/ii_vfifo_c3.ucf
}
