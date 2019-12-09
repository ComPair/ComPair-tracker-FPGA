/*
 * trigger_and_acq
 *
 * Force a trigger and acquire data.
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

#define AXI_BASEADDR XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
#define AXI_HIGHADDR XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR

#define BRAM_BASEADDR XPAR_BRAM_0_BASEADDR
#define BRAM_HIGHADDR XPAR_BRAM_0_HIGHADDR

#define GPIO_BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
#define GPIO_HIGHADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR

#define NDATA 12
#define DEFAULT_DATA_FILE "data.hex"

int main(int argc, char **argv)
{
    int axi_fd;
    FILE *data_fp; 


    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }

    if (argc == 1) {
        if ( (data_fp = fopen(DEFAULT_DATA_FILE, "a")) == NULL) {
            printf("ERROR: could not open config file: %s.\n", DEFAULT_DATA_FILE);
            return 1;
        }
    } else if (argc == 2) {
        if ( (data_fp = fopen(argv[1], "a")) == NULL) {
            printf("ERROR: could not open config file: %s.\n", argv[1]);
            return 1;
        }
    } else {
        printf("ERROR: usage: trigger_and_acq [DATA-FILE-PATH]\n");
        return 1;
    }


    u32 axi_span = AXI_HIGHADDR - AXI_BASEADDR + 1;
    u32 *paxi = mmap_addr(axi_fd, AXI_BASEADDR, axi_span);

    u32 bram_span = BRAM_HIGHADDR - BRAM_BASEADDR + 1;
    u32 *pbram = mmap_addr(axi_fd, BRAM_BASEADDR, bram_span);

    u32 gpio_span = GPIO_HIGHADDR - GPIO_BASEADDR + 1;
    u32 *pgpio = mmap_addr(axi_fd, GPIO_BASEADDR, gpio_span);

    // Trigger daq.
    pgpio[0] = 0;
    pgpio[0] = 1;
    pgpio[0] = 0;

    // Delay for 0.1 s (arbitrary)
    usleep(100000);
    int i;
    //for (i=0; i < 10000 && pbram[0] != 0xFFFFFFFF; i++) {
    //}
    //if (i == 10000) {
    //    printf("ERROR: timeout waiting for data\n");
    //    close(axi_fd);
    //    fclose(data_fp);
    //    return 1;
    //}

    // dump the data....
    for (i=0; i<NDATA; i++) {
        fprintf(data_fp, "%08x", pbram[i+1]); 
    }
    fprintf(data_fp, "\n");

    if (munmap((void *)paxi, axi_span) != 0) {
        printf("ERROR: munmap() failed on AXI\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    if (munmap((void *)pbram, bram_span) != 0) {
        printf("ERROR: munmap() failed on BRAM\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    if (munmap((void *)pgpio, gpio_span) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(axi_fd);
        fclose(data_fp);
        return 1;
    }
    
    close(axi_fd);
    fclose(data_fp);

    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
