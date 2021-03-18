#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <cstring>
#include "dac_ctrl.hpp"

// AXI register offsets for DAC peripheral.
namespace dac_regoffs {
    int input  = 0;
    int delay  = 1;
    int select = 2;
    int write  = 3;
};

// DAC select masks
namespace dac_select_masks {
    u32 a_cal = 1 << 0;  //0b0001
    u32 a_vth = 1 << 1;  //0b0010
    u32 b_cal = 1 << 2;  //0b0100
    u32 b_vth = 1 << 3;  //0b1000
}

// Value limits for user-provided dac parameters
namespace dac_max_values {
    u32 input = 4095;
    u32 delay = 65535;
}

int parse_silayer_side(char *silayer_side_str, enum SilayerSide *silayer_side) {
    if (strncmp("A", silayer_side_str, 1) == 0) {
        *silayer_side = SideA;
    } else if (strncmp("B", silayer_side_str, 1) == 0) {
        *silayer_side = SideB;
    } else {
        return 1;
    }
    return 0;
}

int parse_dac_choice(char *dac_choice_str, enum DacChoice *dac_choice) {
    if (strncmp("cal", dac_choice_str, 3) == 0) {
        *dac_choice = CalDac;
    } else if (strncmp("vth", dac_choice_str, 3) == 0) {
        *dac_choice = VthDac;
    } else {
        return 1;
    }
    return 0;
}

int parse_set_counts_args(char *silayer_side_str, char *dac_choice_str, char *counts_str,
        SilayerSide *silayer_side, DacChoice *dac_choice, u32 *counts) {
    if (parse_silayer_side(silayer_side_str, silayer_side) != 0) {
        return 1;
    }
    if (parse_dac_choice(dac_choice_str, dac_choice) != 0) {
        return 1;
    }
    *counts = (u32)atoi(counts_str); 
    return 0; // success
}

// There should be only a single calibrator.
DacCtrl::DacCtrl() {
    axi_baseaddr = DAC_AXI_BASEADDR;
    axi_highaddr = DAC_AXI_HIGHADDR;
    paxi = NULL;
    mmap_axi();
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
    if (dac_max_values::delay < delay)
        return 1;
    paxi[dac_regoffs::delay] = delay;
    return 0;
}

// Get the current delay value.
u32 DacCtrl::get_delay() {
    return paxi[dac_regoffs::delay];
}

// Set the dac's input value
// Return 1 if you try and set a crazy value.
// Return 0 otherwise.
// This will also command dac value to be written over SPI
int DacCtrl::set_counts(enum SilayerSide silayer_side, enum DacChoice dac_choice, u32 counts) {

    if (dac_max_values::input < counts) {
        return 1;
    }

    if (silayer_side == SideA && dac_choice == CalDac) {
        paxi[dac_regoffs::select] = dac_select_masks::a_cal;
    } else if (silayer_side == SideA && dac_choice == VthDac) { 
        paxi[dac_regoffs::select] = dac_select_masks::a_vth;
    } else if (silayer_side == SideB && dac_choice == CalDac) {
        paxi[dac_regoffs::select] = dac_select_masks::b_cal;
    } else if (silayer_side == SideB && dac_choice == VthDac) {
        paxi[dac_regoffs::select] = dac_select_masks::b_vth;
    } else {
        // This should never happen now? I think.
        std::cerr << "ERROR: How did you even provide bad options????" << std::endl;
        throw "ERROR: Bad Options, nothing done.";
    }

    paxi[dac_regoffs::input] = counts;
    paxi[dac_regoffs::write] = 0;
    paxi[dac_regoffs::write] = 1;
    paxi[dac_regoffs::write] = 0;
    return 0;
}

// Get the current dac input, as stated
// at the axi register.
u32 DacCtrl::get_input() {
    return paxi[dac_regoffs::input];
}

// vim: set ts=4 sw=4 sts=4 et:
