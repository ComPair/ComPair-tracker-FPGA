#ifndef __VATA_UTIL__H
#define __VATA_UTIL__H

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include "vata_types.h"
#include "vata_constants.h"

u32 *mmap_vata_addr(int *fd, u32 baseaddr, u32 highaddr);

u32 *mmap_vata_axi(int *fd, VataAddr vata_addr);
u32 *mmap_vata_trigger(int *fd, VataAddr vata_addr);
u32 *mmap_vata_trigger_ena(int *fd, VataAddr vata_addr);
u32 *mmap_vata_fifo(int *fd, VataAddr vata_addr);

int unmmap_vata_axi(u32 *paxi, VataAddr vata_addr);
int unmmap_vata_trigger(u32 *paxi, VataAddr vata_addr);
int unmmap_vata_trigger_ena(u32 *paxi, VataAddr vata_addr);
int unmmap_vata_fifo(u32 *paxi, VataAddr vata_addr);

VataAddr args2vata_addr(int argc, char **argv, int *err_status);
void printf_args2vata_err(int err_status);

#endif
