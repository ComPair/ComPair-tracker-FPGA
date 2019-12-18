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

#include "vata_util.h"
#include "vata_constants.h"

#define DEFAULT_CYCLE_TIME 100000000 // One second.

int main(int argc, char **argv)
{
    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }
    
    u32 cycle_time;
    if (argc > 2) {
        cycle_time = (u32)atoi(argv[2]);
    } else {
        cycle_time = DEFAULT_CYCLE_TIME;
    }

    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);

    paxi[POWER_CYCLE_REG_OFFSET] = cycle_time;
    paxi[0] = (u32)AXI0_CTRL_POWER_CYCLE; // trigger power cycle.

    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        return 1;
    }

    close(axi_fd);
    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
