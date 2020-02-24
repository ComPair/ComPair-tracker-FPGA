#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "dac_ctrl.hpp"

// There should be only a single calibrator.
DacCtrl::DacCtrl() {
    axi_baseaddr = DAC_AXI_BASEADDR;
    axi_highaddr = DAC_AXI_HIGHADDR;
    paxi = NULL;
}

// Destructor performs un-mmapping.
DacCtrl::~DacCtrl() {
    // Unmap axi...
    if (paxi != NULL)
        if (unmmap_axi() != 0)
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

// Set the clock speed through the delay register
// Return 1 if the requested value is too large.
// 0 otherwise
int DacCtrl::set_delay(u32 delay) {
    if (MAX_DELAY_VAL < delay)
        return 1;
    if (paxi == NULL)
        mmap_axi();
    paxi[DAC_DELAY_REGOFF] = delay;
    return 0;
}

// Get the current delay value.
u32 DacCtrl::get_delay() {
    if (paxi == NULL)
        mmap_axi();
    return paxi[DAC_DELAY_REGOFF];
}

// Set the dac's input value
// Return 1 if you try and set a crazy value.
// Return 0 otherwise.
int DacCtrl::set_input(u32 value) {
    if (MAX_INPUT_VAL < value) {
        return 1;
    }
    if (paxi == NULL)
        this->mmap_axi();
    paxi[DAC_INPUT_REGOFF] = value;
    paxi[DAC_WRITE_REGOFF] = 0;
    paxi[DAC_WRITE_REGOFF] = 1;
    paxi[DAC_WRITE_REGOFF] = 0;
    return 0;
}

// Get the current dac input, as stated
// at the axi register.
u32 DacCtrl::get_input() {
    if (paxi == NULL)
        mmap_axi();
    return paxi[DAC_INPUT_REGOFF];
}

// vim: set ts=4 sw=4 sts=4 et: