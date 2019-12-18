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

#include "vata_util.h"

//#define BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
//#define HIGHADDR XPAR_AXI_GPIO_TRIGGER_HIGHADDR

static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

int main(int argc, char **argv)
{
    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }
    u32 *paxi = mmap_vata_trigger(&axi_fd, vata_addr);
    
    if (paxi == NULL) {
        fprintf(stderr, "Error mmaping address.\n");
        return 1;
    }

    unsigned int usecs;
    int retval = 0;

    if (argc == 2) {
        paxi[0] = 0;
        paxi[0] = 1;
        paxi[0] = 0;
        goto done;
    } else if (argc == 3) {
        usecs = (unsigned int)atoi(argv[2]);
        if (usecs >= 1000000) {
            printf("Error: delay (%u) >= 1000000\n", usecs);
            retval = 1;
            goto done;
        }
    } else {
        printf("Usage: force_trigger N-ASIC [USEC-DELAY]\n");
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
    if (unmmap_vata_trigger(paxi, vata_addr) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        retval = 1;
    }

    close(axi_fd);

    return retval;
}
// vim: set ts=4 sw=4 sts=4 et:
