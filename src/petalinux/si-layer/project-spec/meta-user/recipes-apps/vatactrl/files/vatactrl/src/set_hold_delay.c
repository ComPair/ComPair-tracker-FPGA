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

#include "mmap_addr.h"

#define BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "ERROR: usage: set_hold_delay HOLD-DELAY\n");
        return 1;
    }

    u32 hold_delay = (u32)atoi(argv[1]);

    int fd;

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 baseaddr = BASEADDR;
    u32 highaddr = HIGHADDR;
    u32 axi_span = highaddr - baseaddr + 1;
    u32 *paxi = mmap_addr(fd, baseaddr, axi_span);

    paxi[1] = hold_delay;

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
