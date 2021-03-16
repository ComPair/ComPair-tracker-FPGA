#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "cal_ctrl.hpp"

namespace cal_defaults {
    u32 pulse_width = 200;       // 2 us
    u32 repetition_delay = 1000; // 1 ms
};

namespace cal_regoffs {
    int enable        = 0;
    int init          = 1;
    int pulse_width   = 2;
    int trigger_delay = 3;
    int n_pulses      = 4;
    int repeat_delay  = 5;
};

// There should be only a single calibrator.
CalCtrl::CalCtrl() {
    axi_baseaddr = CAL_AXI_BASEADDR;
    axi_highaddr = CAL_AXI_HIGHADDR;
    paxi = NULL;
    // Default settings for our flags:
    cal_pulse_ena = true;
    vata_trigger_ena = false;
    vata_fast_or_disable = false;
    // Other default settings
    cal_pulse_width = cal_defaults::pulse_width;
    vata_trigger_delay = 0;
    repetition_delay = cal_defaults::repetition_delay;

    mmap_axi();


}

// Destructor performs un-mmapping.
CalCtrl::~CalCtrl() {
    // Unmap axi...
    if (paxi != NULL)
        if (this->unmmap_addr(paxi, axi_baseaddr, axi_highaddr) != 0)
            std::cerr << "ERROR: an unmmap_addr call failed in destructor." << std::endl;
}

u32 *CalCtrl::mmap_addr(int &fd, u32 baseaddr, u32 highaddr) {
    if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        std::cerr << "ERROR: could not open /dev/mem." << std::endl;
        return NULL;
    }
    u32 span = highaddr - baseaddr + 1;
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, fd, baseaddr);
    if (vbase == MAP_FAILED) {
        std::cerr << "ERROR: mmap call failed." << std::endl;
        return NULL;
    }
    return (u32 *)vbase;
}

int CalCtrl::unmmap_addr(u32 *p, u32 baseaddr, u32 highaddr) {
    u32 span = highaddr - baseaddr + 1;
    return munmap((void *)p, span);
}

int CalCtrl::mmap_axi() {
    if ((paxi = this->mmap_addr(axi_fd, axi_baseaddr, axi_highaddr)) == NULL ) {
        throw "ERROR: could not mmap axi.";
    }
    return 0;
}

void CalCtrl::write_settings() {
    // Write the configuration settings...
    paxi[cal_regoffs::enable] = (u32)((vata_fast_or_disable << 2) | (vata_trigger_ena << 1) | cal_pulse_ena);
    paxi[cal_regoffs::pulse_width] = cal_pulse_width;
    paxi[cal_regoffs::trigger_delay] = vata_trigger_delay;
    paxi[cal_regoffs::repeat_delay] = repetition_delay;
}


// Initiate specified number of calibration/trigger pulses.
int CalCtrl::n_pulses(u32 n) {
    this->write_settings();
    paxi[cal_regoffs::n_pulses] = n;
    paxi[cal_regoffs::init] = 1;
    paxi[cal_regoffs::init] = 0;
    return 0;
}

int CalCtrl::start_inf_pulses() {
    this->write_settings();
    paxi[cal_regoffs::n_pulses] = 0;
    paxi[cal_regoffs::init] = 1;
    return 0;
}

int CalCtrl::stop_inf_pulses() {
    paxi[cal_regoffs::init] = 0;
    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
