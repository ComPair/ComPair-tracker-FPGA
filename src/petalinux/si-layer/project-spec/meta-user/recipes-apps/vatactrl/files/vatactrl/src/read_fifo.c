/*
 * Read the data Stream-MM fifo
 */
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

#include "mmap_addr.h"

#define FIFO_BASEADDR XPAR_AXI_FIFO_MM_S_0_BASEADDR
#define FIFO_HIGHADDR XPAR_AXI_FIFO_MM_S_0_HIGHADDR

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
