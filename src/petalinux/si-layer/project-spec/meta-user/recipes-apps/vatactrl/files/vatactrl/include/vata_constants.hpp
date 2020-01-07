#ifndef __VATA_CONSTANTS__HPP
#define __VATA_CONSTANTS__HPP
#include "xparameters.h"
#include "xllfifo_hw.h"

// This uses the fact that number of MM-S Fifo's matches number of VATA's:
#define N_VATA XPAR_XLLFIFO_NUM_INSTANCES

#define N_CFG_REG 17

#define DAQ_SERVER_ADDR     "192.168.1.11"   // DAQ computer's IP addr.
#define DATA_PACKET_PORT    5555            // Port to send data packets to

#define N_ASIC_PACKET   13  // Each asic packet should be 13 x 32 bits.
#define DATA_PACKET_HEADER_NBYTES       3   //  [N-DATA_TOT, TIME0, TIME1]

#define CFG_REG_OFFSET                  1
#define READ_CFG_REG_OFFSET             32
#define HOLD_TIME_REG_OFFSET            18
#define CAL_DAC_REG_OFFSET              19
#define POWER_CYCLE_REG_OFFSET          20
#define TRIGGER_ACK_TIMEOUT_REG_OFFSET  21
#define RUNNING_TIMER_OFFSET            49
#define LIVE_TIMER_OFFSET               51
#define EVENT_COUNT_OFFSET              53

#define AXI0_CTRL_SET_CONF              0
#define AXI0_CTRL_GET_CONF              1
#define AXI0_CTRL_SET_CAL_DAC           2
#define AXI0_CTRL_TRIGGER_EXT_CAL       3
#define AXI0_CTRL_TRIGGER_INT_CAL       4
#define AXI0_CTRL_POWER_CYCLE           5
#define AXI0_CTRL_RST_COUNTERS          6
#define AXI0_CTRL_RST_EV_COUNT          7

#define MAX_CAL_DAC_VAL                 4095

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

const u32 vata_addrs[N_VATA][8] = {
    {XPAR_VATA_460P3_AXI_INTER_0_BASEADDR,
     XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR,
     XPAR_AXI_FIFO_MM_S_DATA0_BASEADDR,
     XPAR_AXI_FIFO_MM_S_DATA0_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER0_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER0_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA0_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA0_HIGHADDR}
#   if N_VATA > 1
    ,{XPAR_VATA_460P3_AXI_INTER_1_BASEADDR,
     XPAR_VATA_460P3_AXI_INTER_1_HIGHADDR,
     XPAR_AXI_FIFO_MM_S_DATA1_BASEADDR,
     XPAR_AXI_FIFO_MM_S_DATA1_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER1_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER1_HIGHADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA1_BASEADDR,
     XPAR_AXI_GPIO_TRIGGER_ENA1_HIGHADDR}
#   endif
};

#endif

// vim: set ts=4 sw=4 sts=4 et:
