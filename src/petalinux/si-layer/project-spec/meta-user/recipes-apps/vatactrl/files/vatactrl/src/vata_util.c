/*
 * vata_util
 *
 * Utility functions.
 */
#include "vata_util.h"

//u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
//    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
//    if (vbase == MAP_FAILED)
//        return NULL;
//    return (u32 *)vbase;
//}

u32 *mmap_vata_addr(int *fd, u32 baseaddr, u32 highaddr) {
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

// mmap the axi registers of the given VataAddr
// Return NULL upon any failure
u32 *mmap_vata_axi(int *fd, VataAddr vata_addr) {
    return mmap_vata_addr(fd, vata_addr.axi_baseaddr, vata_addr.axi_highaddr);
}

u32 *mmap_vata_trigger(int *fd, VataAddr vata_addr) {
    return mmap_vata_addr(fd, vata_addr.trigger_baseaddr, vata_addr.trigger_highaddr); 
}

u32 *mmap_vata_trigger_ena(int *fd, VataAddr vata_addr) {
    return mmap_vata_addr(fd, vata_addr.triggerena_baseaddr, vata_addr.triggerena_highaddr); 
}

u32 *mmap_vata_fifo(int *fd, VataAddr vata_addr) {
    return mmap_vata_addr(fd, vata_addr.fifo_baseaddr, vata_addr.fifo_highaddr); 
}

int unmmap_vata_axi(u32 *paxi, VataAddr vata_addr) {
    u32 span = vata_addr.axi_highaddr - vata_addr.axi_baseaddr + 1; 
    return munmap((void *)paxi, span);
}

int unmmap_vata_trigger(u32 *paxi, VataAddr vata_addr) {
    u32 span = vata_addr.trigger_highaddr - vata_addr.trigger_baseaddr + 1; 
    return munmap((void *)paxi, span);
}

int unmmap_vata_trigger_ena(u32 *paxi, VataAddr vata_addr) {
    u32 span = vata_addr.triggerena_highaddr - vata_addr.triggerena_baseaddr + 1; 
    return munmap((void *)paxi, span);
}

int unmmap_vata_fifo(u32 *paxi, VataAddr vata_addr) {
    u32 span = vata_addr.fifo_highaddr - vata_addr.fifo_baseaddr + 1; 
    return munmap((void *)paxi, span);
}

// Expect that the second command line arg is VATA number.
// If there's an error, err_status will be non-zero
VataAddr args2vata_addr(int argc, char **argv, int *err_status) {
    int n_vata;
    if (argc < 2) {
        *err_status = 1;
        VataAddr ret = {0};
        return ret;
    }
    n_vata = atoi(argv[1]); 
    if (n_vata < 0 || n_vata >= N_VATA) {
        *err_status = 2;
        VataAddr ret = {0};
        return ret;
    }
    *err_status = 0;
    return VATA_ADDRS[n_vata];
}

void printf_args2vata_err(int err_status) {
    if (err_status == 1) {
        fprintf(stderr, "Require > 1 command line arg to know which VATA\n");
    } else if (err_status == 2) {
        fprintf(stderr, "Requested VATA outside allowed range.\n");
    }
}

// vim: set ts=4 sw=4 sts=4 et:
