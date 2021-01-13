#include "data_packet.hpp"

DataPacket::DataPacket() {
    for (int i=0; i<(int)N_VATA; i++) {
        asic_data[i] = new u32[ASIC_NDATA];
        ndata[i] = 0;
        nfifo[i] = 0;
        need_data[i] = true;
    }
    nread = 0;
    flags = 0;
    event_id = -1;
    // Set packet_time on creation...
    auto dtn = std::chrono::high_resolution_clock::now().time_since_epoch();
    packet_time = std::chrono::duration_cast<std::chrono::nanoseconds>(dtn).count();
}

DataPacket::~DataPacket() {
    for (int i=0; i<(int)N_VATA; i++) {
        delete[] asic_data[i];
    }
}

void DataPacket::set_packet_time() {
    auto dtn = std::chrono::high_resolution_clock::now().time_since_epoch();
    packet_time = std::chrono::duration_cast<std::chrono::nanoseconds>(dtn).count();
}

//void DataPacket::collect_header_data(VataCtrl *vatas) {
//    // Currently get data from first vata
//    // This will move to global peripheral when it is ready.
//    vatas[0].get_counters(real_time, live_time);
//    event_counter = vatas[0].get_event_count();
//
//    // XXX CURRENTLY NO EVENT TYPE!!! XXX
//    // XXX DUMMY DATA FOR DEBUGGING
//    event_type = 0x1234;
//}

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

// Set the packet data for vata i, given the data.
// If the event id is not set, this will set it and return true.
// Otherwise, it will check that the event_id matches that of the asic data,
// if it does, data will be set and return true. Otherwise, return false.
bool DataPacket::set_vata_data(int i, u32 *data, VataCtrl *vatas) {
    long int event_id_check = (long int)data[0];
    if (event_id < 0)
        event_id = event_id_check;
    else if (event_id != event_id_check)
        return false;

    for (int j=0; j<ASIC_NDATA; j++) {
        asic_data[i][j] = data[j];
    }
    ndata[i] = (u16)(ASIC_NDATA*sizeof(u32) + sizeof(u16));
    nfifo[i] = (u16)vatas[i].get_n_fifo();
    nread++;
    need_data[i] = false;
    return true;
}

bool DataPacket::is_done() {
    // Return whether all asics have been read from.
    for (int i=0; i<(int)N_VATA; i++) {
        if (need_data[i])
            return false;
    }
    return true;

}

u8 DataPacket::get_header_size() {
    /* Header consists of:
     *  > header-size ( u8)
     *  > flags       (u16)
     *  > packet-time (u64)
     *  >             = 1 + 2 + 8 = 11
     */
    return (u8)(sizeof(u8) + sizeof(u16) + sizeof(u64));
}

u16 DataPacket::get_packet_size() {
    //u16 packet_size = 28 + 2*N_VATA; // packet-size (2) + header (25) + n-asic (1) + n-data[] (2*N_VATA)
    u16 packet_size = ((u16)sizeof(u16)) + ((u16)get_header_size()) + (u16)sizeof(u8) + N_VATA*((u16)sizeof(u16));
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
    char *cur = buf;
    std::memcpy(cur, &packet_size, sizeof(u16));   cur += sizeof(u16);
    std::memcpy(cur, &header_size, sizeof(u8));    cur += sizeof(u8);
    std::memcpy(cur, &flags, sizeof(u16));         cur += sizeof(u16);
    std::memcpy(cur, &packet_time, sizeof(u64));   cur += sizeof(u64);
    //std::memcpy(cur, &real_time, sizeof(u64));     cur += sizeof(u64);
    //std::memcpy(cur, &live_time, sizeof(u64));     cur += sizeof(u64);
    //std::memcpy(cur, &event_type, sizeof(u16));    cur += sizeof(u16);
    //std::memcpy(cur, &event_counter, sizeof(u32)); cur += sizeof(u32);
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

void DataPacket::set_asic_flags() {
    for (u16 i=0; i<(u16)N_VATA; i++)
        if (need_data[i])
            flags |= (1 << i);
}

// vim: set ts=4 sw=4 sts=4 et:
