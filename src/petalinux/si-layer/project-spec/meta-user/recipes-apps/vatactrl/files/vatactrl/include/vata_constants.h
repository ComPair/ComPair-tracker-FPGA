#ifndef __VATA_CONSTANTS__H
#define __VATA_CONSTANTS__H
#include <stdint.h>
#include "vata_types.h"
#include "xparameters.h"

#define N_VATA 2

#define N_CFG_REG 17

#define DAQ_SERVER_ADDR     "10.10.0.100"   // DAQ computer's IP addr.
#define DATA_PACKET_PORT    5555            // Port to send data packets to

#define N_ASIC_PACKET   13  // Each asic packet should be 13 x 32 bits.
#define DATA_PACKET_HEADER_NBYTES       3   //  [N-DATA_TOT, TIME0, TIME1]

#define CFG_REG_OFFSET                  1
#define READ_CFG_REG_OFFSET             32
#define HOLD_TIME_REG_OFFSET            18
#define CAL_DAC_REG_OFFSET              19
#define POWER_CYCLE_REG_OFFSET          20
#define TRIGGER_ACK_TIMEOUT_REG_OFFSET  21

#define AXI0_CTRL_SET_CONF              0
#define AXI0_CTRL_GET_CONF              1
#define AXI0_CTRL_SET_CAL_DAC           2
#define AXI0_CTRL_TRIGGER_EXT_CAL       3
#define AXI0_CTRL_TRIGGER_INT_CAL       4
#define AXI0_CTRL_POWER_CYCLE           5

#define MAX_CAL_DAC_VAL                 4095

static VataAddr VATA_ADDRS[2] = {
    {XPAR_VATA_460P3_AXI_INTER_0_BASEADDR,
     XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR,
     XPAR_AXI_FIFO_MM_S_DATA0_BASEADDR,
     XPAR_AXI_FIFO_MM_S_DATA0_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER0_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER0_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA0_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA0_HIGHADDR},
    {XPAR_VATA_460P3_AXI_INTER_1_BASEADDR,
     XPAR_VATA_460P3_AXI_INTER_1_HIGHADDR,
     XPAR_AXI_FIFO_MM_S_DATA1_BASEADDR,
     XPAR_AXI_FIFO_MM_S_DATA1_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER1_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER1_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA1_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA1_HIGHADDR}
};

#endif

// vim: set ts=4 sw=4 sts=4 et:
