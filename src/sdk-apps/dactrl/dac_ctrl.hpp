#ifndef __DAC_CTRL_HPP__
#define __DAC_CTRL_HPP__
#include <iostream>

#include "xparameters.h"
#include "xil_types.h"

#define DEFAULT_DAC_PULSE_WIDTH  200  // 2 us
#define DEFAULT_REPETITION_DELAY 1000 // 1 ms

#define MAX_DAC_DAC_VAL 4095

#define DAC_AXI_BASEADDR XPAR_DAC121S101_0_S00_AXI_BASEADDR
#define DAC_AXI_HIGHADDR XPAR_DAC121S101_0_S00_AXI_HIGHADDR

#define DAC_INPUT_WORD           0
#define DAC_CLOCK_RATIO          1
#define DAC_SPARE                2
#define DAC_TRIGGER_WRITE        3


class DacCtrl {
    public:
        DacCtrl();
        ~DacCtrl();
        void write_settings();
        void load_current_settings();
        int n_pulses(u32 n);
        int start_inf_pulses();
        int stop_inf_pulses();
        int set_cal_dac(u32 dac_value);
        bool cal_pulse_ena;
        bool vata_trigger_ena;
        bool vata_fast_or_disable;
        u32 cal_pulse_width;    // Width of cal pulse in clock cycles.
        u32 vata_trigger_delay; // Delay before raising the vata_trigger
        u32 repetition_delay;   // How long to wait between pulses in clock cycles.
        
    private:
        //u32 *mmap_addr(int &fd, u32 baseaddr, u32 highaddr);
        int unmmap_axi();
        int mmap_axi();

        u32 *paxi = NULL;
        u32 axi_baseaddr;
        u32 axi_highaddr;
        int axi_fd;
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
