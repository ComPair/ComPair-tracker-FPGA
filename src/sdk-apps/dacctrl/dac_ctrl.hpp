#ifndef __CAL_CTRL_HPP__
#define __CAL_CTRL_HPP__
#include <iostream>

#include "xparameters.h"
#include "xil_types.h"

#define DEFAULT_CAL_PULSE_WIDTH  200  // 2 us
#define DEFAULT_REPETITION_DELAY 1000 // 1 ms

#define MAX_INPUT_VAL 4095
#define MAX_DELAY_VAL 65535

#define DAC_AXI_BASEADDR XPAR_DAC121S101_0_S00_AXI_BASEADDR
#define DAC_AXI_HIGHADDR XPAR_DAC121S101_0_S00_AXI_HIGHADDR

#define DAC_INPUT_REGOFF 0
#define DAC_DELAY_REGOFF 1
#define DAC_WRITE_REGOFF 3

class DacCtrl {
    public:
        DacCtrl();
        ~DacCtrl();
        int set_delay(u32 delay);
        u32 get_delay();
        int set_input(u32 input);
        u32 get_input();
                
    private:
        int unmmap_axi();
        int mmap_axi();

        u32 *paxi = NULL;
        u32 axi_baseaddr;
        u32 axi_highaddr;
        int axi_fd;
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
