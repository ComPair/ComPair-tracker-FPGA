#ifndef __VATA_ADDR__H
#define __VATA_ADDR__H
#include <stdint.h>
#include "vata_types.h"
#include "xparameters.h"

static u32 VATA_BASEADDR_ARR[2] = {XPAR_VATA_460P3_AXI_INTER_0_BASEADDR, XPAR_VATA_460P3_AXI_INTER_1_BASEADDR};
static u32 VATA_HIGHADDR_ARR[2] = {XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR, XPAR_VATA_460P3_AXI_INTER_1_HIGHADDR};

#endif
