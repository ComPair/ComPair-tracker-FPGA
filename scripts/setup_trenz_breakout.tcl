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

set PROJECT_BASE [file normalize "$thisDir/../"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work"]
set HDL_DIR [file normalize "$PROJECT_BASE/src/hdl"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "       CORES_BASE: $CORES_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "================================="

set_param board.repoPaths $PROJECT_BASE/board_files/

create_project -force zynq $BUILD_WORKSPACE/zynq -part xc7z020clg484-2

# setup up custom ip repository location
#set_property ip_repo_paths             \
  [ list                               \
    "${CORES_BASE}/generic_counter"    \
  ] [current_fileset]

update_ip_catalog


# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects zynq]
#set_property "board_part" "digilentinc.com:zybo-z7-20:part0:1.0" $obj
set_property "board_part" "trenz.biz:te0720_2i:part0:1.0" $obj

set_property "default_lib" "xil_defaultlib" $obj
set_property "generate_ip_upgrade_log" "0" $obj
set_property "sim.ip.auto_export_scripts" "1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

puts "INFO: Project created: Trenz Zynq"

set IP_PATH $PROJECT_BASE/ip_lib

puts "INFO:Set IP path :" 
set_property IP_REPO_PATHS $IP_PATH [current_fileset]
::update_ip_catalog

add_files -norecurse $HDL_DIR/vata460p3_driver.vhd

# Source the bd.tcl file to create the bd with custom ip module
# first get the major.minor version of the tool - and source
# the bd creation script that corresponds to the current tool version
set currVer [join [lrange [split [version -short] "."] 0 1] "."]
puts "Current Version $currVer"
if {$currVer eq "2018.3"} {
  puts "Running Block Design Generation"
  source $PROJECT_BASE/src/breakout/zynq_bd.tcl
} else {
  puts "This script will only work with 2018.3, everything else will fail"
}
validate_bd_design
save_bd_design

# Generate Target
create_fileset -blockset -define_from zynq_bd zynq_bd
generate_target all [get_files */zynq_bd.bd]

report_ip_status
upgrade_ip [ get_ips * ]

remove_files fifo_generator_0.xci -quiet

make_wrapper -files [get_files [file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/zynq_bd/zynq_bd.bd"]] -top

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 "[file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/zynq_bd/hdl/zynq_bd_wrapper.vhd"]"\
]
add_files -norecurse -fileset $obj $files
update_compile_order -fileset sim_1

# Set 'sources_1' fileset file properties for remote files
set file "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/zynq_bd/hdl/zynq_bd_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

#add_files -fileset constrs_1 -norecurse [file normalize "$PROJECT_BASE/src/zybo/board_constraints.xdc"]
add_files -fileset constrs_1 -norecurse [glob $PROJECT_BASE/src/breakout/*.xdc]


# Change from "Out of Context" IP to "Global"
set_property synth_checkpoint_mode None [get_files  "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/zynq_bd/zynq_bd.bd"]

# If successful, "touch" a file so the make utility will know it's done
touch {.setup.done}
puts "Setup of the Trenz Board complete!"

puts "Adding VATA driver to BD..."
source $thisDir/add_vata_to_bd.tcl

puts "Setup complete."
