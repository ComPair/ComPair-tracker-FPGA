#include "silayer_server.hpp"

LayerServer::LayerServer() {
    ctx = zmq::context_t(1);
    socket = zmq::socket_t(ctx, zmq::socket_type::rep);
    socket.setsockopt(ZMQ_LINGER, (int)0);
    socket.bind("tcp://*:" SI_SERVER_PORT);
    inproc_sock = zmq::socket_t(ctx, zmq::socket_type::pair);
    inproc_sock.bind("inproc://" INPROC_CHANNEL);
    for (int i=0; i<(int)N_VATA; i++) {
        vatas[i] = VataCtrl(i);
    }

    // Create the emitter thread with a lambda-function,
    // which calls DataEmitter::operator to run the main emitter loop.
    emitter_thread = std::thread(
        [](zmq::context_t *ctx_ptr) {
                DataEmitter emitter_funct(ctx_ptr);
                emitter_funct();
        }, &ctx);

    data_emitter_running = false;
    LOG_F(INFO, "Silayer server finished initializing.");
}

int LayerServer::run() {
    int ret;
    LOG_F(INFO, "Starting silayer server loop.");
    while (true) {
        ret = process_req();
        if (ret < 0) {
            LOG_F(ERROR, "Request failed with errno %d", ret);
            return ret;
        }
        if (ret == EXIT_REQ_RECV_CODE) {
            LOG_F(INFO, "Server received an exit request. Exiting.");
            return 0;
        }
    }
}


int LayerServer::start_packet_emitter() {
    if (data_emitter_running) {
        if (stop_packet_emitter() != 0)
            return 1;
    }
    zmq::message_t msg(5);
    std::memcpy(msg.data(), "start", 5);
    inproc_sock.send(msg, zmq::send_flags::none);
    data_emitter_running = true;
    return 0;
}

int LayerServer::stop_packet_emitter() {
    zmq::message_t msg(5);
    std::memcpy(msg.data(), "stop", 5);
    inproc_sock.send(msg, zmq::send_flags::none);
    data_emitter_running = false;
    return 0;
}

// Have packet emitter exit...
int LayerServer::_kill_packet_emitter() {
    zmq::message_t msg(4);
    std::memcpy(msg.data(), "halt", 4);
    inproc_sock.send(msg, zmq::send_flags::none);

    LOG_F(INFO, "Joining on emitter thread.");
    emitter_thread.join();
    LOG_F(INFO, "Joining complete.");
    data_emitter_running = false;
    return 0;
}

