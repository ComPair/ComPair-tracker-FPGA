#ifndef __MMAP_ADDR__H
#define __MMAP_ADDR__H

#include <sys/mman.h>
#include <stddef.h>
#include "vata_types.h"

u32 *mmap_addr(int fd, u32 baseaddr, u32 span);

#endif
