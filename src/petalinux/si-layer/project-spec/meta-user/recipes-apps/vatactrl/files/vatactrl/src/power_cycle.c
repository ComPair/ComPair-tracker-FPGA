/* Power cycle the ASIC.
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

#define DEFAULT_CYCLE_TIME 100000000 // One second.

int main(int argc, char **argv)
{
    u32 cycle_time;
    if (argc == 2) {
        cycle_time = (u32)atoi(argv[1]);
    } else {
        cycle_time = DEFAULT_CYCLE_TIME;
    }

    int fd;

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 baseaddr = BASEADDR;
    u32 highaddr = HIGHADDR;
    u32 axi_span = highaddr - baseaddr + 1;
    u32 *paxi = mmap_addr(fd, baseaddr, axi_span);

    paxi[3] = cycle_time;
    paxi[0] = (u32)5; // trigger power cycle.

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
