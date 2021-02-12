/* Set the calibration dac value
 * This sets the calibration dac pulse height.
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
    if (argc != 3) {
        fprintf(stderr, "ERROR: usage: set_hold_delay N-ASIC HOLD-DELAY\n");
        return 1;
    }

    u32 dac_val = (u32)atoi(argv[2]);
    if (dac_val > MAX_CAL_DAC_VAL) {
        fprintf(stderr, "ERROR: DAC value: %u. Max DAC value: %u\n", dac_val, MAX_CAL_DAC_VAL);
        return 1;
    }

    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);
    if (paxi == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata axi.\n");
        return 1;
    }

    paxi[CAL_DAC_REG_OFFSET] = dac_val; // Set dac value.
    paxi[0] = (u32)AXI0_CTRL_SET_CAL_DAC; // Fire.

    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        fprintf(stderr, "ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        return 1;
    }

    close(axi_fd);
    return 0;
}
// vim: set ts=4 sw=4 sts=4 et: