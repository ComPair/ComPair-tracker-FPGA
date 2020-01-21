#ifndef __DATA_PACKET_H__
#define __DATA_PACKET_H__
#include <string>
#include "vata_ctrl.hpp"

// Size of expected data packet from asic,
// with some room.
#define ASIC_NDATA 32 // N_ASIC_PACKET * 2

#define DP_TIMEOUT_FLAG 0x0001

class DataPacket {
    private:
        u16 flags;
        u64 real_time;
        u64 live_time;
        u16 event_type;
        u32 event_counter;
        u16 ndata[N_VATA];
        u16 nfifo[N_VATA];
        u32 *asic_data[N_VATA];

    public:
        DataPacket();
        ~DataPacket();
        void collect_header_data(VataCtrl *vatas);
        u8 get_header_size();
        u16 get_packet_size();
        void set_timeout();
        bool read_vata_data(int i, VataCtrl *vatas);
        void to_msg(u16 packet_size, char *buf);
        bool need_data[N_VATA];
        int nread;

};

#endif
// vim: set ts=4 sw=4 sts=4 et:
