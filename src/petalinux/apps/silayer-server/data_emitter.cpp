#include "data_emitter.hpp"

DataPacket::DataPacket() {
    for (int i=0; i<(int)N_VATA; i++) {
        asic_data[i] = new u32[ASIC_NDATA];
        ndata[i] = 0;
        nfifo[i] = 0;
        need_data[i] = true;
    }
    nread = 0;
    flags = 0;
}

DataPacket::~DataPacket() {
    for (int i=0; i<(int)N_VATA; i++) {
        delete[] asic_data[i];
    }
}

void DataPacket::collect_header_data(VataCtrl *vatas) {
    // Currently get data from first vata
    // This will move to global peripheral when it is ready.
    vatas[0].get_counters(real_time, live_time);
    event_counter = vatas[0].get_event_count();

    // XXX CURRENTLY NO EVENT TYPE!!! XXX
    // XXX DUMMY DATA FOR DEBUGGING
    event_type = 0x1234;
}

bool DataPacket::read_vata_data(int i, VataCtrl *vatas) {
    // Call once the vata has fifo data!
    // add data from ith vata into ith asic_data buffer.
    // update ndata[i] to hold the number of 32-bit reads performed.
    // Returns true if data is read. false if no data was read.
    u32 n;
    if ((vatas[i].read_fifo(asic_data[i], ASIC_NDATA, n)) != 1) {
        return false;
    }
    ndata[i] = (u16)(n * sizeof(u32) + sizeof(u16)); // include putting in fifo count
    nfifo[i] = (u16)vatas[i].get_n_fifo();
    nread++;
    need_data[i] = false;
    return true;
}

u8 DataPacket::get_header_size() {
    return (u8)25;
}

u16 DataPacket::get_packet_size() {
    u16 packet_size = 28 + N_VATA; // packet-size + header + n-asic + n-data[]
    for (int i=0; i<(int)N_VATA; i++) {
        packet_size += ndata[i];
    }
    return packet_size;
}

// Better know what you are doing here!!!
void DataPacket::to_msg(u16 packet_size, char* buf) {
    //u16 packet_size = get_packet_size();
    u8 header_size = get_header_size();
    u8 nasic = N_VATA;
    //buf = new char[packet_size];
    char *cur = buf;
    std::memcpy(cur, &packet_size, sizeof(u16));   cur += sizeof(u16);
    std::memcpy(cur, &header_size, sizeof(u8));    cur += sizeof(u8);
    std::memcpy(cur, &flags, sizeof(u16));         cur += sizeof(u16);
    std::memcpy(cur, &real_time, sizeof(u64));     cur += sizeof(u64);
    std::memcpy(cur, &live_time, sizeof(u64));     cur += sizeof(u64);
    std::memcpy(cur, &event_type, sizeof(u16));    cur += sizeof(u16);
    std::memcpy(cur, &event_counter, sizeof(u32)); cur += sizeof(u32);
    std::memcpy(cur, &nasic, sizeof(u8));          cur += sizeof(u8);
    for (int i=0; i<(int)N_VATA; i++) {
        std::memcpy(cur, ndata+i, sizeof(u16));    cur += sizeof(u16);
    }
    for (int i=0; i<(int)N_VATA; i++) {
        if (ndata[i] > 0) {
            int n = (int)ndata[i] - sizeof(u16);
            std::memcpy(cur, asic_data[i], n);
            cur += n;
            std::memcpy(cur, nfifo+i, sizeof(u16));
            cur += sizeof(u16);
        }
    }
}

void DataPacket::set_timeout() {
    flags |= DP_TIMEOUT_FLAG;
}

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
