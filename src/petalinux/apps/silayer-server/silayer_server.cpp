#include "silayer_server.hpp"

LayerServer::LayerServer() {
    ctx = zmq::context_t(1);
    socket = zmq::socket_t(ctx, ZMQ_REP);
    socket.bind("tcp://*:5555");
    inproc_sock = zmq::socket_t(ctx, ZMQ_PAIR);
    inproc_sock.bind("inproc://main");
    for (int i=0; i<(int)N_VATA; i++) {
        vatas[i] = VataCtrl(i);
    }
    data_emitter_running = false;
    std::cout << "Finished initializing layer server." << std::endl;
}

int LayerServer::run() {
    int ret;
    while (true) {
        ret = process_req();
        if (ret < 0) {
            std::cerr << "Request failed with errno " << ret << std::endl;
            return ret;
        }
        if (ret == EXIT_REQ_RECV_CODE)
            return 0;
    }
}


int LayerServer::start_packet_emitter() {
    if (data_emitter_running) {
        if (stop_packet_emitter() != 0)
            return 1;
    }
    inproc_sock = zmq::socket_t(ctx, zmq::socket_type::pair);
    inproc_sock.bind("inproc://main");

    emitter_thread = std::thread(
        [](zmq::context_t *ctx_ptr) {
                DataEmitter emitter_funct(ctx_ptr);
                emitter_funct();
        }, &ctx);

    data_emitter_running = true;
    return 0;
}

int LayerServer::stop_packet_emitter() {
    zmq::message_t msg(4);
    std::memcpy(msg.data(), "halt", 4);
    inproc_sock.send(msg, zmq::send_flags::none);
    #ifdef VERBOSE
    std::cout << "Joining on emitter thread." << std::endl;
    #endif
    emitter_thread.join();
    data_emitter_running = false;
    #ifdef VERBOSE
    std::cout << "Join complete." << std::endl;
    #endif
    return 0;
}

int LayerServer::_set_config(int nvata, char* &cmd) {
    cmd = strtok(NULL, " "); // Move on to file name.
    if (cmd == NULL) {
        #ifdef VERBOSE
        std::cerr << "ERROR: could not parse set-config cmd." << std::endl;
        #endif
        return 1;
    }
    std::ifstream cfg_check(cmd);
    if (!cfg_check.good()) {
        #ifdef VERBOSE
        std::cerr << "ERROR: could not open config file at " << cmd << std::endl;
        #endif
        return 1;
    }
    cfg_check.close();
    if (!vatas[nvata].set_check_config(cmd)) {
        #ifdef VERBOSE
        std::cerr << "ERROR: failed to set config." << std::endl;
        #endif
        return 1;
    }
    #ifdef VERBOSE
    std::cout << "Successfully set config from " << cmd << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_config(int nvata, char* &cmd) {
    cmd = strtok(NULL, " "); // Move on to file name.
    if (cmd == NULL) {
        #ifdef VERBOSE
        std::cerr << "ERROR: could not parse get-config cmd." << std::endl;
        #endif
        return 1;
    }
    if (vatas[nvata].get_config(cmd) != 0) {
        #ifdef VERBOSE
        std::cerr << "ERROR: failed to get config." << std::endl;
        #endif
        return 1;
    }
    #ifdef VERBOSE
    std::cout << "Successfully wrote config to " << cmd << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_set_hold(int nvata, char* &cmd) { 
    cmd = strtok(NULL, " "); // move command to hold value
    if (cmd == NULL) {
        #ifdef VERBOSE
        std::cerr << "ERROR: No hold delay provided." << std::endl;
        #endif
        return 1;
    }
    char *chk;
    int hold_delay = strtol(cmd, &chk, 0);
    if (*chk != ' ' && *chk != '\0') {
        #ifdef VERBOSE
        std::cerr << "ERROR: Could not parse hold delay." << std::endl;
        #endif
        return 1;
    }
    vatas[nvata].set_hold_delay(hold_delay);
    #ifdef VERBOSE
    std::cout << "Hold delay for vata " << nvata << " set to " << hold_delay << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_hold(int nvata, char* &cmd) { 
    u32 hold_delay = vatas[nvata].get_hold_delay();
    #ifdef VERBOSE
    std::cout << "Hold delay for vata " << nvata << ": " << hold_delay << std::endl;
    #endif
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &hold_delay, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_counters(int nvata, char* &cmd) { 
    u64 counters[2];
    int sz = sizeof(counters);
    vatas[nvata].get_counters(counters[0], counters[1]);
    #ifdef VERBOSE
    std::cout << "counters for vata " << nvata << ": "
              << counters[0] << ", " << counters[1] << std::endl;
    #endif
    zmq::message_t response(sz);
    std::memcpy(response.data(), counters, sz);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_reset_counters(int nvata, char* &cmd) {
    vatas[nvata].reset_counters();
    #ifdef VERBOSE
    std::cout << "Reset counters for vata " << nvata << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_enable(int nvata, char* &cmd) {
    vatas[nvata].trigger_enable();
    #ifdef VERBOSE
    std::cout << "Enabled triggers for vata " << nvata << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_disable(int nvata, char* &cmd) {
    vatas[nvata].trigger_disable();
    #ifdef VERBOSE
    std::cout << "Disabled triggers for vata " << nvata << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_event_count(int nvata, char* &cmd) {
    u32 event_count = vatas[nvata].get_event_count();
    #ifdef VERBOSE
    std::cout << "Event count for vata " << nvata
              << ": " << event_count << std::endl;
    #endif
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &event_count, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_reset_event_count(int nvata, char* &cmd) {
    vatas[nvata].reset_event_count();
    #ifdef VERBOSE
    std::cout << "Reset event count for vata " << nvata << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_cal_pulse(int nvata, char* &cmd) {
    vatas[nvata].cal_pulse_trigger();
    #ifdef VERBOSE
    std::cout << "Cal pulse for vata " << nvata << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_set_cal_dac(int nvata, char* &cmd) {
    cmd = strtok(NULL, " ");
    if (cmd == NULL) {
        #ifdef VERBOSE
        std::cerr << "Could not parse cal dac command." << std::endl;
        #endif
        return 1;
    }
    char *chk;
    int cal_dac = strtol(cmd, &chk, 0);
    if (*chk != ' ' && *chk != '\0') {
        #ifdef VERBOSE
        std::cerr << "Could not parse cal dac value." << std::endl;
        #endif
        return 1;
    }
    vatas[nvata].set_cal_dac((u32)cal_dac);
    #ifdef VERBOSE
    std::cout << "Set cal dac for vata " << nvata << " to " << cal_dac << std::endl;
    #endif
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_n_fifo(int nvata, char* &cmd) {
    u32 n_fifo = vatas[nvata].get_n_fifo();
    #ifdef VERBOSE
    std::cout << "Fifo count for vata " << nvata
              << ": " << n_fifo << std::endl;
    #endif
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &n_fifo, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

void LayerServer::_send_msg(const char *msg, int msg_sz) {
    zmq::message_t response(msg_sz);
    std::memcpy(response.data(), msg, msg_sz);
    socket.send(response, zmq::send_flags::none);
}


void LayerServer::_send_could_not_process_msg() {
    const char retmsg[] = "ERROR: could not process message";
    _send_msg(retmsg, sizeof(retmsg));
}

// message should be:
// "emit start" | "emit stop" | "emit status"
// Nothing else.
int LayerServer::_process_emit_msg(char *msg) {
    // Initialize strtok...
    strtok(msg, " ");
    // Now get next token.
    char *cmd = strtok(NULL, " "); // should be "start", "stop", or "status"
    if (strncmp("status", cmd, 6) == 0) {
        if (data_emitter_running) {
            const char retmsg[] = "running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            const char retmsg[] = "stopped";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else if (strncmp("start", cmd, 5) == 0) { 
        if (data_emitter_running) {
            const char retmsg[] = "ERROR: emitter already running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            start_packet_emitter();
            const char retmsg[] = "ok";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else if (strncmp("stop", cmd, 4) == 0) {
        if (!data_emitter_running) {
            const char retmsg[] = "ERROR: emitter not running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            stop_packet_emitter();
            const char retmsg[] = "ok";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else {
        const char retmsg[] = "ERROR: unsupported emit command.";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
}


int LayerServer::process_req() {
    zmq::message_t request;
    socket.recv(request, zmq::recv_flags::none);
    int req_sz = request.size();
    char *c_req = new char[req_sz + 1];
    std::memcpy(c_req, request.data(), req_sz);
    c_req[req_sz] = '\0';
    #ifdef VERBOSE
    std::cout << "Received message: " << c_req << std::endl;
    #endif

    // First check for non-vata-targeting messages.
    //   * emit start|stop
    //   * halt
    int retval;
    if (strncmp("emit", c_req, 4) == 0) {
        #ifdef VERBOSE
        std::cout << "Processing emit message." << std::endl;
        #endif
        retval = _process_emit_msg(c_req);
        delete[] c_req;
        return retval;
    } else if (strncmp("halt", c_req, 4) == 0) {
        delete[] c_req;
        return EXIT_REQ_RECV_CODE;
    }
    
    // First get the vata we are targeting...
    char *cmd;
    int nvata = strtol(c_req, &cmd, 0);
    if (*cmd != ' ') {
        // Could not parse arg (or no command provided after arg)
        #ifdef VERBOSE
        std::cout << "ERROR: first argument not a number: " << c_req << std::endl;
        #endif
        _send_could_not_process_msg();
        return 1;
    } else if (nvata < 0 || nvata >= (int)N_VATA) {
        #ifdef VERBOSE
        std::cout << "ERROR: requested vata out of range: " << nvata << std::endl;
        #endif
        _send_could_not_process_msg();
        return 1;
    }
    // Now move on the the command
    cmd = strtok(cmd, " ");
    if (cmd == NULL) {
        #ifdef VERBOSE
        std::cout << "ERROR: no command provided." << std::endl;
        #endif
        _send_could_not_process_msg();
        return 1;
    }

    // Process command
    // retval = 0: no problem.
    // retval = 1: parse error, continue
    // retval = 2: big problem. shutdown (currently not used)
    retval = 0;
    if (strncmp("set-config", cmd, 10) == 0) {
        if (_set_config(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("get-config", cmd, 10) == 0) {
        if (_get_config(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("set-hold", cmd, 8) == 0) {
        if (_set_hold(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("get-hold", cmd, 8) == 0) {
        if (_get_hold(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("get-counters", cmd, 12) == 0) {
        if (_get_counters(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("reset-counters", cmd, 14) == 0) {
        if (_reset_counters(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("trigger-enable", cmd, 14) == 0) {
        if (_trigger_enable(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("trigger-disable", cmd, 15) == 0) {
        if (_trigger_disable(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("get-event-count", cmd, 15) == 0) {
        if (_get_event_count(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("reset-event-count", cmd, 17) == 0) {
        if (_reset_event_count(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("cal-pulse", cmd, 9) == 0) {
        if (_cal_pulse(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("set-cal-dac", cmd, 11) == 0) {
        if (_set_cal_dac(nvata, cmd) != 0)
            retval = 1;
    } else if (strncmp("get-n-fifo", cmd, 10) == 0) {
        if (_get_n_fifo(nvata, cmd) != 0)
            retval = 1;
    } else {
        #ifdef VERBOSE
        std::cerr << "Could not parse command: " << cmd << std::endl;    
        #endif
        retval = 1;
    }

    delete[] c_req;
    if (retval == 1) {
        _send_could_not_process_msg();
        return 1;
    } else {
        return 0;
    }
}

// vim: set ts=4 sw=4 sts=4 et:
