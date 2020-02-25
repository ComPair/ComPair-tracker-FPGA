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

/*
 * test_port_map_v1
 *
 * This application is meant to check that we are setting voltages on the GALAO
 * lines correctly.
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

#define AXI_BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define AXI_HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

#define BRAM_BASEADDR XPAR_BRAM_0_BASEADDR
#define BRAM_HIGHADDR XPAR_BRAM_0_HIGHADDR

#define GPIO_BASEADDR XPAR_AXI_GPIO_0_BASEADDR
#define GPIO_HIGHADDR XPAR_AXI_GPIO_0_BASEADDR

#define NDATA 12
#define DEFAULT_DATA_FILE "data.hex"

u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

int main(int argc, char **argv)
{
    int axi_fd;
    FILE *data_fp; 


    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    if (argc == 1) {
        if ( (data_fp = fopen(DEFAULT_DATA_FILE, "a")) == NULL) {
            printf("ERROR: could not open config file: %s.\n", DEFAULT_DATA_FILE);
            return 1;
        }
    } else if (argc == 2) {
        if ( (data_fp = fopen(argv[1], "a")) == NULL) {
            printf("ERROR: could not open config file: %s.\n", argv[1]);
            return 1;
        }
    } else {
        printf("ERROR: usage: trigger_and_acq [DATA-FILE-PATH]\n");
        return 1;
    }


    u32 axi_span = AXI_HIGHADDR - AXI_BASEADDR + 1;
    u32 *paxi = mmap_addr(axi_fd, AXI_BASEADDR, axi_span);

    u32 bram_span = BRAM_HIGHADDR - BRAM_BASEADDR + 1;
    u32 *pbram = mmap_addr(axi_fd, BRAM_BASEADDR, bram_span);

    u32 gpio_span = GPIO_HIGHADDR - GPIO_BASEADDR + 1;
    u32 *pgpio = mmap_addr(axi_fd, GPIO_BASEADDR, gpio_span);

    // Trigger daq.
    pgpio[0] = 1;
    pgpio[0] = 0;

    // Delay for 0.1 s (arbitrary)
    //usleep(100000);
    int i;
    for (i=0; i < 10000 && pbram[0] != 0xFFFFFFFF; i++) {
    }
    if (i == 10000) {
        printf("ERROR: timeout waiting for data\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }

    // dump the data....
    for (i=0; i<NDATA; i++) {
        fprintf(data_fp, "%08x", pbram[i+1]); 
    }
    fprintf(data_fp, "\n");

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    if (munmap((void *)pbram, bram_span) != 0) {
        printf("ERROR: munmap() failed on BRAM\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    if (munmap((void *)pgpio, gpio_span) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    
    close(axi_fd);
    fclose(data_fp);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
