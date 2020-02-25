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

/* Set the hold delay in increments of 10ns
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

#include "xil_types.h"
#include "xparameters.h"

#define BASEADDR XPAR_BRAM_0_BASEADDR
#define HIGHADDR XPAR_BRAM_0_HIGHADDR

u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "ERROR: usage: read_bram ADDR\n");
        return 1;
    }

    int addr = atoi(argv[1]);

    int fd;

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 baseaddr = BASEADDR;
    u32 highaddr = HIGHADDR;
    u32 axi_span = highaddr - baseaddr + 1;
    u32 *paxi = mmap_addr(fd, baseaddr, axi_span);

    printf("BRAM[%d] = %u\n", addr, paxi[addr]);

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
