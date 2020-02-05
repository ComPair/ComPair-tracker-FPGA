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

set TOPLEVEL_NAME "zynq_bd_wrapper"
set PROJECT_NAME "zynq"


# source common utilities
source -notrace $thisDir/utils.tcl
set PROJECT_BASE [file normalize "$thisDir/../"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "    PROJECT_NAME: $PROJECT_NAME"
puts "   TOPLEVEL_NAME: $TOPLEVEL_NAME"

# Create project
open_project [file normalize "$BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.xpr"]

#export to sdk - standard location
file mkdir [file normalize "$BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.sdk"]
write_hwdef -force -file [file normalize $BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.runs/synth_1/$TOPLEVEL_NAME.hwdef]
write_sysdef -force -hwdef [file normalize $BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.runs/synth_1/$TOPLEVEL_NAME.hwdef] -bitfile [file normalize $BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/$TOPLEVEL_NAME.bit] -file [file normalize $BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/$TOPLEVEL_NAME.sysdef]
file copy -force [file normalize "$BUILD_WORKSPACE/zynq/zynq.runs/impl_1/$TOPLEVEL_NAME.sysdef"] [file normalize "$BUILD_WORKSPACE/zynq/zynq.sdk/$TOPLEVEL_NAME.hdf"]

puts "Hardware exported!"
