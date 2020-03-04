#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "vata_ctrl.hpp"


VataCtrl::VataCtrl(int n) {
    if (n >= (int)N_VATA) {
        throw "ERROR: requested invalid VATA number";
    }
    vata_num = n;
    axi_baseaddr = vata_addrs[n][0];
    axi_highaddr = vata_addrs[n][1];
    data_fifo_baseaddr = vata_addrs[n][2];
    data_fifo_highaddr = vata_addrs[n][3];
    gpio_trigger_baseaddr = vata_addrs[n][4];
    gpio_trigger_highaddr = vata_addrs[n][5];
    gpio_trigger_ena_baseaddr = vata_addrs[n][6];
    gpio_trigger_ena_highaddr = vata_addrs[n][7];
    paxi = pfifo = pgpio_trigger = pgpio_trigger_ena = NULL;
}

// Destructor performs un-mmapping.
VataCtrl::~VataCtrl() {
    bool axi_ok = true, fifo_ok = true, trigger_ok = true, trigger_ena_ok = true;
    // Unmap anything that needs unmapping...
    if (paxi != NULL)
        axi_ok = (this->unmmap_addr(paxi, axi_baseaddr, axi_highaddr) == 0);
    if (pfifo != NULL)
        fifo_ok = (this->unmmap_addr(pfifo, data_fifo_baseaddr, data_fifo_highaddr) == 0);
    if (pgpio_trigger != NULL)
        trigger_ok = (this->unmmap_addr(pgpio_trigger,
                                        gpio_trigger_baseaddr,
                                        gpio_trigger_highaddr) == 0);
    if (pgpio_trigger_ena != NULL)
        trigger_ena_ok = (this->unmmap_addr(pgpio_trigger_ena,
                                            gpio_trigger_ena_baseaddr,
                                            gpio_trigger_ena_highaddr) == 0);
    if (!axi_ok || !fifo_ok || !trigger_ok || !trigger_ena_ok) {
        std::cerr << "ERROR: an unmmap_addr call failed in destructor." << std::endl;
    }
}

