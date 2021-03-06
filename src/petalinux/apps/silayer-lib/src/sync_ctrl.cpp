#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>

#include "sync_ctrl.hpp"

namespace sync_regoffs {
    int cmd = 0;
    int counter = 1;
    int disable_hits = 3;
    int global_enable = 4;
};

namespace sync_cmds {
    u32 counter_rst = 0;
    u32 force_trigger = 1;
};

// There should be only a single calibrator.
SyncCtrl::SyncCtrl() {
    axi_baseaddr = SYNC_AXI_BASEADDR;
    axi_highaddr = SYNC_AXI_HIGHADDR;
    paxi = NULL;
}

// Destructor performs un-mmapping.
SyncCtrl::~SyncCtrl() {
    // Unmap axi...
    if (paxi != NULL)
        if (this->unmmap_addr(paxi, axi_baseaddr, axi_highaddr) != 0)
            std::cerr << "ERROR: unmmap_addr call failed in sync_ctrl destructor." << std::endl;
}

u32 *SyncCtrl::mmap_addr(int &fd, u32 baseaddr, u32 highaddr) {
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

int SyncCtrl::unmmap_addr(u32 *p, u32 baseaddr, u32 highaddr) {
    u32 span = highaddr - baseaddr + 1;
    return munmap((void *)p, span);
}

int SyncCtrl::mmap_axi() {
    if ((paxi = this->mmap_addr(axi_fd, axi_baseaddr, axi_highaddr)) == NULL ) {
        throw "ERROR: could not mmap axi.";
    }
    return 0;
}

void SyncCtrl::counter_reset() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::cmd] = sync_cmds::counter_rst;
}

u64 SyncCtrl::get_counter() {
    if (paxi == NULL)
        this->mmap_axi();
    u64 *pcounter;
    pcounter = (u64*)(paxi + sync_regoffs::counter);
    return *pcounter;
}

void SyncCtrl::force_trigger() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::cmd] = sync_cmds::force_trigger;
}

/* int asic_hit_disable(int asic)
 * Disable a given asic from contributing hits.
 * 0 <= asic <= N_VATA
 * Return 0 on success, 1 if you chose a bad asic.
 */
int SyncCtrl::asic_hit_disable(int asic) {
    if (asic < 0 || asic >= (int)N_VATA)
        return 1;
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::disable_hits] |= 1 << asic;
    return 0;
}

/* int asic_hit_enable(int asic)
 * Enable a given asic to contribute hits.
 * 0 <= asic <= N_VATA
 * Return 0 on success, 1 if you chose a bad asic.
 */
int SyncCtrl::asic_hit_enable(int asic) {
    if (asic < 0 || asic >= (int)N_VATA)
        return 1;
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::disable_hits] &= ~(1 << asic);
    return 0;
}

/* u32 get_asic_hit_disable_mask()
 * Return the current asic hit mask.
 */
u32 SyncCtrl::get_asic_hit_disable_mask() {
    if (paxi == NULL)
        this->mmap_axi();
    return paxi[sync_regoffs::disable_hits];
}

// Enable the global hit bit
void SyncCtrl::global_hit_enable() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::global_enable] = 1;
}

// Disable the global hit bit
void SyncCtrl::global_hit_disable() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[sync_regoffs::global_enable] = 0;
}

// Return whether the global hit bit is enabled.
bool SyncCtrl::is_global_hit_enabled() {
    if (paxi == NULL)
        this->mmap_axi();
    u32 val = paxi[sync_regoffs::global_enable] & 0x1;
    return val == 1;
}

// vim: set ts=4 sw=4 sts=4 et:
