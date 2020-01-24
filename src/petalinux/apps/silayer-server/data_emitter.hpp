#ifndef __DATA_EMITTER_H__
#define __DATA_EMITTER_H__

#define ZMQ_BUILD_DRAFT_API

#include <zmq.hpp>
#include <string>
#include <thread>
#include <chrono>

#include "vata_ctrl.hpp"
#include "data_packet.hpp"

// broadcast on eth0 interface...
#define EMIT_PORT "9998"
#define FIFO_READ_TIMEOUT_US 10000   // 10 ms (timeout is in microseconts)
#define INPROC_CHANNEL "emit"

class DataEmitter {
    private:
        zmq::context_t *context;
        zmq::socket_t inproc_sock;
        zmq::socket_t emit_sock;
        VataCtrl vatas[N_VATA];
        bool running;

        bool halt_received(zmq::message_t &msg);
        bool stop_received(zmq::message_t &msg);
        bool start_received(zmq::message_t &msg);
        void check_fifos();
        void read_fifos();
        void send_data(DataPacket &dp);

    public:
        DataEmitter() = default;
        DataEmitter(zmq::context_t *ctx);
        ~DataEmitter() {};
        void operator()();
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
