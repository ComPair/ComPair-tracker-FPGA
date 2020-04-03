#
#  ComPair Trakcer FEE project makefile
#

ROOTDIR=../..#$(PWD)

# Common options
VIVADOCOMOPS = -mode batch
XSCTCOMOPS = -batch

# determine the OS shell - this make file should work on both linux and windows
UNAME := $(shell uname)

# on windows you have to prefix vivado call with a cmd shell with /c
ifeq ($(UNAME), Linux)
PREFIX =
POSTFIX =
else
PREFIX = cmd //c "
POSTFIX = "
endif


ifndef BUILD
$(info **********)
$(info BUILD not set)
$(info On Linux: export BUILD=dbe_production)
$(info On Windows: set BUILD=dbe_production)
$(info Valid BUILD options = {dbe_production, dbe_production, breakout})
$(info **********)
$(error Error: Need to set BUILD in environment.)
endif

#@echo "On Linux: export BUILD=dbe_production"
#@echo ""
#@echo ""
## By default we are using the Trenz 21FC3 FPGA module.
## To use the 1CFA module, uncomment the line below.
#USING_1CFA_ARGS = -tclargs use_1cfa

#SETUP_EVAL = -source ../scripts/setup_trenz_breakout.tcl -log setup.log -jou setup.jou -notrace $(USING_1CFA_ARGS)
#SETUP_DBE_ALIVENESS = -source $(ROOTDIR)/scripts/setup_dbe_aliveness.tcl -log setup.log -jou setup.jou -notrace $(USING_1CFA_ARGS)

SETUP_PROJECT = -source $(ROOTDIR)/scripts/setup_project.tcl -log setup.log -jou setup.jou -notrace -tclargs $(BUILD) $(USING_1CFA_ARGS)
COMPILE_PROJECT = -source $(ROOTDIR)/scripts/compile.tcl -log compile.log -jou compile.jou -notrace -tclargs $(BUILD) 
SAVE_BD = -source $(ROOTDIR)/scripts/save_bd.tcl -log save_bd.log -jou save_bd.jou -notrace -tclargs $(BUILD) 
EXPORT_HW = -source $(ROOTDIR)/scripts/export_hardware.tcl -log export_hardware.log -jou export_hardware.jou -notrace -tclargs $(BUILD) 
SDK = -source $(ROOTDIR)/scripts/sdk_project_dbe.tcl $(BUILD) 
#all_dbe: setup_dbe_aliveness compile export_hardware_dbe sdk_project_dbe

#all: setup compile export_hardware sdk_project_dbe rootfs


# Launch the Vivado gui.
launchgui :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Launching GUI..."
	cd work/$(BUILD); $(PREFIX) vivado zynq/zynq.xpr $(POSTFIX)

launchsdk :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Launching XSDK..."
	cd work/$(BUILD); $(PREFIX) xsdk -workspace zynq/zynq.sdk/ $(POSTFIX)

save_bd:
	cd work/$(BUILD); $(PREFIX) vivado $(VIVADOCOMOPS) $(SAVE_BD) $(POSTFIX)    

setup : ./work/$(BUILD)/.setup.done
./work/$(BUILD)/.setup.done :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Running $(BUILD) setup"
	if [ ! -d "work" ]; then mkdir work; fi
	if [ ! -d "work/\$(BUILD)" ]; then mkdir work/\$(BUILD); fi
	@echo $(PWD)
	cd work/$(BUILD); $(PREFIX) vivado $(VIVADOCOMOPS) $(SETUP_PROJECT) $(POSTFIX)

compile : ./work/$(BUILD)/.compile.done 
./work/$(BUILD)/.compile.done : ./work/$(BUILD)/.setup.done
	cd work/$(BUILD); $(PREFIX) vivado $(VIVADOCOMOPS) $(COMPILE_PROJECT) $(POSTFIX)

export_hardware : ./work/$(BUILD)/.export_hardware.done 
./work/$(BUILD)/.export_hardware.done : ./work/$(BUILD)/.compile.done
	cd work/$(BUILD); $(PREFIX) vivado $(VIVADOCOMOPS) $(EXPORT_HW) $(POSTFIX)
	exit 0

sdk_project_dbe : ./work/$(BUILD)/.export_hardware.done 
	cd work/$(BUILD); $(PREFIX) xsdk $(XSCTCOMOPS) $(SDK) $(POSTFIX)
	exit 0

rootfs: ./work/$(BUILD)/.export_hardware.done 
	cd src/petalinux/apps ; $(PREFIX) make $(POSTFIX)
	exit 0

# Remove the work directory. Cannot be undone!
clean:
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Removing working directory."
	rm -rf work
	mkdir work

help:
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "Make options:"
	@echo "setup                -- Generate project."
	@echo "compile              -- Compile."
	@echo "save_bd              -- Exports block diagram."
	@echo "export_hardware      -- Export hardware files for SDK."
	@echo "sdk_project_dbe      -- Build petalinux bsp."
	@echo "rootfs         -- Build the rootfs on the zynq."
	@echo "help                 -- Prints this help."
