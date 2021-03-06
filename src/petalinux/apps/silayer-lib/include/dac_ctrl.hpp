#ifndef __DAC_CTRL_HPP__
#define __DAC_CTRL_HPP__
#include <iostream>

#include "xparameters.h"
#include "xil_types.h"

#define DAC_AXI_BASEADDR XPAR_DAC121S101_0_S00_AXI_BASEADDR
#define DAC_AXI_HIGHADDR XPAR_DAC121S101_0_S00_AXI_HIGHADDR

enum SilayerSide {SideA, SideB};
enum DacChoice {CalDac, VthDac};

int parse_silayer_side(char *silayer_side_str, enum SilayerSide *silayer_side);
int parse_dac_choice(char *dac_choice, enum DacChoice *silayer_side);
int parse_set_counts_args(char *silayer_side_str, char *dac_choice_str, char *counts_str,
                          SilayerSide *silayer_side, DacChoice *dac_choice, u32 *counts);

class DacCtrl {
    public:
        DacCtrl();
        ~DacCtrl();
        int set_delay(u32 delay);
        u32 get_delay();
        int set_counts(enum SilayerSide silayer_side, enum DacChoice dac_choice, u32 counts);
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
