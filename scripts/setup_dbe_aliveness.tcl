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

## Determine which module we're building for
## Build for 21FC3 by default
set USE_1CFA "0"
set TRENZ_MODULE "21FC3"
foreach arg $argv {
    if {[string equal [string compare $arg "use_1cfa"] "0"]} {
        set USE_1CFA "1"
        set TRENZ_MODULE "1CFA"
    }
}

# get the directory where this script resides
set thisDir [file dirname [info script]]

# source common utilities
source -notrace $thisDir/utils.tcl


set PROJECT_BASE [file normalize "$thisDir/../"]
set CORES_BASE [file normalize "$PROJECT_BASE/cores/"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work"]
set HDL_SRC_DIR [file normalize "$PROJECT_BASE/src/hdl"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "       CORES_BASE: $CORES_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "     TRENZ MODULE: $TRENZ_MODULE"
puts "================================="

set_param board.repoPaths $PROJECT_BASE/board_files/

if { $USE_1CFA } {
    create_project -force zynq $BUILD_WORKSPACE/zynq -part xc7z020clg484-1
} else {
    create_project -force zynq $BUILD_WORKSPACE/zynq -part xc7z020clg484-2
}

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

#if { $USE_1CFA } {
#    set_property "board_part" "trenz.biz:te0720_1c:part0:1.0" $obj
#} else {
#    set_property "board_part" "trenz.biz:te0720_2i:part0:1.0" $obj
#}

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

## ip_lib -> cores
## set IP_PATH $PROJECT_BASE/ip_lib
set IP_PATH $CORES_BASE

puts "INFO:Set IP path :" 
set_property IP_REPO_PATHS $IP_PATH [current_fileset]
::update_ip_catalog

##add_files -norecurse $CORES_BASE/vata460p3/vata460p3_interface.vhd
add_files -norecurse $PROJECT_BASE/src/hdl/slice_it_up.vhd
# Source the bd.tcl file to create the bd with custom ip module
# first get the major.minor version of the tool - and source
# the bd creation script that corresponds to the current tool version
set currVer [join [lrange [split [version -short] "."] 0 1] "."]
puts "Current Version $currVer"
if {$currVer eq "2018.3"} {
  puts "Running Block Design Generation"
  source $PROJECT_BASE/src/dbe/dbe_aliveness_bd.tcl
} else {
  puts "This script will only work with 2018.3, everything else will fail"
}
validate_bd_design
save_bd_design

# Generate Target
create_fileset -blockset -define_from dbe_aliveness_bd dbe_aliveness_bd
generate_target all [get_files */dbe_aliveness_bd.bd]

report_ip_status
upgrade_ip [ get_ips * ]

remove_files fifo_generator_0.xci -quiet

make_wrapper -files [get_files [file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/dbe_aliveness_bd.bd"]] -top

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 "[file normalize "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/hdl/dbe_aliveness_bd_wrapper.vhd"]"\
]
add_files -norecurse -fileset $obj $files
update_compile_order -fileset sim_1

# Set 'sources_1' fileset file properties for remote files
set file "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/hdl/dbe_aliveness_bd_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

#add_files -fileset constrs_1 -norecurse [file normalize "$PROJECT_BASE/src/zybo/board_constraints.xdc"]
add_files -fileset constrs_1 -norecurse [glob $PROJECT_BASE/src/dbe/*.xdc]

# Change from "Out of Context" IP to "Global"
set_property synth_checkpoint_mode None [get_files  "$BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/dbe_aliveness_bd.bd"]

puts "Setup of the Trenz Board complete!"

#puts "Importing hdl.."
#add_files -norecurse $PROJECT_BASE/src/hdl/slice_it_up.vhd

#source $thisDir/connect_gpio_to_vata_ports.tcl

##puts "Creating VATA interface..."
##source $thisDir/create_vata_iface.tcl
##
##puts "Adding VATA interface to zynq.bd..."
##source $thisDir/add_vata_to_bd.tcl
##
#### Next commands are cludge to fix error during implementation.
#### Error relates to dbe_aliveness_bd missing some output files
#### vivado recommends synth_checkpoint_mode be set to `Singular` for zynq.bd to fix this (it does not),
#### but there is a command setting synth_checkpoint_mode to None just a few lines up...
#### need to look up what this command does.
##upgrade_ip -srcset dbe_aliveness_bd -vlnv user.org:user:vata_460p3_interface:1.0 [get_ips dbe_aliveness_bd_vata_460p3_interface_P2_0] -log ip_upgrade.log
##export_ip_user_files -of_objects [get_ips dbe_aliveness_bd_vata_460p3_interface_P2_0] -no_script -sync -force -quiet
##generate_target all [get_files $BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/dbe_aliveness_bd.bd]
##export_ip_user_files -of_objects [get_files $BUILD_WORKSPACE/zynq/zynq.srcs/sources_1/bd/dbe_aliveness_bd/dbe_aliveness_bd.bd] -no_script -sync -force -quiet
##report_ip_status

# If successful, "touch" a file so the make utility will know it's done
touch {.setup.done}
puts "Setup complete."