int LayerServer::_set_config(int nvata, char* &cmd) {
    cmd = strtok(NULL, " "); // Move on to file name.
    if (cmd == NULL) {
        LOG_F(ERROR, "Could not parse set-config cmd.");
        return 1;
    }
    std::ifstream cfg_check(cmd);
    if (!cfg_check.good()) {
        LOG_F(ERROR, "Could not open config file at %s.", cmd);
        return 1;
    }
    cfg_check.close();
    if (!vatas[nvata].set_check_config(cmd)) {
        LOG_F(ERROR, "Failed to set config.");
        return 1;
    }
    LOG_F(INFO, "Successfully set config from %s.", cmd);
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_set_config_binary(int nvata) {
    // We received a set-config-binary message.
    // This will now:
    //   * send "ready" message to client
    //   * wait 1 second to receive the config data.
    //   * upon receiving config data, set config data.
    //   * send "ok" if successfully set the config data. Otherwise "error"
    zmq::message_t ready_msg(5);
    std::memcpy(ready_msg.data(), "ready", 5);
    socket.send(ready_msg, zmq::send_flags::none);

    // Set up to poll...
    zmq::pollitem_t items[] = {
        {static_cast<void*>(socket), 0, ZMQ_POLLIN, 0}
    };
    zmq::poll(items, 1, SET_CONFIG_BINARY_TIMEOUT);
    if (!(items[0].revents & ZMQ_POLLIN)) {
        // We did not receive a response in time.
        // Bail without sending anything.
        LOG_F(ERROR, "Timeout after sending 'ready' message.");
        return 1;
    }
    zmq::message_t config_msg;

    socket.recv(config_msg, zmq::recv_flags::none);
    int req_sz = config_msg.size();
    if (req_sz != (N_CFG_REG * sizeof(u32))) {
        LOG_F(ERROR, "Received config data of unsupported size: %d bytes", req_sz);
        const char errmsg[] = "error: req_sz";
        _send_msg(errmsg, sizeof(errmsg));
        return 2;
    }
    std::vector<u32> data(N_CFG_REG, 0);
    std::memcpy((char *)data.data(), config_msg.data(), req_sz);
    
    if (vatas[nvata].set_check_config(data)) {
        // Configuration set successful
        LOG_F(INFO, "Set config successful.");
        const char retmsg[] = "ok";
        _send_msg(retmsg, sizeof(retmsg));
        return 0;
    } else {
        // Configuration set failed.
        LOG_F(ERROR, "Configuration check failed on vata %d.", nvata);
        const char errmsg[] = "error: config_check";
        _send_msg(errmsg, sizeof(errmsg));
        return 3;
    }
}

int LayerServer::_get_config(int nvata, char* &cmd) {
    cmd = strtok(NULL, " "); // Move on to file name.
    if (cmd == NULL) {
        LOG_F(ERROR, "Could not parse get-config cmd.");
        return 1;
    }
    if (vatas[nvata].get_config(cmd) != 0) {
        LOG_F(ERROR, "Failed to get configuration from vata %d.", nvata);
        return 1;
    }
    LOG_F(INFO, "Configuration for vata %d written to file %s.", nvata, cmd);
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_config_binary(int nvata) {
    std::vector<u32> data(N_CFG_REG, 0);
    vatas[nvata].get_config(data);
    zmq::message_t response(N_CFG_REG * sizeof(u32));
    std::memcpy(response.data(), data.data(), N_CFG_REG * sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_set_hold(int nvata, char* &cmd) { 
    cmd = strtok(NULL, " "); // move command to hold value
    if (cmd == NULL) {
        LOG_F(ERROR, "No hold delay provided for set_hold command");
        return 1;
    }
    char *chk;
    int hold_delay = strtol(cmd, &chk, 0);
    if (*chk != ' ' && *chk != '\0') {
        LOG_F(ERROR, "Could not parse hold delay.");
        return 1;
    }
    vatas[nvata].set_hold_delay(hold_delay);
    LOG_F(INFO, "Hold delay for vata %d set to %d", nvata, hold_delay);
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_hold(int nvata, char* &cmd) { 
    u32 hold_delay = vatas[nvata].get_hold_delay();
    LOG_F(INFO, "get_hold_delay() for vata %d: %d.", nvata, hold_delay);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &hold_delay, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_counters(int nvata, char* &cmd) { 
    u64 counters[2];
    int sz = sizeof(counters);
    vatas[nvata].get_counters(counters[0], counters[1]);
    LOG_F(INFO, "get_counters() for vata %d: %lu, %lu", nvata, counters[0], counters[1]);
    zmq::message_t response(sz);
    std::memcpy(response.data(), counters, sz);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_reset_counters(int nvata, char* &cmd) {
    vatas[nvata].reset_counters();
    LOG_F(INFO, "Reset counters for vata %d", nvata);
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_enable_bit(int nvata, char* &cmd) {
    int bitnum;
    if ((bitnum = _parse_positive_int(cmd)) >= 0) {
        if (vatas[nvata].trigger_enable(bitnum) != 0) {
            LOG_F(ERROR, "trigger_enable for vata %d returned non-zero exit status.", nvata);
            return 1;
        }
        LOG_F(INFO, "Enabled trigger #%d for vata %d", bitnum, nvata);
    } else if (strncmp(cmd, "all", 3) == 0) {
        vatas[nvata].trigger_enable_all(); 
        LOG_F(INFO, "Enabled all triggers for vata %d", nvata);
    } else {
        LOG_F(ERROR, "Could not parse trigger enable bit number.");
        return 1;
    }
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_disable_bit(int nvata, char* &cmd) {
    int bitnum;
    if ((bitnum = _parse_positive_int(cmd)) >= 0) {
        if (vatas[nvata].trigger_disable(bitnum) != 0) {
            LOG_F(ERROR, "trigger_disable for vata %d returned non-zero exit status.", nvata);
            return 1;
        }
        LOG_F(INFO, "Disabled trigger #%d for vata %d.", bitnum, nvata);
    } else if (strncmp(cmd, "all", 3) == 0) {
        vatas[nvata].trigger_disable_all(); 
        LOG_F(INFO, "Disabled all triggers vata %d.", nvata);
    } else {
        LOG_F(ERROR, "Could not parse trigger disable bit number.");
        return 1;
    }
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_enable_asic(int nvata, char* &cmd) {
    int asicnum;
    if ((asicnum = _parse_positive_int(cmd)) >= 0) {
        if (vatas[nvata].trigger_enable_local_asic(asicnum) != 0) {
            LOG_F(ERROR, "trigger_enable_local_asic(%d) returned non-zero exit status for vata %d.", asicnum, nvata);
            return 1;
        }
        LOG_F(INFO, "Enabled asic #%d for triggers for vata %d.", asicnum, nvata);
    } else if (strncmp(cmd, "all", 3) == 0) {
        vatas[nvata].trigger_enable_all_local_asics(); 
        LOG_F(INFO, "Enabled all local asic triggers for vata %d..", nvata);
    } else {
        LOG_F(ERROR, "Could not parse trigger enable asic number.");
        const char retmsg[] = "E: could not parse asic number";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_disable_asic(int nvata, char* &cmd) {
    int asicnum;
    if ((asicnum = _parse_positive_int(cmd)) >= 0) {
        if (vatas[nvata].trigger_disable_local_asic(asicnum) != 0) {
            LOG_F(ERROR, "trigger_disable_local_asic(%d) returned non-zero exit status for vata %d.", asicnum, nvata);
            const char retmsg[] = "E: trigger_disable_local_asic failed.";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
        LOG_F(INFO, "Disabled asic #%d triggers for vata %d.", asicnum, nvata);
    } else if (strncmp(cmd, "all", 3) == 0) {
        vatas[nvata].trigger_disable_all_local_asics(); 
        LOG_F(INFO, "Disabled all local asic triggers for vata %d.", nvata);
    } else {
        LOG_F(ERROR, "Could not parse trigger disable asic number.");
        const char retmsg[] = "E: could not parse asic number";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_trigger_enable_tm_hit(int nvata) {
    LOG_F(INFO, "Enabling TM hit triggers for vata %d.", nvata);
    int ret;
    if ((ret = vatas[nvata].trigger_enable_tm_hit()) == 0) {
        const char retmsg[] = "ok";
        _send_msg(retmsg, sizeof(retmsg));
    } else {
        LOG_F(ERROR, "trigger_enable_tm_hit() failed for vata %d.", nvata);
        const char retmsg[] = "E: trigger_enable_tm_hit failed.";
        _send_msg(retmsg, sizeof(retmsg));
    }
    return ret;
}

int LayerServer::_trigger_disable_tm_hit(int nvata) {
    LOG_F(INFO, "Disabling TM hit triggers for vata %d.", nvata);
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return vatas[nvata].trigger_disable_tm_hit();
}

int LayerServer::_trigger_enable_tm_ack(int nvata) {
    LOG_F(INFO, "Enabling TM ack triggers for vata %d.", nvata);
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return vatas[nvata].trigger_enable_tm_ack();
}

int LayerServer::_trigger_disable_tm_ack(int nvata) {
    LOG_F(INFO, "Disabling TM ack triggers for vata %d.", nvata);
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return vatas[nvata].trigger_disable_tm_ack();
}

int LayerServer::_trigger_enable_forced(int nvata) {
    LOG_F(INFO, "Enabling forced triggers for vata %d.", nvata);
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return vatas[nvata].trigger_enable_forced();
}

int LayerServer::_trigger_disable_forced(int nvata) {
    LOG_F(INFO, "Disabling forced triggers for vata %d.", nvata);
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return vatas[nvata].trigger_disable_forced();
}

int LayerServer::_get_trigger_ena_mask(int nvata) {
    u32 trigger_mask = vatas[nvata].get_trigger_ena_mask();
    LOG_F(INFO, "Retrieved trigger enable mask for vata %d: %lu.", nvata, trigger_mask);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &trigger_mask, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_get_event_count(int nvata, char* &cmd) {
    u32 event_count = vatas[nvata].get_event_count();
    LOG_F(INFO, "Retrieved event count for vata %d: %lu.", nvata, event_count);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &event_count, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_reset_event_count(int nvata, char* &cmd) {
    vatas[nvata].reset_event_count();
    LOG_F(INFO, "Reset event count for vata %d.", nvata);
    zmq::message_t response(2);
    std::memcpy(response.data(), "ok", 2);
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_parse_positive_int(char* &cmd) {
    cmd = strtok(NULL, " "); // move command to ena/dis
    if (cmd == NULL) {
        return -1;
    }
    char *chk;
    int ret = strtol(cmd, &chk, 0);
    if (*chk != ' ' && *chk != '\0') {
        return -1;
    }
    return ret;
}

int LayerServer::_cal_pulse_ena(char* &cmd) {
    int pulse_ena = _parse_positive_int(cmd);
    if (pulse_ena < 0) {
        LOG_F(ERROR, "Could not parse pulse enable setting.");
        return 1;
    }
    if (pulse_ena == 0) {
        LOG_F(INFO, "Setting calctrl.cal_pulse_ena to false.");
        calctrl.cal_pulse_ena = false;
    } else if (pulse_ena == 1) {
        LOG_F(INFO, "Setting calctrl.cal_pulse_ena to true.");
        calctrl.cal_pulse_ena = true;
    } else {
        LOG_F(ERROR, "Pulse enable setting: %d. Must be 0 or 1.", pulse_ena);
        return 1;
    }
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_trigger_ena(char* &cmd) {
    int trigger_ena = _parse_positive_int(cmd);
    if (trigger_ena < 0) {
        LOG_F(ERROR, "Could not parse cal trigger enable setting.");
        return 1;
    }
    if (trigger_ena == 0) {
        LOG_F(INFO, "Setting calctrl.vata_trigger_ena to false.");
        calctrl.vata_trigger_ena = false;
    } else if (trigger_ena == 1) {
        LOG_F(INFO, "Setting calctrl.vata_trigger_ena to true.");
        calctrl.vata_trigger_ena = true;
    } else {
        LOG_F(ERROR, "calctrl vata trigger enable setting: %d. Must be 0 or 1.", trigger_ena);
        return 1;
    }
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_fast_or_disable(char* &cmd) {
    int fast_or_dis = _parse_positive_int(cmd);
    if (fast_or_dis < 0) {
        LOG_F(ERROR, "Could not parse fast-or disable setting.");
        return 1;
    }
    if (fast_or_dis == 0) {
        LOG_F(INFO, "Setting calctrl.vata_fast_or_disable to false.");
        calctrl.vata_fast_or_disable = false;
    } else if (fast_or_dis == 1) {
        LOG_F(INFO, "Setting calctrl.vata_fast_or_disable to true.");
        calctrl.vata_fast_or_disable = true;
    } else {
        LOG_F(ERROR, "calctrl fast-or disable setting: %d. Must be 0 or 1.", fast_or_dis);
        return 1;
    }
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_pulse_width(char* &cmd) {
    int pulse_width = _parse_positive_int(cmd);
    if (pulse_width < 0) {
        LOG_F(ERROR, "Could not parse pulse-width value.");
        return 1;
    }
    LOG_F(INFO, "Setting calctrl.cal_pulse_width to %d", pulse_width);
    calctrl.cal_pulse_width = (u32)pulse_width;
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_trigger_delay(char* &cmd) {
    int trigger_delay = _parse_positive_int(cmd);
    if (trigger_delay < 0) {
        LOG_F(ERROR, "Could not parse trigger-delay value.");
        return 1;
    }
    LOG_F(INFO, "Setting calctrl.vata_trigger_delay to %d", trigger_delay);
    calctrl.vata_trigger_delay = (u32)trigger_delay;
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_repeat_delay(char* &cmd) {
    int repeat_delay = _parse_positive_int(cmd);
    if (repeat_delay < 0) {
        LOG_F(ERROR, "Could not parse repeat-delay value.");
        return 1;
    }
    LOG_F(INFO, "Setting calctrl.repetition_delay to %d", repeat_delay);
    calctrl.repetition_delay = (u32)repeat_delay;
    calctrl.write_settings();
    return 0;
}

int LayerServer::_cal_n_pulses(char* &cmd) {
    int n = _parse_positive_int(cmd);
    if (n < 0) {
        LOG_F(ERROR, "Could not parse number of cal pulses.");
        return 1;
    } else if (n == 0) {
        LOG_F(ERROR, "Requested number of cal pulses cannot be 0.");
        return 2;
    }
    LOG_F(INFO, "Performing %d cal pulses", n);
    return calctrl.n_pulses((u32)n);
}

int LayerServer::_get_n_fifo(int nvata, char* &cmd) {
    u32 n_fifo = vatas[nvata].get_n_fifo();
    LOG_F(INFO, "FIFO count for vata %d: %lu", nvata, n_fifo);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &n_fifo, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_clear_fifo(int nvata) {
    // Clear the vata's FIFO.
    // Does not send any data.
    LOG_F(INFO, "Clearing FIFO for vata %d", nvata);
    std::vector<u32> data;
    int nread;
    u32 nremain;
    while (vatas[nvata].get_n_fifo() > 0)
        vatas[nvata].read_fifo(data, nread, nremain);

    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return 0;
}
int LayerServer::_fsm_idle(int nvata) {
    // Force vata to idle...
    LOG_F(INFO, "Forcing vata %d to idle.", nvata);
    return vatas[nvata].force_fsm_to_idle();
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
            LOG_F(INFO, "Emitter status requestreceived. Status: running.");
            const char retmsg[] = "running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            LOG_F(INFO, "Emitter status request received. Status: stopped.");
            const char retmsg[] = "stopped";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else if (strncmp("start", cmd, 5) == 0) { 
        if (data_emitter_running) {
            LOG_F(INFO, "Received request to start emitter. Emitter already running. No action taken.");
            const char retmsg[] = "ERROR: emitter already running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            LOG_F(INFO, "Received start emitter request. Starting.");
            start_packet_emitter();
            const char retmsg[] = "ok";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else if (strncmp("stop", cmd, 4) == 0) {
        if (!data_emitter_running) {
            LOG_F(INFO, "Received request to stop emitter. Emitter is not running. No action taken.");
            const char retmsg[] = "ERROR: emitter not running";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        } else {
            LOG_F(INFO, "Received stop emitter request. Stopping.");
            stop_packet_emitter();
            const char retmsg[] = "ok";
            _send_msg(retmsg, sizeof(retmsg));
            return 0;
        }
    } else {
        LOG_F(ERROR, "Received unsupported emit command.");
        const char retmsg[] = "ERROR: unsupported emit command.";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
}

/************************************
 * Process the calibration message.
 * 
 * cal pulse-ena [1|0]
 * cal trigger-ena [1|0]
 * cal fast-or-disable [1|0]
 * cal pulse-width WIDTH
 * cal trigger-delay DELAY
 * cal repeat-delay DELAY
 * cal start-inf
 * cal stop-inf
 * cal n-pulses N
 * Nothing else.
 ***********************************/
int LayerServer::_process_cal_msg(char *msg) {
    LOG_F(INFO, "Processing cal message: %s", msg);
     // Initialize strtok...
    strtok(msg, " ");
    // Now get next token. Should be the subcommand
    char *cmd = strtok(NULL, " ");
    if (strncmp("pulse-ena", cmd, 9) == 0) {
        if (_cal_pulse_ena(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse pulse-ena command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-ena", cmd, 11) == 0) { 
        if (_cal_trigger_ena(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-ena command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("fast-or-disable", cmd, 15) == 0) { 
        if (_cal_fast_or_disable(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse fast-or-disable command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("pulse-width", cmd, 11) == 0) { 
        if (_cal_pulse_width(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse pulse-width command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-delay", cmd, 13) == 0) { 
        if (_cal_trigger_delay(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-delay command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("repeat-delay", cmd, 12) == 0) { 
        if (_cal_repeat_delay(cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse repeat-delay command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("start-inf", cmd, 9) == 0) { 
        if (calctrl.start_inf_pulses() != 0) {
            LOG_F(ERROR, "Failed to run calctrl.start_inf_pulses()");
            const char retmsg[] = "ERROR: could not do start-inf command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("stop-inf", cmd, 8) == 0) { 
        if (calctrl.stop_inf_pulses() != 0) {
            LOG_F(ERROR, "Failed to run calctrl.stop_inf_pulses()");
            const char retmsg[] = "ERROR: could not do stop-inf command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("n-pulses", cmd, 8) == 0) { 
        int ret = _cal_n_pulses(cmd);
        if (ret == 1) {
            const char retmsg[] = "ERROR: could not parse n-pulses command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        } else if (ret == 2) {
            const char retmsg[] = "ERROR: number of pulses must be > 0";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
   } else {
        LOG_F(ERROR, "Unsupported cal command.");
        const char retmsg[] = "ERROR: unsupported cal command.";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }   
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return 0;
}

/* Set the delay value from the command string.
 *  Returns 0 on success.
 *  Returns 1 if we could not parse the command.
 *  Returns 2 if dac value is out of range.
 */
int LayerServer::_dac_set_delay(char* &cmd) {
    char *delay_str = strtok(NULL, " ");
    if (delay_str == NULL) {
        return 1;
    }
    u32 delay = (u32)atoi(delay_str);
    if (dacctrl.set_delay(delay) != 0) {
        LOG_F(ERROR, "Failed to set DAC delay");
        return 2;
    }
    LOG_F(INFO, "Set DAC delay to %lu", delay);
    return 0;
}

/* Get the delay value and send it out.
 *  Returns 0.
 */
int LayerServer::_dac_get_delay() {
    u32 delay = dacctrl.get_delay();
    LOG_F(INFO, "Current DAC delay: %lu", delay);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &delay, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_dac_set_counts(char* &cmd) {
    char *silayer_side_str = strtok(NULL, " ");
    if (silayer_side_str == NULL) {
        LOG_F(ERROR, "Failed to parse dac_set_counts command.");
        return 1;
    }
    char *dac_choice_str = strtok(NULL, " ");
    if (dac_choice_str == NULL) {
        LOG_F(ERROR, "Failed to parse dac_set_counts command.");
        return 1;
    }
    char *count_str = strtok(NULL, " ");
    if (count_str == NULL) {
        LOG_F(ERROR, "Failed to parse dac_set_counts command.");
        return 1;
    }
    SilayerSide silayer_side;
    DacChoice dac_choice;
    if (parse_silayer_side(silayer_side_str, &silayer_side) != 0) {
        LOG_F(ERROR, "Failed to set dac counts: could not parse silayer side.");
        return 1;
    }
    if (parse_dac_choice(dac_choice_str, &dac_choice) != 0) {
        LOG_F(ERROR, "Failed to set dac counts: could not parse dac choice.");
        return 1;
    }
    u32 counts = (u32)atoi(count_str);
    if (dacctrl.set_counts(silayer_side, dac_choice, counts) != 0) {
        LOG_F(ERROR, "dacctrl.set_counts(%s, %s, %lu) failed.", silayer_side_str, dac_choice_str, counts);
        return 2;
    }
    LOG_F(INFO, "Set DAC counts for side %s, dac %s to %lu", silayer_side_str, dac_choice_str, counts);
    return 0;
}

int LayerServer::_dac_get_input() {
    u32 input = dacctrl.get_input();
    LOG_F(INFO, "dacctrl.get_input() returned %lu", input);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &input, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}


/************************************
 * Process dac message
 * 
 * dac set-delay DELAY
 * dac get-delay
 * dac set-counts SIDE DAC-CHOICE COUNTS
 * dac get-input
 * Nothing else.
 ***********************************/
int LayerServer::_process_dac_msg(char *msg) {
    LOG_F(INFO, "Processing dac message: %s", msg);
    // Initialize strtok...
    strtok(msg, " ");
    // Now get next token. Should be the subcommand
    char *cmd = strtok(NULL, " ");
    if (strncmp("set-delay", cmd, 9) == 0) {
        int ret = _dac_set_delay(cmd);
        if (ret == 1) {
            const char retmsg[] = "ERROR: could not parse set-delay command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        } else if (ret == 2) {
            const char retmsg[] = "ERROR: delay value out of range";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-delay", cmd, 10) == 0) {
        // Get and send off delay..
        _dac_get_delay();
        return 0;
    } else if (strncmp("set-counts", cmd, 10) == 0) {
        int ret = _dac_set_counts(cmd);
        if (ret == 1) {
            const char retmsg[] = "ERROR: could not parse set-counts command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        } else if (ret == 2) {
            const char retmsg[] = "ERROR: count value out of range";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-input", cmd, 10) == 0) {
        // Get and send off current input value at the axi register..
        _dac_get_input();
        return 0;
    } else {
        LOG_F(ERROR, "Dac command unsupported.");
        const char retmsg[] = "ERROR: unsupported dac command.";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return 0;
}


/* Get the synchronous counter value and send it out.
 *  Returns 0.
 */
int LayerServer::_sync_get_counter() {
    u64 counter = syncctrl.get_counter();
    LOG_F(INFO, "Sync counter: %lu", counter);
    zmq::message_t response(sizeof(u64));
    std::memcpy(response.data(), &counter, sizeof(u64));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_sync_get_global_hit_enable() {
    bool is_enabled = syncctrl.is_global_hit_enabled();
    LOG_F(INFO, "Sync global hit enabled: %s", is_enabled ? "true" : "false");
    zmq::message_t response(sizeof(bool));
    std::memcpy(response.data(), &is_enabled, sizeof(bool));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_sync_get_asic_hit_disable_mask() {
    u32 hit_disable_mask = syncctrl.get_asic_hit_disable_mask();
    LOG_F(INFO, "Sync asic hit disable mask: %lu", hit_disable_mask);
    zmq::message_t response(sizeof(u32));
    std::memcpy(response.data(), &hit_disable_mask, sizeof(u32));
    socket.send(response, zmq::send_flags::none);
    return 0;
}

int LayerServer::_sync_set_asic_hit_enable(char* &cmd, int ena) {
    int asic = _parse_positive_int(cmd);
    if (asic < 0) {
        LOG_F(ERROR, "set-asic-hit-enable: could not parse asic number.");
        return 1;
    }

    if (ena == 1) {
        if (syncctrl.asic_hit_enable(asic) != 0) {
            LOG_F(ERROR, "set-asic-hit-enable: could not enable asic hit.");
            return 1;
        }
        LOG_F(INFO, "synctrl asic hit enabled for asic %d", asic);
    } else if (ena == 0) {
        if (syncctrl.asic_hit_disable(asic) != 0) {
            LOG_F(ERROR, "set-asic-hit-enable: could not disable asic hit.");
            return 1;
        }
        LOG_F(INFO, "synctrl asic hit disabled for asic %d", asic);
    } else {
        LOG_F(ERROR, "set-asic-hit-enable: ena value = %d. Expected 1 or 0.", ena);
        return 1;
    }
    return 0;
}

/************************************
 * Process sync message
 * 
 * sync counter-reset
 * sync get-counter
 * sync force-trigger
 * sync get-global-hit-ena
 * sync global-hit-enable
 * sync global-hit-disable
 * sync asic-hit-enable N
 * sync asic-hit-disable N
 * sync get-asic-hit-disable-mask
 * Nothing else.
 ***********************************/
int LayerServer::_process_sync_msg(char *msg) {
    LOG_F(INFO, "Processing sync message: %s", msg);
    // Initialize strtok...
    strtok(msg, " ");
    // Now get next token. Should be the subcommand
    char *cmd = strtok(NULL, " ");
    if (strncmp("counter-reset", cmd, 13) == 0) {
        LOG_F(INFO, "Resetting sync-ctrl counter.");
        syncctrl.counter_reset();
    } else if (strncmp("get-counter", cmd, 11) == 0) {
        // Get and send off counter...
        _sync_get_counter();
        return 0;
    } else if (strncmp("force-trigger", cmd, 13) == 0) {
        LOG_F(INFO, "Issuing sync-ctrl force trigger.");
        syncctrl.force_trigger();
    } else if (strncmp("get-global-hit-ena", cmd, 18) == 0) {
        // Get and send off the global hit ena bit.
        _sync_get_global_hit_enable();
        return 0;
    } else if (strncmp("global-hit-enable", cmd, 17) == 0) {
        LOG_F(INFO, "Asserting global hit enable.");
        syncctrl.global_hit_enable();
    } else if (strncmp("global-hit-disable", cmd, 18) == 0) {
        LOG_F(INFO, "De-asserting global hit enable.");
        syncctrl.global_hit_disable();
    } else if (strncmp("asic-hit-enable", cmd, 15) == 0) {
        if (_sync_set_asic_hit_enable(cmd, 1) != 0) {
            const char retmsg[] = "error";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("asic-hit-disable", cmd, 16) == 0) {
        if (_sync_set_asic_hit_enable(cmd, 0) != 0) {
            const char retmsg[] = "error";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-asic-hit-disable-mask", cmd, 25) == 0) {
        // Get and send off the asic disable mask.
        _sync_get_asic_hit_disable_mask();
        return 0;
    } else {
        LOG_F(ERROR, "Unsupported sync command.");
        const char retmsg[] = "ERROR: unsupported sync command.";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
    const char retmsg[] = "ok";
    _send_msg(retmsg, sizeof(retmsg));
    return 0;
}

/* 
 * Process a vata message
 * Messages have the form `vata VATA CMD [ARGS]`
 *     VATA: integer. Specifies which asic the command targets.
 *     CMD: string. Which command to run.
 *     ARGS: space-separated parameters. Present if the given `CMD` requires arguments.
 */
int LayerServer::_process_vata_msg(char *msg) {
    LOG_F(INFO, "Processing vata message: %s", msg);
    // Initialize strtok...
    strtok(msg, " ");
    // Move to vata number..
    char *cmd = strtok(NULL, " ");
    
    char *chk;
    int nvata = strtol(cmd, &chk, 0);

    if (*chk != ' ' && *chk != '\0') {
        // Could not parse arg (or no command provided after arg)
        LOG_F(ERROR, "First argument not a number.");
        _send_could_not_process_msg();
        return 1;
    } else if (nvata < 0 || nvata >= (int)N_VATA) {
        LOG_F(ERROR, "Requested vata number: %d. Out of range.", nvata);
        _send_could_not_process_msg();
        return 1;
    }
    // Now move on the the command
    cmd = strtok(NULL, " ");
    if (cmd == NULL) {
        LOG_F(ERROR, "No command provided?");
        _send_could_not_process_msg();
        return 1;
    }

    // Process command
    if (strncmp("set-config-binary", cmd, 17) == 0) {
        // _set_config_binary handles all message sending.
        // Just return whatever this function returns.
        return _set_config_binary(nvata);
    } else if (strncmp("set-config", cmd, 10) == 0) {
        if (_set_config(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse set-config command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-config-binary", cmd, 17) == 0) {
        // _get_config_binary handles all message sending.
        // Just return whatever this function returns.
        return _get_config_binary(nvata);
    } else if (strncmp("get-config", cmd, 10) == 0) {
        if (_get_config(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse get-config command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("set-hold", cmd, 8) == 0) {
        if (_set_hold(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse set-hold command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-hold", cmd, 8) == 0) {
        if (_get_hold(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse get-hold command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-counters", cmd, 12) == 0) {
        if (_get_counters(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse get-counters command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("reset-counters", cmd, 14) == 0) {
        if (_reset_counters(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse reset-counters command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-enable-bit", cmd, 18) == 0) {
        if (_trigger_enable_bit(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-enable-bit command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-disable-bit", cmd, 19) == 0) {
        if (_trigger_disable_bit(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-disable-bit command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-enable-asic", cmd, 19) == 0) {
        if (_trigger_enable_asic(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-enable-asic command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-disable-asic", cmd, 20) == 0) {
        if (_trigger_disable_asic(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse trigger-disable-asic command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("trigger-enable-tm-hit", cmd, 21) == 0) {
        _trigger_enable_tm_hit(nvata);
    } else if (strncmp("trigger-disable-tm-hit", cmd, 22) == 0) {
        _trigger_disable_tm_hit(nvata);
    } else if (strncmp("trigger-enable-tm-ack", cmd, 21) == 0) {
        _trigger_enable_tm_ack(nvata);
    } else if (strncmp("trigger-disable-tm-ack", cmd, 22) == 0) {
        _trigger_disable_tm_ack(nvata);
    } else if (strncmp("trigger-enable-forced", cmd, 21) == 0) {
        _trigger_enable_forced(nvata);
    } else if (strncmp("trigger-disable-forced", cmd, 22) == 0) {
        _trigger_disable_forced(nvata);
    }else if (strncmp("get-trigger-ena-mask", cmd, 20) == 0) {
        _get_trigger_ena_mask(nvata);
    } else if (strncmp("get-event-count", cmd, 15) == 0) {
        if (_get_event_count(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse get-event-count command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("reset-event-count", cmd, 17) == 0) {
        if (_reset_event_count(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse reset-event-count command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("get-n-fifo", cmd, 10) == 0) {
        if (_get_n_fifo(nvata, cmd) != 0) {
            const char retmsg[] = "ERROR: could not parse get-n-fifo command";
            _send_msg(retmsg, sizeof(retmsg));
            return 1;
        }
    } else if (strncmp("clear-fifo", cmd, 10) == 0) {
        _clear_fifo(nvata);
    } else if (strncmp("fsm-idle", cmd, 8) == 0) {
        _fsm_idle(nvata);
        const char retmsg[] = "ok";
        _send_msg(retmsg, sizeof(retmsg));
    } else {
        LOG_F(ERROR, "Failed to parse vata command.");
        const char retmsg[] = "ERROR: vata sub-command invalid";
        _send_msg(retmsg, sizeof(retmsg));
        return 1;
    }
    // The above vata commands send a response.
    // No need to send one here.
    return 0;
}

int LayerServer::process_req() {
    zmq::message_t request;
    socket.recv(request, zmq::recv_flags::none);
    int req_sz = request.size();
    char *c_req = new char[req_sz + 1];
    std::memcpy(c_req, request.data(), req_sz);
    c_req[req_sz] = '\0';
    LOG_F(INFO, "Received message: %s", c_req);

    int retval = 0;
    if (strncmp("emit", c_req, 4) == 0) {
        retval = _process_emit_msg(c_req);
    } else if (strncmp("cal", c_req, 3) == 0) { 
        retval = _process_cal_msg(c_req);
    } else if (strncmp("dac", c_req, 3) == 0) { 
        retval = _process_dac_msg(c_req);
    } else if (strncmp("sync", c_req, 4) == 0) {
        retval = _process_sync_msg(c_req);
    } else if (strncmp("vata", c_req, 4) == 0) {
        retval = _process_vata_msg(c_req);
    } else if (strncmp("get-n-vata", c_req, 10) == 0) {
        LOG_F(INFO, "get-n-vata request. Returning n_vata = %d", (int)N_VATA);
        zmq::message_t n_vata_response(sizeof(u8));
        u8 n_vata = N_VATA;
        std::memcpy(n_vata_response.data(), &n_vata, sizeof(u8));
        socket.send(n_vata_response, zmq::send_flags::none);
    } else if (strncmp("halt", c_req, 4) == 0) {
        LOG_F(INFO, "Halt message received. Exiting.");
        // Need to check if emitter is running!!!
        // ??? I think the below is deprecated???
        //if (data_emitter_running) {
        //    _kill_packet_emitter();
        //}
        _kill_packet_emitter();
        retval = EXIT_REQ_RECV_CODE;
    } else {
        LOG_F(ERROR, "Failed to parse message: %s", c_req);
        _send_could_not_process_msg();
        retval = 1;
    }

    delete[] c_req;
    return retval;
}

// vim: set ts=4 sw=4 sts=4 et:
