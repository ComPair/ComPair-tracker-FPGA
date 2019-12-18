#ifndef __VATA_TYPES__H
#define __VATA_TYPES__H
#include <stdint.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct VataAddr {
    u32 axi_baseaddr;
    u32 axi_highaddr;
    u32 fifo_baseaddr;
    u32 fifo_highaddr;
    u32 trigger_baseaddr;
    u32 trigger_highaddr;
    u32 triggerena_baseaddr;
    u32 triggerena_highaddr;
} VataAddr;

#endif
