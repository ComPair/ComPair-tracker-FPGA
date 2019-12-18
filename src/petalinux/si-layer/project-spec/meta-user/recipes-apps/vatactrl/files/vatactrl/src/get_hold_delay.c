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

    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);

    printf("Hold time: %u\n", paxi[HOLD_TIME_REG_OFFSET]);

    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        return 1;
    }

    close(axi_fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
