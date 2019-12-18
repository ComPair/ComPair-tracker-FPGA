/*
 * set-conf
 *
 * Set the vata 460.3 configuration from a raw binary file.
 * Essentially copies the data to the configuration bram, then triggers
 * the ASIC to load configuration from bram.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

#include "xparameters.h"

#include "vata_util.h"
#include "vata_constants.h"


int main(int argc, char **argv)
{
    if (argc != 3) {
        printf("ERROR: usage: set-conf ASIC CFG-FILE-PATH\n");
        return 1;
    }

    int axi_fd, cfg_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    if ( (cfg_fd = open(argv[2], O_RDONLY)) == -1) {
        printf("ERROR: could not open config file: %s.\n", argv[1]);
        return 1;
    }
    
    u32 *paxi = mmap_vata_axi(&axi_fd, vata_addr);
    if (paxi == NULL) {
        printf("ERROR: could not mmap vata axi.\n");
        return 1;
    }

    u32 *pcfg = (u32 *)mmap(NULL, N_CFG_REG * 4, PROT_READ, MAP_SHARED, cfg_fd, 0);

    // Transfer data from file to axi config registers
    int i;
    for (i=0; i<N_CFG_REG; i++) {
        paxi[i+CFG_REG_OFFSET] = pcfg[i];
    }

    // Trigger set config:
    paxi[0] = AXI0_CTRL_SET_CONF;

    int ret = 0;
    if (unmmap_vata_axi(paxi, vata_addr) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        ret = 1;
    }

    if (munmap((void *)pcfg, N_CFG_REG * 4) != 0) {
        printf("ERROR: munmap() failed on config\n");
        ret = 1;
    }

    close(axi_fd);
    close(cfg_fd);

    return ret;
}

// vim: set ts=4 sw=4 sts=4 et:
