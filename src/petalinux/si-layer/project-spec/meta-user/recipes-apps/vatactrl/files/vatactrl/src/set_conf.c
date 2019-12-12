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

#include "vata_types.h"
#include "mmap_addr.h"

#include "xparameters.h"

#define BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR

#define CFG_OFFSET 4
#define N_REG 17

int main(int argc, char **argv)
{
    int axi_fd, cfg_fd;

    if (argc != 2) {
        printf("ERROR: usage: set-conf <CFG-FILE-PATH>\n");
        return 1;
    }

    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }
    if ( (cfg_fd = open(argv[1], O_RDONLY)) == -1) {
        printf("ERROR: could not open config file: %s.\n", argv[1]);
        return 1;
    }
    

    u32 axi_span = HIGHADDR - BASEADDR + 1;
    u32 *paxi = mmap_addr(axi_fd, BASEADDR, axi_span);

    u32 *pcfg = (u32 *)mmap(NULL, N_REG * 4, PROT_READ, MAP_SHARED, cfg_fd, 0);

    int i;
    for (i=0; i<N_REG; i++) {
        paxi[i+CFG_OFFSET] = pcfg[i];
    }

    // Trigger set config:
    paxi[0] = 0;

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        close(cfg_fd);
        return 1;
    }
    if (munmap((void *)pcfg, N_REG * 4) != 0) {
        printf("ERROR: munmap() failed on config\n");
        close(cfg_fd);
        close(axi_fd);
        return 1;
    }


    close(axi_fd);
    close(cfg_fd);

    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