u32 *VataCtrl::mmap_vata_addr(int &fd, u32 baseaddr, u32 highaddr) {
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

int VataCtrl::unmmap_addr(u32 *p, u32 baseaddr, u32 highaddr) {
    u32 span = highaddr - baseaddr + 1;
    return munmap((void *)p, span);
}

int VataCtrl::mmap_axi() {
    if ((paxi = this->mmap_vata_addr(axi_fd, axi_baseaddr, axi_highaddr)) == NULL ) {
        throw "ERROR: could not mmap axi.";
    }
    return 0;
}

int VataCtrl::mmap_fifo() {
    if ((pfifo = this->mmap_vata_addr(fifo_fd,
                                      data_fifo_baseaddr,
                                      data_fifo_highaddr)) == NULL ) {
        throw "ERROR: could not mmap data fifo.";
    }
    return 0;
}

int VataCtrl::mmap_gpio_trigger() {
    if ((pgpio_trigger = this->mmap_vata_addr(trigger_fd,
                                              gpio_trigger_baseaddr,
                                              gpio_trigger_highaddr)) == NULL ) {
        throw "ERROR: could not mmap trigger gpio.";
    }
    return 0;
}

int VataCtrl::mmap_gpio_trigger_ena() {
    if ((pgpio_trigger_ena = this->mmap_vata_addr(trigger_ena_fd,
                                                  gpio_trigger_ena_baseaddr,
                                                  gpio_trigger_ena_highaddr)) == NULL ) {
        throw "ERROR: could not mmap trigger gpio.";
    }
    return 0;
}

// Set the configuration register from the given data vector.
int VataCtrl::set_config(std::vector<u32> &data) { 
    if (paxi == NULL)
        this->mmap_axi();
    for (int i=0; i<N_CFG_REG; i++)
        paxi[i+CFG_REG_OFFSET] = data[i];
    //std::copy(data.begin(), data.end(), paxi + CFG_REG_OFFSET);
    paxi[0] = AXI0_CTRL_SET_CONF;
    return 0;
}

// Utility function to read `n` u32 values from the given file.
std::vector<u32> VataCtrl::read_file_to_u32(char *fname, int n) {
    std::ifstream is;
    is.open(fname, std::ifstream::binary);
    std::vector<u32> data(n, 0);
    is.read((char *)data.data(), n*sizeof(u32));
    return data;
}

// Read config data from file, write to register.
int VataCtrl::set_config(char *fname) {
    std::vector<u32> cfg_buf = this->read_file_to_u32(fname, N_CFG_REG);
    return (this->set_config(cfg_buf));
}

// Read config data from axi register, store in vector
int VataCtrl::get_config(std::vector<u32> &data) {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[0] = AXI0_CTRL_GET_CONF;
    // Delay for 0.1s (arbitrary, definitely enough time)
    usleep(100000);
    for (int i=0; i<N_CFG_REG; i++) {
        data[i] = paxi[i+CFG_REG_OFFSET];
    }
    return 0;
}

// Get config from asic, write to the given file location.
int VataCtrl::get_config(char *fname) {
    std::vector<u32> cfg_buf(N_CFG_REG, 0);
    this->get_config(cfg_buf);
    std::ofstream fout;
    fout.open(fname, std::ofstream::binary | std::ofstream::out);
    fout.write((char *)cfg_buf.data(), N_CFG_REG * sizeof(u32));
    return 0;
}

// Set the configuration, then ask for config to be sent back
// to verify it was correctly set. Returns `true` if set/get
// were the same. `false` otherwise.
bool VataCtrl::set_check_config(std::vector<u32> &config_in) {
    std::vector<u32> config_out(N_CFG_REG, 0);
    this->set_config(config_in);
    usleep(100000); // Arbitrary delay again...
    this->get_config(config_out);
    for (int i=0; i<N_CFG_REG; i++) {
        if (config_in[i] != config_out[i])    
            return false;
    }
    return true;
}

bool VataCtrl::set_check_config(char *fname) {
    std::vector<u32> cfg_in = this->read_file_to_u32(fname, N_CFG_REG);
    return this->set_check_config(cfg_in);
}

// Set the asic's hold delay.
int VataCtrl::set_hold_delay(u32 hold_delay) {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[HOLD_TIME_REG_OFFSET] = hold_delay;
    return 0;
}

// Get the current hold delay.
u32 VataCtrl::get_hold_delay() {
    if (paxi == NULL)
        this->mmap_axi();
    return paxi[HOLD_TIME_REG_OFFSET];
}

// Read the running and live counters.
// Of course impossible to read at exactly the same time,
// but should give a good enough snap-shot.
int VataCtrl::get_counters(u64 &running, u64 &live) {
    if (paxi == NULL)
        this->mmap_axi();
    u64 clk_vals[2];
    std::memcpy((void *)clk_vals, (void *)(paxi + RUNNING_TIMER_OFFSET), 2*sizeof(u64));
    running = clk_vals[0];
    live = clk_vals[1];
    return 0;
}

// Reset the `running` and `live-time` counters.
int VataCtrl::reset_counters() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[0] = AXI0_CTRL_RST_COUNTERS;
    return 0;
}

// Return 0 if set.
// Return 1 if called with illegal mask_bit
int VataCtrl::trigger_enable(int mask_bit) {
    if (paxi == NULL)
        this->mmap_axi();
    if (mask_bit >= TRIGGER_ENA_MASK_LEN)
        return 1;
    paxi[TRIGGER_ENA_MASK_REG_OFFSET] |= (1 << mask_bit);
    return 0;
}

int VataCtrl::trigger_enable_all() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[TRIGGER_ENA_MASK_REG_OFFSET] = 0xFFFFFFFF;
    return 0;
}

