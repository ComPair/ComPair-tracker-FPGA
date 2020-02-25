set BUILD "[lindex $argv 0]"
# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
source -notrace $thisDir/utils.tcl

set PROJECT_BASE [file normalize "$thisDir/../"]
set CORES_BASE [file normalize "$PROJECT_BASE/cores/"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work/$BUILD/"]
set HDL_SRC_DIR [file normalize "$PROJECT_BASE/src/hdl"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "            BUILD: $BUILD"
puts "       CORES_BASE: $CORES_BASE"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "================================="


# Create project
open_project [file normalize "$BUILD_WORKSPACE/zynq/zynq.xpr"]

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $part -flow {Vivado Synthesis 2014} -strategy "Flow_RuntimeOptimized" -constrset constrs_1
} else {
  set_property strategy "Flow_RuntimeOptimized" [get_runs synth_1]
}
current_run -synthesis [get_runs synth_1]

#Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $part -flow {Vivado Implementation 2014} -strategy "Flow_RuntimeOptimized" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Flow_RuntimeOptimized" [get_runs impl_1]
}

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
#set timestamp_finish [clock format [clock seconds] -format {%YYYY-MM-DD--hh-mm}]
#write_bitstream -force -bin_file $BUILD_WORKSPACE/timestamp_finish

# if everything is successful "touch" a file so make will not it's done
touch {.compile.done}
puts "Compilation complete!"