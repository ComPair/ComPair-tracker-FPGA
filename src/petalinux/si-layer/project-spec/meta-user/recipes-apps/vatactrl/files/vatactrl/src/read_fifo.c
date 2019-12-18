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

#include "vata_util.h"

int main(int argc, char **argv)
{
    int axi_fd, err, data_fd;
    u32 data_buf[1024];
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    if (argc > 2) {
        // Write to specified data file.
        if ((data_fd = open(argv[2], O_RDWR | O_SYNC | O_CREAT)) == -1) {
            fprintf(stderr, "ERROR: could not open data file: %s\n", argv[2]);
            return 1;
        }
    } else {
        data_fd = -1;
    }
    
    u32 *pfifo = mmap_vata_fifo(&axi_fd, vata_addr);
    if (pfifo == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata fifo.\n");
        return 1;
    }

    u32 isr = pfifo[0];
    printf("ISR: 0x%08X\n", isr);
    if ((isr & XLLF_INT_RC_MASK) != 0) {
        printf("Receive Complete.\n");
    }
    pfifo[0] = 0xFFFFFFFF; // clear reset done interrupt bits.
    
    int i, j;
    u32 rdfo, rlr, val;
    for (i=0; (rdfo = pfifo[XLLF_RDFO_OFFSET/4])>0; i++) {
        rlr = pfifo[XLLF_RLF_OFFSET/4]/4; 
        printf("Read %d. Occupancy: %u. Receive Len: %u\n", i, rdfo, rlr);
        for (j=0; j < rlr ; j++) {
            val = pfifo[XLLF_RDFD_OFFSET/4]; /* For using AXI4-lite this worked */
            printf("    0x%04X (%u)\n", val, val);
            data_buf[j] = val;
        }
        if (data_fd >= 0) {
            write(data_fd, (void *)data_buf, rlr*sizeof(u32));
        }
        printf("Read done.\n");
    }
    printf("Final read occupancy: %u.\n", rdfo);
    isr = pfifo[0];
    printf("IsRxDone: %u.\n", isr & XLLF_INT_RC_MASK ? 1: 0);
    
    if (unmmap_vata_fifo(pfifo, vata_addr) != 0) {
        printf("ERROR: munmap() failed on FIFO\n");
        close(axi_fd);
        if (data_fd >= 0) {
            close(data_fd);
        }
        return 1;
    }
    
    close(axi_fd);
    if (data_fd >= 0) {
        close(data_fd);
    }

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