// Disable trigger acceptance by the asic.
int VataCtrl::trigger_disable(int mask_bit) {
    if (paxi == NULL)
        this->mmap_axi();
    if (mask_bit >= TRIGGER_ENA_MASK_LEN)
        return 1;
    paxi[TRIGGER_ENA_MASK_REG_OFFSET] &= ~((u32)(1 << mask_bit));
    return 0;
}

int VataCtrl::trigger_disable_all() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[TRIGGER_ENA_MASK_REG_OFFSET] = 0;
    return 0;
}

u32 VataCtrl::get_trigger_ena_mask() {
    if (paxi == NULL)
        this->mmap_axi();
    return paxi[TRIGGER_ENA_MASK_REG_OFFSET];
}

// Set the trigger acknowledge timeout
int VataCtrl::set_trigger_ack_timeout(u32 ack_timeout) {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[TRIGGER_ACK_TIMEOUT_REG_OFFSET] = ack_timeout;
    return 0;
}

// Get the current trigger acknowledge timeout
u32 VataCtrl::get_trigger_ack_timeout() {
    if (paxi == NULL)
        this->mmap_axi();
    return paxi[TRIGGER_ACK_TIMEOUT_REG_OFFSET];
}




// Return the current event count.
u32 VataCtrl::get_event_count() {
    if (paxi == NULL)
        this->mmap_axi();
    return paxi[EVENT_COUNT_OFFSET];
}

// Reset the event counter.
int VataCtrl::reset_event_count() {
    if (paxi == NULL)
        this->mmap_axi();
    paxi[0] = AXI0_CTRL_RST_EV_COUNT;
    return 0;
}

// Get the number of data packets in the data fifo.
int VataCtrl::get_n_fifo() {
    if (pfifo == NULL)
        this->mmap_fifo();
    return (int)pfifo[XLLF_RDFO_OFFSET/4];
}

// Read single value from fifo
// Returns 1 if we read from the FIFO, 0 if no data was read.
// If error, return negative.
// nread will contain number of reads performed.
// nremain will contain occupancy after reading.
int VataCtrl::read_fifo(std::vector<u32> &data, int &nread, u32 &nremain) {
    if (pfifo == NULL)
        this->mmap_fifo();

    u32 rdfo = pfifo[XLLF_RDFO_OFFSET/4];
    if (rdfo == 0) {
        nremain = 0;
        return 0;
    }
    int rlr = (int)pfifo[XLLF_RLF_OFFSET/4]/4;
    if ((int)data.size() < rlr)
        data.resize(rlr);
    for (nread=0; nread<rlr; nread++) {
        data[nread] = pfifo[XLLF_RDFD_OFFSET/4];        
    }
    nremain = pfifo[XLLF_RDFO_OFFSET/4];
    return 1;
}

// In case we want to use a raw buffer (and we know what we are doing!!!)
// This is used to read the fifo once...  does not care about nremain.
int VataCtrl::read_fifo(u32 *data, int nbuffer, u32 &nread) {
    if (pfifo == NULL)
        this->mmap_fifo();

    u32 rdfo = pfifo[XLLF_RDFO_OFFSET/4];
    if (rdfo == 0) {
        return 0;
    }
    u32 rlr = pfifo[XLLF_RLF_OFFSET/4]/4;
    if (nbuffer < (int)rlr) {
        // Not enough space in the buffer!!!
        // Put rlr into the nread reference
        // in case we want to resize buffer
        nread = rlr;
        return -1;
    }
    for (nread=0; nread<rlr; nread++) {
        data[nread] = pfifo[XLLF_RDFD_OFFSET/4];        
    }
    return 1;
}

// Force a trigger.
int VataCtrl::force_trigger() {
    if ( pgpio_trigger == NULL )
        this->mmap_gpio_trigger();
    pgpio_trigger[0] = 0;
    pgpio_trigger[0] = 1;
    pgpio_trigger[0] = 0;
    return 0;
}


// vim: set ts=4 sw=4 sts=4 et:
