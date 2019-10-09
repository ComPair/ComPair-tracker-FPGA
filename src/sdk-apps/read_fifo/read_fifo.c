/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

#include "xil_types.h"
#include "xllfifo_hw.h"
#include "xparameters.h"

#define FIFO_BASEADDR XPAR_AXI_FIFO_MM_S_0_BASEADDR
#define FIFO_HIGHADDR XPAR_AXI_FIFO_MM_S_0_HIGHADDR

u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

int main(int argc, char **argv)
{
    int axi_fd;

    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 fifo_span = FIFO_HIGHADDR - FIFO_BASEADDR + 1;
    u32 *pfifo = mmap_addr(axi_fd, FIFO_BASEADDR, fifo_span);

    u32 isr = pfifo[0];
    printf("ISR: 0x%08X\n", isr);
    if ((isr & XLLF_INT_RC_MASK) != 0) {
        printf("Receive Complete.\n");
    }
    pfifo[0] = 0xFFFFFFFF;
    
    int i;
    u32 rdfo, rlr, val;
    for (i=0; (rdfo = pfifo[XLLF_RDFO_OFFSET/4])>0; i++) {
        rlr = pfifo[XLLF_RLF_OFFSET/4]/4; 
        printf("Read %d. Occupancy: %u. Receive Len: %u\n", i, rdfo, rlr);
        for (; rlr > 0; rlr--) {
            val = pfifo[XLLF_RDFD_OFFSET/4]; /* For using AXI4-lite this worked */
            printf("    0x%04X (%u)\n", val, val);
        }
        printf("Read done.\n");
    }
    printf("Final read occupancy: %u.\n", rdfo);
    isr = pfifo[0];
    printf("IsRxDone: %u.\n", isr & XLLF_INT_RC_MASK ? 1: 0);
    
    if (munmap((void *)pfifo, fifo_span) != 0) {
        printf("ERROR: munmap() failed on FIFO\n");
        close(axi_fd);
        return 1;
    }
    
    close(axi_fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
