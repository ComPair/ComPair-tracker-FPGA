#ifndef __VATA_CTRL_HPP__
#define __VATA_CTRL_HPP__

#include <vector>
#include <iostream>
#include <fstream>
#include <cstring>
#include <cstdint>

#include "vata_constants.hpp"

class VataCtrl {
    public:
        int vata_num;
        VataCtrl() = default;
        VataCtrl(int n);
        ~VataCtrl();
        int set_config(std::vector<u32> &data);
        int set_config(char *fname);
        int get_config(std::vector<u32> &data);
        int get_config(char *fname);
        bool set_check_config(std::vector<u32> &data);
        bool set_check_config(char *fname);
        int set_hold_delay(u32 delay);
        u32 get_hold_delay();
        int get_counters(u64 &running, u64 &live);
        int reset_counters();
        int trigger_enable(int mask_bit);
        int trigger_enable_all();
        int trigger_disable(int mask_bit);
        int trigger_disable_all();
        int trigger_enable_local_asic(int asic_number);
        int trigger_disable_local_asic(int asic_number);
        int trigger_enable_all_local_asics();
        int trigger_disable_all_local_asics();
        int trigger_enable_tm_hit();
        int trigger_disable_tm_hit();
        int trigger_enable_tm_ack();
        int trigger_disable_tm_ack();
        int trigger_enable_forced();
        int trigger_disable_forced();
        u32 get_trigger_ena_mask();
        int set_trigger_ack_timeout(u32 ack_timeout);
        u32 get_trigger_ack_timeout();
        u32 get_event_count();
        int reset_event_count();
        int get_n_fifo();
        int read_fifo(std::vector<u32> &data, int &nread, u32 &nremain);
        int read_fifo(u32 *data, int nbuffer, u32 &nread);
        int read_fifo_full_packet(u32 *data);
        //int force_trigger();
        int force_fsm_to_idle();
        
    private:
        int mmap_axi();
        int mmap_fifo();
        //int mmap_gpio_trigger();
        //int mmap_gpio_trigger_ena();
        u32 *mmap_vata_addr(int &fd, u32 baseaddr, u32 highaddr);
        int unmmap_addr(u32 *p, u32 baseaddr, u32 highaddr);
        std::vector<u32> read_file_to_u32(char *fname, int n);

        u32 *paxi = NULL;
        u32 *pfifo = NULL;
        u32 axi_baseaddr;
        u32 axi_highaddr;
        u32 data_fifo_baseaddr;
        u32 data_fifo_highaddr;

        int axi_fd;
        int fifo_fd;
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
