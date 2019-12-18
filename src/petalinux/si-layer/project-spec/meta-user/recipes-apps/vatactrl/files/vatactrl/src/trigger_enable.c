/*
 * trigger_enable
 *
 * Enable/disable trigger acceptance by the ASIC
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
    u32 level;
    if (argc == 1) {
        printf("USAGE: %s N-ASIC [0|1]\n", argv[0]);
    }
    if (argc == 2) {
        // Set trigger ena high by default:
        level = 1;
    } else if (argc == 3) {
        level = (u32)atoi(argv[2]);
        if (level != 0 && level != 1) {
            printf("ERROR: must choose either 0 or 1.\n");
            return 1;
        }
    } else {
        printf("USAGE: %s N-ASIC [0|1]\n", argv[0]);
        return 1;
    }

    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }
    
    u32 *pgpio = mmap_vata_trigger_ena(&axi_fd, vata_addr);
    pgpio[0] = level;

    if (unmmap_vata_trigger_ena(pgpio, vata_addr) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(axi_fd);
        return 1;
    }
    
    close(axi_fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
