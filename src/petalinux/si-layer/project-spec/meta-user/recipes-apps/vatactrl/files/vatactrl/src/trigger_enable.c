/*
 * trigger_enable
 *
 * Enable trigger acceptance by the ASIC
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

#define GPIO_BASEADDR XPAR_AXI_GPIO_TRIGGER_ENA_BASEADDR
#define GPIO_HIGHADDR XPAR_AXI_GPIO_TRIGGER_ENA_BASEADDR

int main(int argc, char **argv)
{
    int axi_fd;
    u32 level;

    if (argc == 1) {
        // Set trigger ena high by default:
        level = 1;
    } else if (argc == 2) {
        level = (u32)atoi(argv[1]);
        if (level != 0 && level != 1) {
            printf("ERROR: must choose either 0 or 1.\n");
            return 1;
        }
    } else {
        printf("USAGE: trigger_ena [0|1]\n");
        return 1;
    }

    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    u32 gpio_span = GPIO_HIGHADDR - GPIO_BASEADDR + 1;
    u32 *pgpio = mmap_addr(axi_fd, GPIO_BASEADDR, gpio_span);

    pgpio[0] = level;

    if (munmap((void *)pgpio, gpio_span) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(axi_fd);
        return 1;
    }
    
    close(axi_fd);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
