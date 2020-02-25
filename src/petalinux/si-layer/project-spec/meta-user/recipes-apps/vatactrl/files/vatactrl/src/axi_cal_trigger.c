/* cal_pulse_trigger
 *   This should cause the external calibration pulse to fire.
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

//typedef uint32_t u32;

#define BASEADDR XPAR_AXI_CAL_PULSE_0_S00_AXI_BASEADDR
#define HIGHADDR XPAR_AXI_CAL_PULSE_0_S00_AXI_HIGHADDR

#define SET_DAC_REG 4
#define CAL_DAC_REG 5
#define CAL_TRIGGER_REG 0

u32 *mmap_axi_addr(int *fd, u32 baseaddr, u32 highaddr) {
    if ( (*fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        fprintf(stderr, "ERROR: could not open /dev/mem.\n");
        return NULL;
    }
    u32 span = highaddr - baseaddr + 1;
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, *fd, baseaddr);
    if (vbase == MAP_FAILED) {
        fprintf(stderr, "ERROR: mmap call failed.\n");
        return NULL;
    }
    return (u32 *)vbase;
}

int unmmap_axi_addr(u32 *paxi, u32 baseaddr, u32 highaddr) {
    return munmap((void *)paxi, highaddr - baseaddr + 1);
}

int main(int argc, char **argv)
{
    int fd;
    u32 *paxi = mmap_axi_addr(&fd, BASEADDR, HIGHADDR);
    if (paxi == NULL) {
        fprintf(stderr, "ERROR: could not mmap axi\n");
        return 1;
    }
    paxi[CAL_TRIGGER_REG] = 0;
    paxi[CAL_TRIGGER_REG] = 1;
    paxi[CAL_TRIGGER_REG] = 0;

    if (unmmap_axi_addr(paxi, BASEADDR, HIGHADDR) != 0) {
        fprintf(stderr, "ERROR: munmap() failed on AXI\n");
        close(fd);
        return 1;
    }

    close(fd);
    return 0;
}
//vim: set ts=4 sw=4 sts=4 et:
