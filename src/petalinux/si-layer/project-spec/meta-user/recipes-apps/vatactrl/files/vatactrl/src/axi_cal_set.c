/*
 * This application should set the cal dac value.
 * Currently stand-alone to test the axi-cal-dac.
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

u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

int main(int argc, char **argv)
{
    int fd;
    if (argc != 2) {
        printf("Usage: %s VALUE\n"
               "    VALUE: non-negative integer\n", argv[0]);
        return 1;
    }

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 baseaddr = XPAR_AXI_CAL_DAC_0_S00_AXI_BASEADDR;
    u32 highaddr = XPAR_AXI_CAL_DAC_0_S00_AXI_HIGHADDR;
    u32 axi_span = highaddr - baseaddr + 1;

    printf("baseaddr: %08X\n", baseaddr);
    printf("highaddr: %08X\n", highaddr);
    u32 *paxi = mmap_addr(fd, baseaddr, axi_span);
    paxi[5] = (u32)atoi(argv[1]);
    paxi[4] = 0;
    paxi[4] = 1;
    paxi[4] = 0;

    printf("Set cal dac to %u\n", paxi[5]);
    
    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
