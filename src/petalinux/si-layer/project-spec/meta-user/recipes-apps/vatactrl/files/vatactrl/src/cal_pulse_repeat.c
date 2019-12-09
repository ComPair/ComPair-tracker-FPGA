/* Send the cal-pulse trigger repeatedly.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/mman.h>

#include "xil_types.h"
#include "xparameters.h"

#include "mmap_addr.h"

#define BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        printf("Usage: cal_pulse_repeat USEC\n");
        return 1;
    }
    signal(SIGINT, int_handle);

    unsigned int usecs = (unsigned int)atoi(argv[1]);
    if (usecs >= 1000000) {
        printf("Error: delay (%u) >= 1000000\n", usecs);
        return 1;
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

    while (keep_running == 1) {
        paxi[0] = 3;
        usleep(usecs);
    }
    
    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);
    return 0;
}
// vim sw=4 sts=4 ts=4 et:
