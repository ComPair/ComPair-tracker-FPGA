#ifndef __DATA_PACKET_H__
#define __DATA_PACKET_H__
#include <string>
#include <chrono>
#include "vata_ctrl.hpp"

// Size of expected data packet from asic,
// with some room (should not be needed!!!
#define ASIC_NDATA   N_ASIC_PACKET

//#define DP_TIMEOUT_FLAG 0x0001

class DataPacket {
    private:
        u16 flags;
        //u64 real_time;
        //u64 live_time;
        //u16 event_type;
        //u32 event_counter;
        u16 ndata[N_VATA];
        u16 nfifo[N_VATA];
        u32 *asic_data[N_VATA];

    public:
        DataPacket();
        ~DataPacket();
        void set_packet_time();
        //void collect_header_data(VataCtrl *vatas);
        u8 get_header_size();
        u16 get_packet_size();
        void set_timeout();
        bool set_vata_data(int i, u32 *data, VataCtrl *vatas);
        bool read_vata_data(int i, VataCtrl *vatas);
        void to_msg(u16 packet_size, char *buf);
        bool is_done();
        bool need_data[N_VATA];
        int nread;
        long int event_id; // -1 when not set, otherwise the event id.
        u64 packet_time; // This should become private after debugging.

};

#endif
// vim: set ts=4 sw=4 sts=4 et:
