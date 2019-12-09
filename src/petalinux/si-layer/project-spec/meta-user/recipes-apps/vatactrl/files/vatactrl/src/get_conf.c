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

#include "mmap_addr.h"
#include "xil_types.h"
#include "xparameters.h"

#define AXI_BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define AXI_HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

#define BRAM_BASEADDR XPAR_BRAM_0_BASEADDR
#define BRAM_HIGHADDR XPAR_BRAM_0_HIGHADDR

#define N_REG 17


int main(int argc, char **argv)
{
    int axi_fd, cfg_fd;

    if (argc != 2) {
        printf("ERROR: usage: get_config <SAVE-FILE-PATH>\n");
        return 1;
    }

    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    if ( (cfg_fd = open(argv[1], O_RDWR | O_SYNC | O_CREAT)) == -1) {
        printf("ERROR: could not open config file: %s.\n", argv[1]);
        return 1;
    }

    u32 axi_span = AXI_HIGHADDR - AXI_BASEADDR + 1;
    u32 *paxi = mmap_addr(axi_fd, AXI_BASEADDR, axi_span);

    u32 bram_span = BRAM_HIGHADDR - BRAM_BASEADDR + 1;
    u32 *pbram = mmap_addr(axi_fd, BRAM_BASEADDR, bram_span);

    // Trigger get config:
    paxi[0] = 1;

    // Delay for 0.1 s (arbitrary)
    usleep(100000);
    // Copy the settings...
    write(cfg_fd, (void *)pbram, N_REG * sizeof(u32));
    //write(cfg_fd, (void *)(paxi + 2), N_REG * sizeof(u32));

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        close(cfg_fd);
        return 1;
    }
    if (munmap((void *)pbram, bram_span) != 0) {
        printf("ERROR: munmap() failed on BRAM\n");
        close(axi_fd);
        close(cfg_fd);
        return 1;
    }


    close(axi_fd);
    close(cfg_fd);

    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
