#!/bin/bash

silayer='root@10.10.0.11'
#builddir="$(pwd)/build/tmp/work/cortexa9hf-neon-xilinx-linux-gnueabi/vatactrl/1.0-r0/build/src"
#incdir="$(pwd)/vatactrl/files/vatactrl/include"
#zynqinc="$(pwd)/../../../../ComPair-tracker-FPGA/work/zynq/zynq.sdk/standalone_bsp_0/ps7_cortexa9_0/include"
echo "Copying binaries and libraries over..."
scp -v images/linux/BOOT.BIN $silayer:/media/card/
scp -v images/linux/image.ub $silayer:/media/card/

#scp ${builddir}/vatactrl $silayer:~/bin/
#scp ${builddir}/calctrl $silayer:~/bin/
#scp ${builddir}/libsictrl.la $silayer:~/lib/
#scp ${builddir}/.libs/libsictrl.a $silayer:~/lib/
#scp ${incdir}/*.hpp $silayer:~/include/
#scp ${zynqinc}/x*.h $silayer:~/include/

##scp ${builddir}/axi_cal* $silayer:~/bin/

## vim: set ts=4 sw=4 sts=4 et: