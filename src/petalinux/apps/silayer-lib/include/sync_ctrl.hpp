#ifndef __SYNC_CTRL_HPP__
#define __SYNC_CTRL_HPP__
#include <iostream>

#include "xparameters.h"
#include "xil_types.h"

#define SYNC_AXI_BASEADDR XPAR_SYNC_VATA_DISTN_0_S00_AXI_BASEADDR 
#define SYNC_AXI_HIGHADDR XPAR_SYNC_VATA_DISTN_0_S00_AXI_HIGHADDR

class SyncCtrl {
    public:
        SyncCtrl();
        ~SyncCtrl();
        void counter_reset();
        u64 get_counter();
        void force_trigger();

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
