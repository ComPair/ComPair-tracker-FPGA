#
#  ComPair Trakcer FEE project makefile
#

ROOTDIR=..

# Common Vivado options
VIVADOCOMOPS = -mode batch

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

SETUP_EVAL = -source $(ROOTDIR)/scripts/setup_trenz_breakout.tcl -log setup.log -jou setup.jou

all: setup_breakout
	
# Setup the Trenz/Zynq base project
setup_breakout : .\work\.setup.done
.\work\.setup.done :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Running Trenz TE0703 setup"
	mkdir -p work
	echo $(PWD)
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) $(SETUP_EVAL) -notrace $(POSTFIX)

compile : .\work\.compile.done
.\work\.compile.done : .\work\.setup.done
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/compile.tcl -log compile.log -jou compile.jou $(POSTFIX)


	#This is export hardware files so they can be used in sdk
export_hardware :
	cd work; $(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/export_hardware.tcl -log export_hardware.log -jou export_hardware.jou -notrace $(POSTFIX)
	exit 0


# Launch the Vivado gui.
launchgui :
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Launching GUI..."
	cd work; $(PREFIX) vivado zynq/zynq.xpr $(POSTFIX)


# Remove the work directory. Cannot be undone!
clean:
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++"
	@echo "    Removing working directory."
	rm -rf work	