#include "data_emitter.hpp"

DataEmitter::DataEmitter(zmq::context_t *ctx) {
    context = ctx;
    for (int i=0; i<(int)N_VATA; i++) {
        vatas[i] = VataCtrl(i);
    }
    inproc_sock = zmq::socket_t(*context, zmq::socket_type::pair);
    inproc_sock.connect("inproc://main");

    emit_sock = zmq::socket_t(*context, ZMQ_DISH);
    emit_sock.bind(UDP_ADDR);

}

// Return true if halt message was received.
bool DataEmitter::halt_received(zmq::message_t &msg) {
    if (msg.size() < 4) {
        return false;
    }
    return strncmp("halt", (char *)msg.data(), 4) == 0;
}

void DataEmitter::send_data(DataPacket &data_packet) {
    u16 packet_size = data_packet.get_packet_size();
    zmq::message_t response(packet_size);
    data_packet.to_msg(packet_size, (char *)response.data());
    emit_sock.send(response);
}

void DataEmitter::read_fifos() {
    DataPacket data_packet();
    data_packet.collect_header_data(vatas);
    auto t0 = std::chrono::high_resolution_clock::now();
    while (data_packet.nread < N_VATA) {
        for (int i=0; i<N_VATA; i++) {
            if (data_packet.need_data[i]) {
                data_packet.read_vata_data(i, vatas);
            }
        }
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
                            (std::chrono::high_resolution_clock::now() - t0)
                        );
        if (duration > FIFO_READ_TIMEOUT) {
            data_packet.set_timeout();
            break; 
        }
    }
    send_data(data_packet);
}

void DataEmitter::check_fifos() {
    // If any FIFO has data, try and read them all out...
    for (int i=0; i<N_VATAS; i++) {
        if (vatas[i].get_n_fifo() > 0 ) {
            read_fifos();
            return;
        }
    }
}

void DataEmitter::operator()() {
    while (true) {
        zmq::message_t inproc_msg;
        try {
            inproc_sock.recv(inproc_msg, ZMQ_NOBLOCK);
            if (halt_received(inproc_msg))
                return;
        } catch (zmq::error_t e) {
            // No message came in...
        }
        check_fifos();
    }
}

// vim: set ts=4 sw=4 sts=4 et:
