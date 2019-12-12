/* Force a trigger by sending the trigger_ena signal on the GPIO
 * User can also specify a repetition duration, and the trigger will
 * be fired with the specified period.
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

#define BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
#define HIGHADDR XPAR_AXI_GPIO_TRIGGER_HIGHADDR

static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

int main(int argc, char **argv)
{
    int fd;

    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 baseaddr = BASEADDR;
    u32 highaddr = HIGHADDR;
    u32 axi_span = highaddr - baseaddr + 1;
    u32 *paxi = mmap_addr(fd, baseaddr, axi_span);

    if (paxi == NULL) {
        fprintf(stderr, "Error mmaping address.\n");
        return 1;
    }

    unsigned int usecs;
    int retval = 0;

    if (argc == 1) {
        paxi[0] = 0;
        paxi[0] = 1;
        paxi[0] = 0;
        goto done;
    } else if (argc == 2) {
        usecs = (unsigned int)atoi(argv[1]);
        if (usecs >= 1000000) {
            printf("Error: delay (%u) >= 1000000\n", usecs);
            retval = 1;
            goto done;
        }
    } else {
        printf("Usage: force_trigger [USEC-DELAY]\n");
        retval = 1;
        goto done;
    }
    
    signal(SIGINT, int_handle);
    while (keep_running == 1) {
        paxi[0] = 1;
        paxi[0] = 0;
        usleep(usecs);
    }
    paxi[0] = 0; // Just in case?

done:
    
    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return retval;
}
// vim: set ts=4 sw=4 sts=4 et:
