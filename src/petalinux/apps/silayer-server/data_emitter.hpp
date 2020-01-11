#ifndef __DATA_EMITTER_H__
#define __DATA_EMITTER_H__

#include <zmq.hpp>
#include <string>
#include <thread>
#include <chrono>

#include "vata_ctrl.hpp"

#define VERBOSE

// broadcast on eth0 interface...
#define UDP_ADDR "udp://eth0:9999"

#define FIFO_READ_TIMEOUT 10000   // 10 ms, or 1000000 clock cycles

// NDATA per asic...
//// this is actually in vata_constants.hpp as N_ASIC_PACKET...

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

class DataEmitter {
    private:
        zmq::context_t *context;
        zmq::socket_t inproc_sock;
        zmq::socket_t emit_sock;
        VataCtrl vatas[N_VATA];

        bool halt_received(zmq::message_t &msg);
        void check_fifos();
        void read_fifos();
        void send_data(DataPacket &dp);

    public:
        DataEmitter(zmq::context_t *ctx);
        ~DataEmitter();
        void operator()();
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
