/*
 * get_conf
 *
 * This will fetch the current configuration from the ASIC
 * and write it to a file specified on command line.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

#include "xil_types.h"
#include "xparameters.h"

#include "vata_util.h"
#include "vata_constants.h"


int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "ERROR: usage: get_config N-ASIC SAVE-FILE-PATH\n");
        return 1;
    }

    int axi_fd, cfg_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    if ( (cfg_fd = open(argv[2], O_RDWR | O_SYNC | O_CREAT)) == -1) {
        fprintf(stderr, "ERROR: could not open config file: %s.\n", argv[1]);
        return 1;
    }

    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);
    if (paxi == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata axi.\n");
        return 1;
    }

    // Trigger get config:
    paxi[0] = AXI0_CTRL_GET_CONF;

    // Delay for 0.1 s (arbitrary)
    usleep(100000);
    // Read the configuration registers
    write(cfg_fd, (void *)(paxi+READ_CFG_REG_OFFSET), N_CFG_REG * sizeof(u32));

    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        fprintf(stderr, "ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        close(cfg_fd);
        return 1;
    }
    
    close(axi_fd);
    close(cfg_fd);

    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
