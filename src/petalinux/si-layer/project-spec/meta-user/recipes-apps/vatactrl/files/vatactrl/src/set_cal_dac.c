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

#include "mmap_addr.h"

#define BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

#define MAX_CAL_DAC_VAL 4095

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "ERROR: usage: set_hold_delay HOLD-DELAY\n");
        return 1;
    }

    u32 dac_val = (u32)atoi(argv[1]);

    if (dac_val > MAX_CAL_DAC_VAL) {
        fprintf(stderr, "ERROR: DAC value: %u. Max DAC value: %u\n", dac_val, MAX_CAL_DAC_VAL);
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

    paxi[2] = dac_val; // Set dac value.

    paxi[0] = (u32)2; // Fire.

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);

    return 0;
}
