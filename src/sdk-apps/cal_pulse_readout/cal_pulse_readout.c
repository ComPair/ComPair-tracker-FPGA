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

/* Send the trigger_ena signal on the GPIO
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

#define GPIO_BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
#define GPIO_HIGHADDR XPAR_AXI_GPIO_TRIGGER_HIGHADDR

#define AXI_BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define AXI_HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR


u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

int main()
{

    int fd;

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 gpio_baseaddr = GPIO_BASEADDR;
    u32 gpio_highaddr = GPIO_HIGHADDR;
    u32 axi_baseaddr = AXI_BASEADDR;
    u32 axi_highaddr = AXI_HIGHADDR;
    u32 axi_span = axi_highaddr - axi_baseaddr + 1;
    u32 gpio_span = gpio_highaddr - gpio_baseaddr + 1;
    u32 *paxi = mmap_addr(fd, axi_baseaddr, axi_span);
    u32 *pgpio = mmap_addr(fd, gpio_baseaddr, gpio_span);

    // Trigger calibration pulse:
    paxi[0] = 3;

    // Force the readout:
    pgpio[0] = 0;
    pgpio[0] = 1;
    pgpio[0] = 0;
    
    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }
    if (munmap((void *)pgpio, gpio_span) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
