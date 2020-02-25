#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "cal_ctrl.hpp"

// There should be only a single calibrator.
DacCtrl::DacCtrl() {
    axi_baseaddr = DAC_AXI_BASEADDR;
    axi_highaddr = DAC_AXI_HIGHADDR;
    paxi = NULL;
    // Default settings for our flags:
    cal_pulse_ena = true;
    vata_trigger_ena = false;
    vata_fast_or_disable = false;
    // Other default settings
    cal_pulse_width = DEFAULT_DAC_PULSE_WIDTH;
    vata_trigger_delay = 0;
    repetition_delay = DEFAULT_REPETITION_DELAY;
}

// Destructor performs un-mmapping.
DacCtrl::~DacCtrl() {
    // Unmap axi...
    if (paxi != NULL)
        if (this->unmmap_axi() != 0)
            std::cerr << "ERROR: an unmmap_addr call failed in destructor." << std::endl;
}

int DacCtrl::mmap_axi() {
    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        std::cerr << "ERROR: could not open /dev/mem." << std::endl;
        throw "ERROR: could not mmap axi.";
    }
    u32 span = axi_highaddr - axi_baseaddr + 1;
    void *vbase = mmap(NULL, span, PROT_READ | PROT_WRITE, MAP_SHARED, axi_fd, axi_baseaddr);
    if (vbase == MAP_FAILED) {
        throw "ERROR: could not mmap axi.";
    }
    paxi = (u32 *)vbase;
    return 0;
}

int DacCtrl::unmmap_axi() {
    u32 span = axi_highaddr - axi_baseaddr + 1;
    return munmap((void *)paxi, span);
}

void DacCtrl::load_current_settings() {
    // Read the AXI registers to set the settings.
    if (paxi == NULL)
        mmap_axi();
    u32 ena_settings = paxi[DAC_ENA_REGOFF];
    cal_pulse_ena = (ena_settings  & 1) == 1;
    vata_trigger_ena = ((ena_settings >> 1) & 1) == 1;
    vata_fast_or_disable = ((ena_settings >> 2) & 1) == 1;
    cal_pulse_width = paxi[DAC_PULSE_WIDTH_REGOFF];
    vata_trigger_delay = paxi[DAC_TRIGGER_DELAY_REGOFF];
    repetition_delay = paxi[DAC_REPEAT_DELAY_REGOFF];
}

void DacCtrl::write_settings() {
    if (paxi == NULL)
        mmap_axi();
    // Write the configuration settings...
    u32 ena_settings = 0;
    if (vata_fast_or_disable)
        ena_settings |= (1 << 2);
    if (vata_trigger_ena)
        ena_settings |= (1 << 1);
    if (cal_pulse_ena)
        ena_settings |= 1;
    paxi[DAC_ENA_REGOFF] = ena_settings;
    paxi[DAC_PULSE_WIDTH_REGOFF] = cal_pulse_width;
    paxi[DAC_TRIGGER_DELAY_REGOFF] = vata_trigger_delay;
    paxi[DAC_REPEAT_DELAY_REGOFF] = repetition_delay;
}


// Initiate specified number of calibration/trigger pulses.
int DacCtrl::n_pulses(u32 n) {
    write_settings();
    paxi[DAC_N_PULSES_REGOFF] = n;
    paxi[DAC_INIT_REGOFF] = 1;
    paxi[DAC_INIT_REGOFF] = 0;
    return 0;
}

int DacCtrl::start_inf_pulses() {
    this->write_settings();
    paxi[DAC_N_PULSES_REGOFF] = 0;
    paxi[DAC_INIT_REGOFF] = 1;
    return 0;
}

int DacCtrl::stop_inf_pulses() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[DAC_INIT_REGOFF] = 0;
    return 0;
}

int DacCtrl::set_cal_dac(u32 dac_value) {
    if (MAX_DAC_DAC_VAL < dac_value) {
        return 1;
    }
    if (paxi == NULL)
        this->mmap_axi();
    paxi[DAC_DAC_DAC_REGOFF] = dac_value;
    paxi[DAC_SET_DAC_REGOFF] = 0;
    paxi[DAC_SET_DAC_REGOFF] = 1;
    paxi[DAC_SET_DAC_REGOFF] = 0;
    return 0;
}

// vim: set ts=4 sw=4 sts=4 et:
