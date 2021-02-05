#!/bin/bash
petalinux-package --boot --fsbl ../../../work/$BUILD/zynq/zynq.sdk/zynq_fsbl/Release/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --force
