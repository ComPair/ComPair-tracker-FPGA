#include <zmq.hpp>
#include <string>
#include <iostream>
#include <fstream>
#include <unistd.h>

#include "vata_ctrl.hpp"

/* Request format:
 * <N-VATA> <COMMAND> <ARGS>
 *  N-VATA: <- [0..N_VATA]
 *  COMMAND ARGS: One of the following:
 *      set-config <PATH> 
 *      get-config
 *      set-hold <HOLD>
 *      get-hold
 *      get-counters
 *      reset-counters
 *      trigger-enable
 *      trigger-disable
 *      get-event-count
 *      reset-event-count
 *      cal-pulse
 *      set-cal-dac <VALUE>
 *      get-n-fifo
 *      single-read-fifo
 */

/********************************************************************
 * process_req:                                                     *
 *     Function to process the incoming tcp requests.               *
 *     Message format:                                              *
 *         VATA CMD [ARGS]                                          *
 *         - VATA: integer, which asic is being targeted.           *
 *         - CMD : one of the supported commands.                   *
 *         - ARGS: When required, an argument to the given command. *
 *     Places data to send back to requester in `data` buffer.      * 
 *     Returns the size of the message to send bace to requester    *
 *     In the event of an error, returns < 0.                       *
 ********************************************************************/
int process_req(zmq::message_t &request, VataCtrl *vatas, char *data) {
    int req_sz = request.size();
    char *c_req = new char[req_sz + 1];
    std::memcpy(c_req, request.data(), req_sz);
    c_req[req_sz] = '\0';
    std::cout << "Received message: " << c_req << std::endl;

    char *cmd;
    int nvata = strtol(c_req, &cmd, 0);
    if (*cmd != ' ') {
        // Could not parse arg...
        std::cerr << "ERROR: first argument not a number??? " << c_req << std::endl;
        goto bail;
    } else if (nvata < 0 || nvata >= N_VATA) {
        std::cerr << "ERROR: Requested vata out of range: " << nvata << std::endl;
        goto bail;
    }
    cmd = strtok(cmd, " ");  // move to next word, initialize strtok...
    if (cmd == NULL) {
        std::cerr << "ERROR: No command provided. " << std::endl;
        goto bail; 
    }
    
    if (strncmp("set-config", cmd, 10) == 0) {
        // Make sure we can get remaining argument...
        cmd = strtok(NULL, " ");
        if (cmd == NULL) {
            std::cerr << "ERROR: could not parse set-config cmd " << std::endl;
            goto bail;
        }
        // cmd should now be a file...
        std::ifstream cfg(cmd);
        if (!cfg.good()) {
            std::cerr << "ERROR: could not open config file at " << cmd << std::endl;
            goto bail;
        }
        cfg.close();
        // Remaining on cmd should be the file path...
        if (!vatas[nvata].set_check_config(cmd)) {
            // Set config failed...
            std::cerr << "ERROR: failed to set config. " << std::endl;
            goto bail;
        }
        std::cout << "Successfully set config from " << cmd << std::endl;
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("get-config", cmd, 10) == 0) {
        std::cout << "Request: get-config: Not ready." << std::endl;
        std::memcpy(data, "not-ready", 9);
        return 9;
    } else if (strncmp("set-hold", cmd, 8) == 0) {
        cmd = strtok(NULL, " "); // cmd should now be hold delay...
        if (cmd == NULL) {
            std::cerr << "ERROR: could not parse set-hold cmd " << std::endl;
            goto bail;
        }
        char *chk;
        int hold_delay = strtol(cmd, &chk, 0);
        if (*chk != ' ' && *chk != '\0') {
            std::cerr << "ERROR: could not parse set-hold value: " << cmd << std::endl;
            goto bail;
        }
        vatas[nvata].set_hold_delay(hold_delay);
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("get-hold", cmd, 8) == 0) {
        u32 hold_delay = vatas[nvata].get_hold_delay();
        int sz = sizeof(u32);
        std::memcpy(data, &hold_delay, sz);
        return sz;
    } else if (strncmp("get-counters", cmd, 12) == 0) {
        u64 counters[2];
        int sz = sizeof(counters);
        vatas[nvata].get_counters(counters[0], counters[1]);
        std::memcpy(data, counters, sz);
        return sz;
    } else if (strncmp("reset-counters", cmd, 14) == 0) {
        vatas[nvata].reset_counters();
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("trigger-enable", cmd, 14) == 0) {
        vatas[nvata].trigger_enable();
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("trigger-disable", cmd, 15) == 0) {
        vatas[nvata].trigger_disable();
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("get-event-count", cmd, 15) == 0) {
        u32 event_count = vatas[nvata].get_event_count();
        int sz = sizeof(u32);
        std::memcpy(data, &event_count, sz);
        return sz;
    } else if (strncmp("reset-event-count", cmd, 17) == 0) {
        vatas[nvata].reset_event_count();
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("cal-pulse", cmd, 9) == 0) {
        vatas[nvata].cal_pulse_trigger();
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("set-cal-dac", cmd, 11) == 0) {
        cmd = strtok(NULL, " "); // cmd should now be cal dac value.
        if (cmd == NULL) {
            std::cerr << "ERROR: could not parse set-cal-dac cmd " << std::endl;
            goto bail;
        }
        char *chk;
        int cal_dac = strtol(cmd, &chk, 0);
        if (*chk != ' ' && *chk != '\0') {
            std::cerr << "ERROR: could not parse set-cal-dac value: " << cmd << std::endl;
            goto bail;
        }
        vatas[nvata].set_cal_dac((u32)cal_dac);
        std::memcpy(data, "ok", 2);
        return 2;
    } else if (strncmp("get-n-fifo", cmd, 10) == 0) {
        u32 n_fifo = vatas[nvata].get_n_fifo();
        int sz = sizeof(u32);
        std::memcpy(data, &n_fifo, sz);
        return sz;
    } else if (strncmp("single-read-fifo", cmd, 16) == 0) {
        std::vector<u32> fifo_data;
        int nread;
        u32 nremain;
        vatas[nvata].read_fifo(fifo_data, nread, nremain);
        int sz = nread * sizeof(u32);
        std::memcpy(data, fifo_data.data(), sz);
        return sz; 
    } else {
        std::cerr << "ERROR: Invalid command received." << cmd << std::endl;
        goto bail;
    }
    
bail:
    delete[] c_req;
    return -1;
}

int main () {
    zmq::context_t context(1);
    zmq::socket_t socket(context, ZMQ_REP);
    socket.bind("tcp://*:5555");

    VataCtrl vatas[N_VATA];
    for (int i=0; i<N_VATA; i++) {
        std::cout << "Opening vata " << i << std::endl;
        try {
            vatas[i] = VataCtrl(i);
        }
        catch (char *msg) {
            std::cerr << "Error when initializing vata " << i << std::endl;
            return 1;
        }
    }

    int ret_sz;
    char *data = new char[1024];
    while (true) {
        zmq::message_t request, response;
        socket.recv(&request);
        ret_sz = process_req(request, vatas, data);
        if (ret_sz < 0) {
            char err_msg[] = "Error processing request";
            response.rebuild(sizeof(err_msg));
            std::memcpy(response.data(), err_msg, sizeof(err_msg));
        } else {
            response.rebuild(ret_sz);
            std::memcpy(response.data(), data, ret_sz);
        }
        socket.send(response);
    }

    delete[] data;
    return 0;
}
// vim: set ts=4 sw=4 sts=4 et:
