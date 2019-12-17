/*
 * mmap-addr
 *
 * Simple utility that provides the mmap_addr function used everywhere
 */
#include "mmap_addr.h"

u32 *mmap_addr(int fd, u32 baseaddr, u32 span) {
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED)
        return NULL;
    return (u32 *)vbase;
}

// vim: set ts=4 sw=4 sts=4 et:
