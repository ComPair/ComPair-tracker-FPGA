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


set TOPLEVEL_NAME "dbe_aliveness_bd_wrapper"
set PROJECT_NAME "zynq"


# source common utilities

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

#Set SDK workspace
set sdk_ws_dir [file normalize "$BUILD_WORKSPACE/$PROJECT_NAME/$PROJECT_NAME.sdk"]
set hdf_filename [file normalize $sdk_ws_dir/$TOPLEVEL_NAME.hdf]
sdk setws $sdk_ws_dir

sdk createhw -name hw_0 -hwspec $hdf_filename

createbsp -name bsp_fsbl -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
setlib -bsp bsp_fsbl -lib xilrsa
setlib -bsp bsp_fsbl -lib xilffs
updatemss -mss [file normalize $sdk_ws_dir/bsp_fsbl/system.mss]
regenbsp -bsp bsp_fsbl
sdk createapp -bsp bsp_fsbl -name app_fsbl -app "Zynq FSBL" -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
sdk configapp -app app_fsbl build-config debug
sdk configapp -app  app_fsbl -set compiler-optimization {Optimize for size (-Os)}
sdk configapp -app app_fsbl build-config release
sdk configapp -app  app_fsbl -set compiler-optimization {Optimize for size (-Os)}




createbsp -name bsp_gpio -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
updatemss -mss ${sdk_ws_dir}/bsp_gpio/system.mss

sdk createapp -name app_gpio -app "Empty Application" -proc [get_processor_name hw_0] -hwproject hw_0 -bsp bsp_gpio -os standalone
exec rm -f ${sdk_ws_dir}/app_gpio/src/main.cc
sdk configapp -app app_gpio build-config debug
sdk configapp -app  app_gpio -set compiler-optimization {Optimize for size (-Os)}
sdk configapp -app app_gpio build-config release
sdk configapp -app  app_gpio -set compiler-optimization {Optimize for size (-Os)}
if { [file exists ${sdk_ws_dir}/app_gpio/src/lscript.ld] == 1 } {
   exec cp -f ${sdk_ws_dir}/app_gpio/src/lscript.ld ${sdk_ws_dir}/app_gpio/lscript.ld
}
exec rm -rf ${sdk_ws_dir}/app_gpio/src
#exec ln -s $::env(SDK_SRC_PATH) ${sdk_ws_dir}/app_gpio/src
exec cp -f -r ${PROJECT_BASE}/src/dbe/sdk/gpio_app/src ${sdk_ws_dir}/app_gpio/
if { [file exists ${sdk_ws_dir}/app_gpio/lscript.ld] == 1 } {
   exec mv -f ${sdk_ws_dir}/app_gpio/lscript.ld ${sdk_ws_dir}/app_gpio/src/lscript.ld
}

#createbsp -name bsp_gpio -proc [get_processor_name hw_0] -hwproject hw_0 -os standalone
updatemss -mss ${sdk_ws_dir}/bsp_gpio/system.mss

sdk createapp -name toggle_gpio -app "Empty Application" -proc [get_processor_name hw_0] -hwproject hw_0 -bsp bsp_gpio -os standalone
exec rm -f ${sdk_ws_dir}/toggle_gpio/src/main.cc
sdk configapp -app toggle_gpio build-config debug
sdk configapp -app  toggle_gpio -set compiler-optimization {Optimize for size (-Os)}
sdk configapp -app toggle_gpio build-config release
sdk configapp -app  toggle_gpio -set compiler-optimization {Optimize for size (-Os)}
if { [file exists ${sdk_ws_dir}/toggle_gpio/src/lscript.ld] == 1 } {
   exec cp -f ${sdk_ws_dir}/toggle_gpio/src/lscript.ld ${sdk_ws_dir}/toggle_gpio/lscript.ld
}
exec rm -rf ${sdk_ws_dir}/toggle_gpio/src
#exec ln -s $::env(SDK_SRC_PATH) ${sdk_ws_dir}/toggle_gpio/src
exec cp -f -r ${PROJECT_BASE}/src/dbe/sdk/toggle_gpio/src ${sdk_ws_dir}/toggle_gpio/
if { [file exists ${sdk_ws_dir}/toggle_gpio/lscript.ld] == 1 } {
   exec mv -f ${sdk_ws_dir}/toggle_gpio/lscript.ld ${sdk_ws_dir}/toggle_gpio/src/lscript.ld
}



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
regenbsp -bsp bsp_gpio
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