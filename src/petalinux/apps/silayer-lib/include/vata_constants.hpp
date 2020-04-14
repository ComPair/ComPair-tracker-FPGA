#ifndef __VATA_CONSTANTS__HPP
#define __VATA_CONSTANTS__HPP
#include "xparameters.h"
#include "xllfifo_hw.h"

// This uses the fact that number of MM-S Fifo's matches number of VATA's:
// XXX UPDATE TO SOMETHING BETTER!!!!
#define N_VATA XPAR_XLLFIFO_NUM_INSTANCES
//#define N_VATA 3

#define N_CFG_REG 17


#define N_ASIC_PACKET   16                  // Each asic packet should be 16 x 32 bits.
#define DATA_PACKET_HEADER_NBYTES       3   //  [N-DATA_TOT, TIME0, TIME1]

// AXI register offsets
#define CFG_REG_OFFSET                  1
#define READ_CFG_REG_OFFSET             31
#define HOLD_TIME_REG_OFFSET            18
#define POWER_CYCLE_REG_OFFSET          19
#define TRIGGER_ACK_TIMEOUT_REG_OFFSET  20
#define TRIGGER_ENA_MASK_REG_OFFSET     21
#define RUNNING_TIMER_OFFSET            48
#define LIVE_TIMER_OFFSET               50
#define EVENT_COUNT_OFFSET              52

// AXI control register interpretation
#define AXI0_CTRL_SET_CONF              0
#define AXI0_CTRL_GET_CONF              1
#define AXI0_CTRL_TRIGGER_INT_CAL       2
#define AXI0_CTRL_POWER_CYCLE           3
#define AXI0_CTRL_RST_EV_COUNT          4
#define AXI0_CTRL_FORCE_TRIGGER         5

// Trigger enable mask bit mapping
// 0-11: asics. 12: TM hit. 13: TM ack. 14: Force trigger
#define TRIGGER_ENA_MASK_LEN            15
#define TRIGGER_ENA_BIT_TM_HIT          12
#define TRIGGER_ENA_BIT_TM_ACK          13
#define TRIGGER_ENA_BIT_FORCE_TRIGGER   14
// Bit numbering for each asic within the trigger enable mask.
// trigger_ena_local_asics[n_asic] is the bit number for asic number `n_asic`
const int trigger_ena_local_asics[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

const u32 vata_addrs[N_VATA][4] =
    {
        { XPAR_VATA_460P3_AXI_INTER_0_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_0_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA0_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA0_HIGHADDR
        }
#   if N_VATA > 1
    ,
        { XPAR_VATA_460P3_AXI_INTER_1_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_1_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA1_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA1_HIGHADDR
        }
#   endif
#   if N_VATA > 2
    ,
        { XPAR_VATA_460P3_AXI_INTER_2_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_2_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA2_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA2_HIGHADDR
        }
#   endif
#   if N_VATA > 3
    ,
        { XPAR_VATA_460P3_AXI_INTER_3_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_3_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA3_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA3_HIGHADDR
        }
#   endif
#   if N_VATA > 4
    ,
        { XPAR_VATA_460P3_AXI_INTER_4_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_4_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA4_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA4_HIGHADDR
        }
#   endif
#   if N_VATA > 5
    ,
        { XPAR_VATA_460P3_AXI_INTER_5_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_5_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA5_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA5_HIGHADDR
        }
#   endif
#   if N_VATA > 6
    ,
        { XPAR_VATA_460P3_AXI_INTER_6_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_6_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA6_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA6_HIGHADDR
        }
#   endif
#   if N_VATA > 7
    ,
        { XPAR_VATA_460P3_AXI_INTER_7_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_7_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA7_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA7_HIGHADDR
        }
#   endif
#   if N_VATA > 8
    ,
        { XPAR_VATA_460P3_AXI_INTER_8_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_8_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA8_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA8_HIGHADDR
        }
#   endif
#   if N_VATA > 9
    ,
        { XPAR_VATA_460P3_AXI_INTER_9_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_9_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA9_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA9_HIGHADDR
        }
#   endif
#   if N_VATA > 10
    ,
        { XPAR_VATA_460P3_AXI_INTER_10_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_10_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA10_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA10_HIGHADDR
        }
#   endif
#   if N_VATA > 11
    ,
        { XPAR_VATA_460P3_AXI_INTER_11_BASEADDR
        , XPAR_VATA_460P3_AXI_INTER_11_HIGHADDR
        , XPAR_AXI_FIFO_MM_S_DATA11_BASEADDR
        , XPAR_AXI_FIFO_MM_S_DATA11_HIGHADDR
        }
#   endif
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
