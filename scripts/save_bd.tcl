set BUILD "[lindex $argv 0]"
# get the directory where this script resides
set thisDir [file dirname [info script]]

# source common utilities
source -notrace $thisDir/utils.tcl

set CORES_BASE [file normalize "$thisDir/../cores/"]
set IP_BASE [file normalize "$CORES_BASE/fpga-ip-library/vivado_library/ip_repo"]
set PROJECT_BASE [file normalize "$thisDir/../"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work/$BUILD"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "            BUILD: $BUILD"
puts "       CORES_BASE: $CORES_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "          IP_BASE: $IP_BASE"

# Create project
open_project [file normalize "$BUILD_WORKSPACE/zynq/zynq.xpr"]

open_bd_design [file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/$BUILD\_bd/$BUILD\_bd.bd"]

write_bd_tcl [file normalize "$PROJECT_BASE/src/block_diagrams/$BUILD/$BUILD\_bd.tcl"] -force
puts "$BUILD block diagram saved!"
