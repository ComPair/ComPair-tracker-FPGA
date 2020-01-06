/* Get the running clock value and live clock value.
 * Relies on running timer registers to immediately preceed live timer.
 * Try to use memcpy to get close to sampling the running and live clocks
 * at the same time?
 *
 * Prints <running-clock> <live-clock> to standard out without any flourishes.
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

int main(int argc, char **argv)
{

    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    u64 clk_vals[2];
    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);

    memcpy((void *)clk_vals, (void *)(paxi + RUNNING_TIMER_OFFSET), 2*sizeof(u64));
    u64 running_clk = clk_vals[0];
    u64 live_clk = clk_vals[1];

    printf("%llu %llu\n", running_clk, live_clk);

    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        return 1;
    }

    close(axi_fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
