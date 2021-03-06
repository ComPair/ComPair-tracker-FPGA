set BUILD "[lindex $argv 0]"
#Function to get the name of the processor in the design
# get the directory where this script resides
set thisDir [file dirname [info script]]



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


set TOPLEVEL_NAME "$BUILD\_bd_wrapper"
set PROJECT_NAME "zynq"


# source common utilities

set PROJECT_BASE [file normalize "$thisDir/../"]
set BUILD_WORKSPACE [file normalize "$PROJECT_BASE/work/$BUILD/"]

puts "================================="
puts "     PROJECT_BASE: $PROJECT_BASE"
puts "            BUILD: $BUILD"
puts "  BUILD_WORKSPACE: $BUILD_WORKSPACE"
puts "     PROJECT_NAME: $PROJECT_NAME"
puts "    TOPLEVEL_NAME: $TOPLEVEL_NAME"





# SDK install path (eg. "C:/Xilinx/Vivado/2016.3")
set sdk_dir $::env(XILINX_SDK)

set hw_project_name my_hw_project

#Create an SDK workspace
set sdk_ws_dir [file normalize "$BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.sdk"]
set hdf_filename [file normalize $sdk_ws_dir/$TOPLEVEL_NAME.hdf]
sdk setws $sdk_ws_dir

file delete -force $sdk_ws_dir/.metadata
file delete -force $sdk_ws_dir/hw_0
file delete -force $sdk_ws_dir/bsp_fsbl
file delete -force $sdk_ws_dir/zynq_fsbl
file delete -force $sdk_ws_dir/zynq_fsbl_bsp
file delete -force $sdk_ws_dir/bsp_petalinux
file delete -force $sdk_ws_dir/calctrl
file delete -force $sdk_ws_dir/dacctrl


sdk createhw -name hw_0 -hwspec $hdf_filename

# ##################      First Stage Boot Loader
sdk createapp -name zynq_fsbl -app "Zynq FSBL" -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone 
puts "${PROJECT_BASE}/src/baremetal/zynq_fsbl"
puts "${sdk_ws_dir}/zynq_fsbl"
#exec rm -rf ${sdk_ws_dir}/zynq_fsbl/src
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/te_fsbl_hooks_te0720.c ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/te_fsbl_hooks_te0720.h ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/te_fsbl_hooks.c ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/te_fsbl_hooks.h ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/fsbl_hooks.c ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/fsbl_hooks.h ${sdk_ws_dir}/zynq_fsbl/src 
exec cp -f ${PROJECT_BASE}/src/baremetal/zynq_fsbl/main.c ${sdk_ws_dir}/zynq_fsbl/src 
sdk configapp -app zynq_fsbl build-config debug
sdk configapp -app  zynq_fsbl -set compiler-optimization {Optimize for size (-Os)}
sdk configapp -app zynq_fsbl build-config release
sdk configapp -app  zynq_fsbl -set compiler-optimization {Optimize for size (-Os)}


# # ##################      Linux Applications
 createbsp -name bsp_petalinux -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
 updatemss -mss [file normalize $sdk_ws_dir/bsp_petalinux/system.mss]
 regenbsp -bsp bsp_petalinux

# sdk createapp -name calctrl -app "Empty Application" -proc ps7_cortexa9 -hwproject hw_0 -os linux -bsp bsp_petalinux -lang c++
# puts "${PROJECT_BASE}/src/sdk-apps/calctrl"
# puts "${sdk_ws_dir}/calctrl"
# exec rm -rf ${sdk_ws_dir}/calctrl/src
# exec cp -rf ${PROJECT_BASE}/src/sdk-apps/calctrl/ ${sdk_ws_dir}/calctrl/src 

# sdk configapp -app calctrl build-config debug
# sdk configapp -app calctrl include-path ${sdk_ws_dir}/bsp_petalinux/ps7_cortexa9_0/include

# sdk createapp -name dacctrl -app "Empty Application" -proc ps7_cortexa9 -hwproject hw_0 -os linux -bsp bsp_petalinux -lang c++
# puts "${PROJECT_BASE}/src/sdk-apps/dacctrl"
# puts "${sdk_ws_dir}/dacctrl"
# exec rm -rf ${sdk_ws_dir}/dacctrl/src
# exec cp -rf ${PROJECT_BASE}/src/sdk-apps/dacctrl/ ${sdk_ws_dir}/dacctrl/src 

# sdk configapp -app dacctrl build-config debug
# sdk configapp -app dacctrl include-path ${sdk_ws_dir}/bsp_petalinux/ps7_cortexa9_0/include

# # projects -clean
# projects -build

# ##################      GPIO Application
# createbsp -name bsp_gpio -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
# updatemss -mss ${sdk_ws_dir}/bsp_gpio/system.mss

# sdk createapp -name app_gpio -app "Empty Application" -proc [get_processor_name hw_0] -hwproject hw_0 -bsp bsp_gpio -os standalone
# exec rm -f ${sdk_ws_dir}/app_gpio/src/main.cc
# sdk configapp -app app_gpio build-config debug
# sdk configapp -app  app_gpio -set compiler-optimization {Optimize for size (-Os)}
# sdk configapp -app app_gpio build-config release
# sdk configapp -app  app_gpio -set compiler-optimization {Optimize for size (-Os)}
# if { [file exists ${sdk_ws_dir}/app_gpio/src/lscript.ld] == 1 } {
   # exec cp -f ${sdk_ws_dir}/app_gpio/src/lscript.ld ${sdk_ws_dir}/app_gpio/lscript.ld
# }
# exec rm -rf ${sdk_ws_dir}/app_gpio/src
# #exec ln -s $::env(SDK_SRC_PATH) ${sdk_ws_dir}/app_gpio/src
# exec cp -f -r ${PROJECT_BASE}/src/dbe/sdk/gpio_app/src ${sdk_ws_dir}/app_gpio/
# if { [file exists ${sdk_ws_dir}/app_gpio/lscript.ld] == 1 } {
   # exec mv -f ${sdk_ws_dir}/app_gpio/lscript.ld ${sdk_ws_dir}/app_gpio/src/lscript.ld
# }


# createbsp -name bsp_lwip -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
# setlib -bsp bsp_lwip -lib lwip202
# updatemss -mss ${sdk_ws_dir}/bsp_lwip/system.mss

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
# exec cp -f -r ${PROJECT_BASE}/sdk/htides_ccd_app/src ${sdk_ws_dir}/app_lwip/
# if { [file exists ${sdk_ws_dir}/app_lwip/lscript.ld] == 1 } {
   # exec mv -f ${sdk_ws_dir}/app_lwip/lscript.ld ${sdk_ws_dir}/app_lwip/src/lscript.ld
# }


# Build all
#regenbsp -bsp bsp_gpio
#regenbsp -bsp bsp_lwip
projects -build


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