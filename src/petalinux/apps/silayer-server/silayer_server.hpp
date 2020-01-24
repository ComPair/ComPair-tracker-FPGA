#ifndef __SILAYER_SERVER_H__
#define __SILAYER_SERVER_H__

#define ZMQ_BUILD_DRAFT_API

#include <zmq.hpp>
#include <string>
#include <thread>

#include "vata_ctrl.hpp"
#include "data_emitter.hpp"

#define SI_SERVER_PORT     "5556"
#define DATA_BUFSZ         1024
#define LAYER_CTX_NTHREAD    1
#define EXIT_REQ_RECV_CODE 1785 // QUIT

#define VERBOSE

class LayerServer {
    private:
        VataCtrl vatas[N_VATA];
        zmq::context_t ctx;
        zmq::socket_t socket;
        bool data_emitter_running;
        std::thread emitter_thread;
        zmq::socket_t inproc_sock;

        int _set_config(int nvata, char* &cmd);
        int _get_config(int nvata, char* &cmd);
        int _set_hold(int nvata, char* &cmd);
        int _get_hold(int nvata, char* &cmd);
        int _get_counters(int nvata, char* &cmd);
        int _reset_counters(int nvata, char* &cmd);
        int _trigger_enable(int nvata, char* &cmd);
        int _trigger_disable(int nvata, char* &cmd);
        int _get_event_count(int nvata, char* &cmd);
        int _reset_event_count(int nvata, char* &cmd);
        int _cal_pulse(int nvata, char* &cmd);
        int _set_cal_dac(int nvata, char* &cmd);
        int _get_n_fifo(int nvata, char* &cmd);
        int _process_emit_msg(char *msg);
        void _send_could_not_process_msg();
        void _send_msg(const char *msg, int msg_sz);
        int _kill_packet_emitter();

    public:
        LayerServer(); 
        ~LayerServer() {};
        int run();
        int process_req();
        int start_packet_emitter();
        int stop_packet_emitter();
};

#endif
// vim: set ts=4 sw=4 sts=4 et:
