#
#  This file is part of:
#    SpaceCube Development Suite (scds) / SpaceCube Linux (scLinux)
#
#  Copyright (c) 2016, United States government as represented by the
#  administrator of the National Aeronautics Space Administration.
#  All rights reserved. This software was created at NASA's Goddard
#  Space Flight Center pursuant to government contracts.
#
#   Author:   G. Crum,  NASA/GSFC Code 587
#

# get the directory where this script resides
set thisDir [file dirname [info script]]

# source common utilities
source -notrace $thisDir/utils.tcl

set CORES_BASE [file normalize "$thisDir/../cores/"]
set IP_BASE [file normalize "$CORES_BASE/fpga-ip-library/vivado_library/ip_repo"]
set PROJECT_BASE [file normalize "$thisDir/../"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "       CORES_BASE: $CORES_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "          IP_BASE: $IP_BASE"

# Create project
open_project [file normalize "$BUILD_WORKSPACE/zynq/zynq.xpr"]

open_bd_design [file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/zynq_bd/zynq_bd.bd"]

write_bd_tcl [file normalize "$PROJECT_BASE/src/zybo/zynq_bd.tcl"] -force
puts "Zybo Board design saved!"
