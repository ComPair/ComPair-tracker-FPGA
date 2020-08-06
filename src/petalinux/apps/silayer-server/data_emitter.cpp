#include "data_emitter.hpp"

DataEmitter::DataEmitter(zmq::context_t *ctx) {
    context = ctx;
    for (int i=0; i<(int)N_VATA; i++) {
        vatas[i] = VataCtrl(i);
    }
    inproc_sock = zmq::socket_t(*context, zmq::socket_type::pair);
    inproc_sock.connect("inproc://" INPROC_CHANNEL);

    emit_sock = zmq::socket_t(*context, zmq::socket_type::pub);
    emit_sock.setsockopt(ZMQ_LINGER, (int)0);

    emit_sock.bind("tcp://eth0:" EMIT_PORT);
    running = false;

    data_buffer = new u32[ASIC_NDATA];
}

// Return true if halt message was received.
bool DataEmitter::halt_received(zmq::message_t &msg) {
    if (msg.size() < 4) {
        return false;
    }
    return strncmp("halt", (char *)msg.data(), 4) == 0;
}

bool DataEmitter::stop_received(zmq::message_t &msg) {
    if (msg.size() < 4) {
        return false;
    }
    return strncmp("stop", (char *)msg.data(), 4) == 0;
}

bool DataEmitter::start_received(zmq::message_t &msg) {
    if (msg.size() < 5) {
        return false;
    }
    return strncmp("start", (char *)msg.data(), 5) == 0;
}

void DataEmitter::send_data(DataPacket &data_packet) {
    u16 packet_size = data_packet.get_packet_size();
    zmq::message_t response(packet_size);
    data_packet.to_msg(packet_size, (char *)response.data());
    //std::cout << "XXX Sending data. Packet size: " << packet_size 
    //          << ". Packet time: " << data_packet.packet_time << std::endl;
    emit_sock.send(response, zmq::send_flags::none);
}

void DataEmitter::read_fifo(int i) {
    // Read vata i's fifo into data packets map.
    int success = vatas[i].read_fifo_full_packet(data_buffer);
    if (success == 0) {
        // Packet was read!
        // Check event id (first element in buffer)
        long int current_event_id = (long int)data_buffer[0];
        if (packets.find(current_event_id) == packets.end()) {
            packets.insert({current_event_id, new DataPacket()});
        }
        DataPacket *packet = packets[current_event_id];
        if (!(packet->set_vata_data(i, data_buffer))) {
            std::cout << "E: data_aligner attempted to input data for packet with incorrect event id!"
                      << std::endl;
        }
        if (packet->is_done()) {
            // Send packet and delete from packet map.
            std::cout << "I: sending complete packet for event: " << current_event_id << std::endl;
            send_data(*packet);
            packets.erase(current_event_id);
            delete packet;
        }
    }
}

void DataEmitter::read_fifos() {
    // Read each fifo, send any packets that are completed...
    // XXX: Currently no timeout on packet time!
    for (int i=0; i<(int)N_VATA; i++) {
        read_fifo(i);
    }
    
    //DataPacket data_packet;
    //data_packet.set_packet_time();
    ////data_packet.collect_header_data(vatas);
    //auto t0 = std::chrono::high_resolution_clock::now();
    //auto fifo_read_timeout = std::chrono::microseconds(FIFO_READ_TIMEOUT_US);
    //while (data_packet.nread < (int)N_VATA) {
    //    for (int i=0; i<(int)N_VATA; i++) {
    //        if (data_packet.need_data[i]) {
    //            data_packet.read_vata_data(i, vatas);
    //        }
    //    }
    //    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
    //                        (std::chrono::high_resolution_clock::now() - t0)
    //                    );
    //    if (duration > fifo_read_timeout) {
    //        data_packet.set_timeout();
    //        break; 
    //    }
    //}
    //send_data(data_packet);
}

void DataEmitter::check_fifos() {
    // If any FIFO has data, try and read them all out...
    for (int i=0; i<(int)N_VATA; i++) {
        if (vatas[i].get_n_fifo() > 0 ) {
            read_fifos();
            return;
        }
    }
}

void DataEmitter::operator() () {
    std::cout << "XXX Starting main data emitter loop" << std::endl;
    while (true) {
        zmq::message_t inproc_msg;
        if (running) {
            // We are streaming data.
            // Quickly check the inproc_sock to see if the silayer-server sent us anything
            try {
                inproc_sock.recv(inproc_msg, zmq::recv_flags::dontwait);
            } catch (zmq::error_t e) {
                // Nothing received. inproc_msg will be empty moving forward.
            }
        } else {
            // We are not streaming data.
            // Wait to receive a command from the silayer-server before moving on.
            inproc_sock.recv(inproc_msg, zmq::recv_flags::none); // block
            if (inproc_msg.size() > 0) {
                // This if-clause only exists for showing the debug message.
                std::string msg((char *)inproc_msg.data(), inproc_msg.size());
                std::cout << "!!! Emitter thread received message: " <<  msg << std::endl;
            }
        }
        
        // Process the inproc_msg. None of these are true with an empty msg.
        if (halt_received(inproc_msg)) {
            // we are shutting down. return.
            std::cout << "!!! Emitter thread received halt message" << std::endl;
            return;
        } else if (stop_received(inproc_msg)) {
            // Change state to running = false
            std::cout << "!!! Emitter thread received stop message" << std::endl;
            running = false;
        } else if (start_received(inproc_msg)) {
            // Change state to running = true
            std::cout << "!!! Emitter thread received start message" << std::endl;
            running = true;
        }
        
        if (running) {
            // Look to see if there is data we can send out.
            check_fifos();
        }
    }
}

// vim: set ts=4 sw=4 sts=4 et:
