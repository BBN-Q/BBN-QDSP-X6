#move to the repo directory
set cur_dir [pwd]
set SCRIPT_PATH [file normalize [info script]]
set REPO_ROOT [file normalize [file join [file dirname $SCRIPT_PATH] ".."]]
cd $REPO_ROOT

#get the version info
set git_descrip [exec git describe --dirty]
regexp {v(\d+)\.(\d+)} [exec git describe] -> tag_major tag_minor
set git_sha1 [exec git rev-parse --short=8 HEAD]

#and the timestamp
set build_timestamp [clock format [clock seconds] -format {32'h%y%m%d%H}]

#update the generic string
#(bizarrely we have to use Verilog style for std_logic_vector generics see https://forums.xilinx.com/t5/Vivado-TCL-Community/Vivado-2013-1-and-VHDL-93-string-generics/m-p/333341/highlight/true)
set generics [project get "Generics, Parameters"]
#x6_version
regsub {BBN_X6_VERSION=32'h\d{8}} $generics [format BBN_X6_VERSION=32'h%x%03x%02x%02x 13 10 0 9] generics
#git_sha1
regsub {BBN_X6_GIT_SHA1=32'h\d{8}} $generics BBN_X6_GIT_SHA1=32'h$git_sha1 generics
#build timestamp
regsub {BUILD_TIMESTAMP=32'h\d{8}} $generics BUILD_TIMESTAMP=$build_timestamp generics

project set "Generics, Parameters" $generics

#move back to where we were
cd $cur_dir
