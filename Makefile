#
#  ComPair Trakcer FEE project makefile
#

ROOTDIR=..

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

## By default we are using the Trenz 21FC3 FPGA module.
## To use the 1CFA module, uncomment the line below.
#USING_1CFA_ARGS = -tclargs use_1cfa

SETUP_EVAL = -source $(ROOTDIR)/scripts/setup_trenz_breakout.tcl -log setup.log -jou setup.jou -notrace $(USING_1CFA_ARGS)
SETUP_DBE_ALIVENESS = -source $(ROOTDIR)/scripts/setup_dbe_aliveness.tcl -log setup.log -jou setup.jou -notrace $(USING_1CFA_ARGS)

all_dbe: setup_dbe_aliveness compile export_hardware_dbe sdk_project_dbe
	
# Setup the Trenz/Zynq base project
#setup_breakout : .\work\.setup.done
#.\work\.setup.done :
#	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
#	@echo "    Running Trenz TE0703 setup"
#	mkdir -p work
#	echo $(PWD)
#	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) $(SETUP_EVAL) $(POSTFIX)

setup_dbe_aliveness : .\work\.setup.done
.\work\.setup.done :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Running DBE setup"
	mkdir -p work
	echo $(PWD)
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) $(SETUP_DBE_ALIVENESS) $(POSTFIX)


save_trenz_design :  
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/save_trenz_design.tcl -log save_trenz_design.log -jou save_trenz_design.jou -notrace $(POSTFIX)

save_dbe_bd :  
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/save_dbe_bd.tcl -log save_dbe_bd.log -jou save_dbe_bd.jou -notrace $(POSTFIX)

compile : .\work\.compile.done
.\work\.compile.done : .\work\.setup.done
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/compile.tcl -log compile.log -jou compile.jou $(POSTFIX)


# Launch the Vivado gui.
launchgui :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Launching GUI..."
	cd work; $(PREFIX) vivado zynq/zynq.xpr $(POSTFIX)

#This is export hardware files so they can be used in sdk
export_hardware : 
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/export_hardware.tcl -log export_hardware.log -jou export_hardware.jou -notrace $(POSTFIX)
	exit 0

export_hardware_dbe :
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/export_hardware_dbe.tcl -log export_hardware.log -jou export_hardware.jou -notrace $(POSTFIX)
	exit 0

sdk_project_dbe :
	cd work; $(PREFIX) xsdk $(XSCTCOMOPS) -source $(ROOTDIR)/scripts/sdk_project_dbe.tcl $(POSTFIX)
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
	@echo "all (setup_breakout)"
	@echo "setup_breakout"
	@echo "setup_dbe_aliveness"
	@echo "save_trenz_design"
	@echo "save_dbe_bd"
	@echo "compile (Broken at moment)"
	@echo "setup_breakout"
	@echo "export_hardware"
	@echo "export_hardware_dbe"
	@echo "clean"
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
