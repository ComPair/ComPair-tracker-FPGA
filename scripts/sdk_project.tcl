#Function to get the name of the processor in the design

proc get_processor_name {hw_project_name} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the last column is "PROCESSOR", then get the "IP INSTANCE" name (1st col)
    if {[lindex $values end] == "PROCESSOR"} {
      return [lindex $values 0]
    }
  }
  return ""
}

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





# SDK install path (eg. "C:/Xilinx/Vivado/2016.3")
set sdk_dir $::env(XILINX_SDK)

set hw_project_name my_hw_project

#Create an SDK workspace
set sdk_ws_dir [file normalize "$BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.sdk"]
set hdf_filename $sdk_ws_dir/$TOPLEVEL_NAME.hdf
sdk setws $sdk_ws_dir

sdk createhw -name hw_0 -hwspec $hdf_filename

createbsp -name bsp_fsbl -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
setlib -bsp bsp_fsbl -lib xilrsa
setlib -bsp bsp_fsbl -lib xilffs
updatemss -mss ${sdk_ws_dir}/bsp_fsbl/system.mss
regenbsp -bsp bsp_fsbl
sdk createapp -bsp bsp_fsbl -name app_fsbl -app "Zynq FSBL" -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
sdk configapp -app app_fsbl build-config debug
sdk configapp -app  app_fsbl -set compiler-optimization {Optimize for size (-Os)}
sdk configapp -app app_fsbl build-config release
sdk configapp -app  app_fsbl -set compiler-optimization {Optimize for size (-Os)}


createbsp -name bsp_lwip -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
setlib -bsp bsp_lwip -lib lwip202
updatemss -mss ${sdk_ws_dir}/bsp_lwip/system.mss


# sdk createapp -name app_lwip -app "Empty Application" -proc [get_processor_name hw_0] -hwproject hw_0 -bsp bsp_lwip -os standalone
# exec rm -f ${sdk_ws_dir}/app_lwip/src/main.cc
# sdk configapp -app app_lwip build-config debug
# sdk configapp -app  app_lwip -set compiler-optimization {Optimize for size (-Os)}
# sdk configapp -app app_lwip build-config release
# sdk configapp -app  app_lwip -set compiler-optimization {Optimize for size (-Os)}
# if { [file exists ${sdk_ws_dir}/app_lwip/src/lscript.ld] == 1 } {
   # exec cp -f ${sdk_ws_dir}/app_lwip/src/lscript.ld ${sdk_ws_dir}/app_lwip/lscript.ld
# }
# exec rm -rf ${sdk_ws_dir}/app_lwip/src
# #exec ln -s $::env(SDK_SRC_PATH) ${sdk_ws_dir}/app_lwip/src
# exec cp -f -r ${repoRoot}/sdk/htides_ccd_app/src ${sdk_ws_dir}/app_lwip/
# if { [file exists ${sdk_ws_dir}/app_lwip/lscript.ld] == 1 } {
   # exec mv -f ${sdk_ws_dir}/app_lwip/lscript.ld ${sdk_ws_dir}/app_lwip/src/lscript.ld
# }


# # # Build all
# regenbsp -bsp bsp_lwip
# regenbsp -bsp bsp_lwip
# projects -build


# # # if everything is successful "touch" a file so make will not it's done
# # #touch {.sdk.done}

# exec mkdir ${sdk_ws_dir}/app_lwip/bootimage
# set fp [open ${sdk_ws_dir}/app_lwip/bootimage/app.bif w+]
# puts $fp "//arch = zynq; split = false; format = BIN"
# puts $fp "the_ROM_image:"
# puts $fp "{"
# puts $fp "\t\[bootloader\][file normalize ${sdk_ws_dir}]/app_fsbl/Release/app_fsbl.elf"
# puts $fp "\t[file normalize ${sdk_ws_dir}]/hw_0/top.bit"
# puts $fp "\t[file normalize ${sdk_ws_dir}]/app_lwip/Release/app_lwip.elf"
# puts $fp "}"
# close $fp
# exec bootgen -image sdk\\app_lwip\\bootimage\\app.bif -o sdk\\app_lwip\\bootimage\\BOOT.bin