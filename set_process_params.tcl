# if something goes wrong with version lookup, assume 12.3
set maj 12
set min 3
set par_msg  [open "|par" r]
while {[gets $par_msg cur_line] >= 0} {
  if {[regexp -nocase {^Release (.*) - .*} $cur_line match ver]} {
    set ise_ver [regexp -all -inline {\d+} $ver]
    set maj [lindex $ise_ver 0]
    set min [lindex $ise_ver 1]
  }
}
puts "Running ISE $ver"

# XST properties
project set "Optimization Goal" Speed
project set "Keep Hierarchy" Soft
project set "Add I/O Buffers" True
project set "Bus Delimiter" <>
project set "Hierarchy Separator" /
project set "Register Balancing" "Yes"
project set "Read Cores" True
project set "Resource Sharing" False
project set "Equivalent Register Removal" False -process "Synthesize - XST"
project set "Register Duplication" True -process "Synthesize - XST"
project set "Write Timing Constraints" False
project set "Optimize Instantiated Primitives" False
project set "Cross Clock Analysis" False
project set "Max Fanout" 10000
# project set "Cores Search Directories" $CORE_DIRS
project set "Pack I/O Registers into IOBs" "Auto"
# project set "Generics, Parameters" "PCIE_LANES=$nLANES,USE_XMC_RST=$XMCRST,ADD_AURORA=$ADD_AURORA,DEVICE=\"$DEV\""

# NGDBuild properties
# project set "Macro Search Path" $CORE_DIRS -process "Translate"

# MAP properties
project set "Optimization Strategy" speed
project set "Generate Detailed MAP Report" True
project set "Global Optimization" "Off"
project set "Enable Multi-Threading" 2 -process "Map"
project set "Enable Multi-Threading" 2 -process "Place & Route"

project set "Placer Effort Level" "High"
project set "Placer Extra Effort" "Continue on Impossible"
project set "Allow Logic Optimization Across Hierarchy" True
project set "Starting Placer Cost Table (1-100)" 1 -process "Map"

# PAR properties
project set "Place & Route Effort Level (Overall)" High
project set "Extra Effort (Highest PAR level only)" Normal

# Bitgen properties
project set "Run Design Rules Checker (DRC)" False
project set "Other Bitgen Command Line Options" {-g StartupClk:CClk -g DriveDone:Yes}