# Standalone vatactrl

This directory contains the `vatactrl` app on its own,
to be compiled on-board the zynq

## Build instructions
scp this directory to the zynq.

scp the `zynq.sdk/bsp_petalinux/ps7_coretexa9_0/include/*.h` files to some include
directory on the zynq

ssh onto the zynq

Modify the vatactrl/Makefile's `XIL_INC_DIR` variable to point to the directory you scp'd those
xilinx header files to.

make

And you should have a `vatactrl` executable.


