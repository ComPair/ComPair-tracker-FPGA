#ifndef __SILAYER_SERVER_H__
#define __SILAYER_SERVER_H__

// We are not using UDP, so ignore this:
//#define ZMQ_BUILD_DRAFT_API

#include <zmq.hpp>
#include <string>
#include <thread>

#include "cal_ctrl.hpp"
#include "dac_ctrl.hpp"
#include "sync_ctrl.hpp"
#include "vata_ctrl.hpp"

#include "data_emitter.hpp"

#define SI_SERVER_PORT     "5556"
#define DATA_BUFSZ         1024
#define LAYER_CTX_NTHREAD  1
#define EXIT_REQ_RECV_CODE 1785 // QUIT

#define SET_CONFIG_BINARY_TIMEOUT 1000 // in milliseconds

#define VERBOSE

class LayerServer {
    private:
        VataCtrl vatas[N_VATA];
        CalCtrl calctrl;
        DacCtrl dacctrl;
        SyncCtrl syncctrl;
        zmq::context_t ctx;
        zmq::socket_t socket;
        bool data_emitter_running;
        std::thread emitter_thread;
        zmq::socket_t inproc_sock;

        int _set_config(int nvata, char* &cmd);
        int _set_config_binary(int nvata);
        int _get_config(int nvata, char* &cmd);
        int _get_config_binary(int nvata);
        int _set_hold(int nvata, char* &cmd);
        int _get_hold(int nvata, char* &cmd);
        int _get_counters(int nvata, char* &cmd);
        int _reset_counters(int nvata, char* &cmd);
        int _trigger_enable(int nvata, char* &cmd);
        int _trigger_disable(int nvata, char* &cmd);
        int _get_event_count(int nvata, char* &cmd);
        int _reset_event_count(int nvata, char* &cmd);
        int _cal_pulse_ena(char* &cmd);
        int _cal_trigger_ena(char* &cmd);
        int _cal_fast_or_disable(char* &cmd);
        int _cal_pulse_width(char* &cmd);
        int _cal_trigger_delay(char* &cmd);
        int _cal_repeat_delay(char* &cmd);
        int _cal_n_pulses(char* &cmd);
        int _dac_set_delay(char* &cmd);
        int _dac_get_delay();
        int _dac_set_counts(char* &cmd);
        int _dac_get_input();
        int _sync_get_counter();

        int _get_n_fifo(int nvata, char* &cmd);

        int _process_emit_msg(char *msg);
        int _process_cal_msg(char *msg);
        int _process_dac_msg(char *msg);
        int _process_sync_msg(char *msg);
        int _process_vata_msg(char *msg);

        int _parse_positive_int(char* &cmd);
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
