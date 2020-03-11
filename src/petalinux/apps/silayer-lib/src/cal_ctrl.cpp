#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "cal_ctrl.hpp"

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
    cal_pulse_width = DEFAULT_CAL_PULSE_WIDTH;
    vata_trigger_delay = 0;
    repetition_delay = DEFAULT_REPETITION_DELAY;
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
    if (paxi == NULL)
        this->mmap_axi();
    // Write the configuration settings...
    paxi[CAL_ENA_REGOFF] = (u32)((vata_fast_or_disable << 2) | (vata_trigger_ena << 1) | cal_pulse_ena);
    paxi[CAL_PULSE_WIDTH_REGOFF] = cal_pulse_width;
    paxi[CAL_TRIGGER_DELAY_REGOFF] = vata_trigger_delay;
    paxi[CAL_REPEAT_DELAY_REGOFF] = repetition_delay;
}


// Initiate specified number of calibration/trigger pulses.
int CalCtrl::n_pulses(u32 n) {
    this->write_settings();
    paxi[CAL_N_PULSES_REGOFF] = n;
    paxi[CAL_INIT_REGOFF] = 1;
    paxi[CAL_INIT_REGOFF] = 0;
    return 0;
}

int CalCtrl::start_inf_pulses() {
    this->write_settings();
    paxi[CAL_N_PULSES_REGOFF] = 0;
    paxi[CAL_INIT_REGOFF] = 1;
    return 0;
}

int CalCtrl::stop_inf_pulses() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[CAL_INIT_REGOFF] = 0;
    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
