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
puts "================================="


# Create project
open_project [file normalize "$BUILD_WORKSPACE/zynq/zynq.xpr"]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1


# if everything is successful "touch" a file so make will not it's done
touch {.compile.done}
puts "Compilation complete!"