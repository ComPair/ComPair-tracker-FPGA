#ifndef __CAL_CTRL_HPP__
#define __CAL_CTRL_HPP__
#include <iostream>

#include "xparameters.h"
#include "xil_types.h"

#define DEFAULT_CAL_PULSE_WIDTH  200  // 2 us
#define DEFAULT_REPETITION_DELAY 1000 // 1 ms

#define CAL_AXI_BASEADDR XPAR_AXI_CAL_PULSE_0_S00_AXI_BASEADDR
#define CAL_AXI_HIGHADDR XPAR_AXI_CAL_PULSE_0_S00_AXI_HIGHADDR

#define CAL_ENA_REGOFF           0
#define CAL_INIT_REGOFF          1
#define CAL_PULSE_WIDTH_REGOFF   2
#define CAL_TRIGGER_DELAY_REGOFF 3
#define CAL_N_PULSES_REGOFF      4
#define CAL_REPEAT_DELAY_REGOFF  5

class CalCtrl {
    public:
        CalCtrl();
        ~CalCtrl();
        void write_settings();
        int n_pulses(u32 n);
        int start_inf_pulses();
        int stop_inf_pulses();
        bool cal_pulse_ena;
        bool vata_trigger_ena;
        bool vata_fast_or_disable;
        u32 cal_pulse_width;    // Width of cal pulse in clock cycles.
        u32 vata_trigger_delay; // Delay before raising the vata_trigger
        u32 repetition_delay;   // How long to wait between pulses in clock cycles.
        
    private:
        u32 *mmap_addr(int &fd, u32 baseaddr, u32 highaddr);
        int unmmap_addr(u32 *p, u32 baseaddr, u32 highaddr);
        int mmap_axi();

        u32 *paxi = NULL;
        u32 axi_baseaddr;
        u32 axi_highaddr;
        int axi_fd;
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
