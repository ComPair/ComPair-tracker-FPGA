# First run "petalinux-package --prebuilt" to make images
# Then run xsct <this_file.tcl> to boot

connect -url 10.10.2.100:3121
targets -set -nocase -filter {name =~ "arm*#0"}
rst -system
after 2000

targets -set -nocase -filter {name =~ "arm*#0"}

source /fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/project-spec/hw-description/ps7_init.tcl; ps7_post_config
catch {stop}
set mctrlval [string trim [lindex [split [mrd 0xF8007080] :] 1]]
puts "mctrlval=$mctrlval"
puts stderr "INFO: Downloading ELF file: /fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/zynq_fsbl.elf to the target."
dow "/fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/zynq_fsbl.elf"
after 2000
con
after 3000; stop
targets -set -nocase -filter {name =~ "arm*#0"}
puts stderr "INFO: Downloading ELF file: /fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/u-boot.elf to the target."
dow "/fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/u-boot.elf"
after 2000
con
after 2000; stop
targets -set -nocase -filter {name =~ "arm*#0"}

rst -processor; after 2000
puts stderr "INFO: Loading image: /fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/system.dtb at 0x08008000"
dow -data "/fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/system.dtb" 0x08008000
after 2000
rwr r2 0x08008000
targets -set -nocase -filter {name =~ "arm*#0"}
puts stderr "INFO: Loading image: /fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/zImage at 0x00008000"
dow -data "/fpga/code/ComPair-tracker-FPGA/src/petalinux/si-layer/pre-built/linux/images/zImage" 0x00008000
after 2000
rwr pc 0x00008000
con
after 5000
exit
puts stderr "INFO: Saving XSDB commands to mytcl3. You can run 'xsdb mytcl3' to execute"
