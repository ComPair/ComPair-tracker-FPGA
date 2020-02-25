#!/usr/bin/env python3
import numpy as np
import h5py
"""
This module should parse the raw, flat, binary file to produce an hdf5 file.
"""

class DataSz:
    """
    Stupid thing to keep track of data sizes in bytes.
    """
    u8 = 1
    u16 = 2
    u32 = 4
    u64 = 8

def byte2bits(byte, nbits=8):
    """
    Return a list of bits for the given byte, LSB..MSB
    Defaults to interpret a byte.
    Change nbits to interpret different sized unsigned data.
    (for example, nbits=4 for a nibble)
    """
    return [byte >> i & 1 for i in range(nbits)]


def bits2val(bitarr):
    """
    Convert arbitrarily long list of bits to unsigned integer.
    Bits should be ordered LSB..MSB
    """
    val, fac = 0, 1
    for bit in bitarr:
        val += bit * fac
        fac *= 2
    return val


def bytes2bits(bytestr):
    """
    Return entire byte string as bit array, LSB .. MSB.
    """
    bits = []
    for byte in bytestr:
        bits += byte2bits(byte)
    return bits

def hexstr2bytes(hexstr):
    """
    Given a string of hex data, as printed out by `vatactrl --read-fifo`,
    return the bytes this corresponds to.

    Wrote up something quick and dirty, so this should probably be made more readable
    in the future.
    """
    assert len(hexstr) % 8 == 0
    axi_reads = [ hexstr[i:i+8][::-1] for i in range(0, len(hexstr), 8) ]
    return bytes( int(s.encode(), 16) for s in axi_reads)
    ##return bytes( int((b1 + b0).encode(), 16) for b0, b1 in zip(hexstr[:-1:2], hexstr[1::2]) )

def bytes2val(bytestr):
    """
    Interpret string of bytes as single unsigned integer.
    So, length 4 bytestring should be interpreted as 32 bit integer.
    """
    return bits2val(bytes2bits(bytestr))


class AsicPacket(object):
    """
    Class for parsing binary data from a single asic, single event.

    Ideally, only the class attributes will need to be changed as the packet
    structure evolves.
    """
    N_CHANNEL = 32
    ADC_NBITS = 10
    N_READS_PER_PACKET = 15 ## Number of 32-bit reads per asic packet.

    ## _field_info: values are start_bit, n_bits for each field
    ##_field_info = {
    ##    "event_id": (0, 32),
    ##    "start_bit": (32, 1),
    ##    "chip_data_bit": (33, 1),
    ##    "trigger_bit": (34, 1),
    ##    "seu_bit": (35, 1),
    ##    "status_bits": (36, 34),
    ##    "all_channel_data": (70, 340),
    ##    "stop_bit": (410, 1),
    ##}
    
    ## Data layout for each asic data packet.
    ## Data shows up in the packet in the order of _DATA_LAYOUT
    ## Entries are field name, and number of bits.
    _DATA_LAYOUT = [
        ("event_id", 32),
        ("event_time", 64),
        ("start_bit", 1),
        ("chip_data_bit", 1),
        ("trigger_bit", 1),
        ("seu_bit", 1),
        ("status_bits", 34),
        ("all_channel_data", 340),
        ("stop_bit", 1),
    ]
    N_BYTES = DataSz.u32 * N_READS_PER_PACKET ## Expected packet size, in bytes.

    def __init__(self, data):
        """
        Initialize the AsicPacket
        `data` can be:
            * bytes
            * file name
        """
        if type(data) is str:
            data = open(data, "rb").read(self.N_BYTES)
        assert type(data) is bytes
        bits = bytes2bits(data)
        self.parse_bits(bits)

    def parse_bits(self, bits):
        for field, nbits in self._DATA_LAYOUT:
            field_bits = bits[:nbits]
            if field == "all_channel_data":
                self.set_channel_data(field_bits)
            elif field == "status_bits":
                self.set_status_bits(field_bits)
            else:
                setattr(self, field, bits2val(field_bits))
            bits = bits[nbits:]

    def set_channel_data(self, bits):
        self.data = []
        self.dummy_data = bits2val(bits[:self.ADC_NBITS])
        bits = bits[self.ADC_NBITS:]
        for _ in range(self.N_CHANNEL):
            self.data.append(bits2val(bits[:self.ADC_NBITS]))
            bits = bits[self.ADC_NBITS:]
        self.cm_data = bits2val(bits[:self.ADC_NBITS])

    def set_status_bits(self, bits):
        self.dummy_status = bits[0]
        self.channel_status = bits[1:-1]
        self.cm_status = bits[-1]

    

class DataPacket(object):
    """
    Class to parse a multi-asic, single event data packet.

    Expect packet to start with header info,
    then present the number of bytes for each asic,
    then the asic data.
    """
    
    ## Header content, and data size for each field
    _HEADER_LAYOUT = [
            ('packet_size', DataSz.u16), ## was npacket
            ('header_size', DataSz.u8),
            ('packet_flags', DataSz.u16),
            ('real_time_counter', DataSz.u64),
            ('live_time_counter', DataSz.u64),
            ('event_type', DataSz.u16),
            ('event_counter', DataSz.u32),
            ('nasic', DataSz.u8)]
    _ASIC_NDATA_SZ = DataSz.u16

    ##N_HEADER = 3  ## Number of bytes in header.
    ##N_ASIC = 2  ## This may get included in the data packet?

    def __init__(self, data):
        """
        Initialize the DataPacket.
        `data` can be:
            * bytes
            * file name

        NOTE: 4's used everywhere as this is u32 data size in bytes.
        """
        if type(data) is str:
            data = open(data, "rb").read()
        assert type(data) is bytes
        self.parse_asic_data(self.parse_header(data))
        self.packet_size = 91 ## XXX KLUDGE XXX FIXME XXX

    def parse_header(self, data):
        """
        Read header data, and set the corresponding attributes of `self`.
        Return the data that tails the header.
        """
        for name, nbytes in self._HEADER_LAYOUT:
            setattr(self, name, bytes2val(data[:nbytes]))
            data = data[nbytes:]
        return data

    def parse_asic_data(self, data):
        """
        Input data should be the post-header data.
        Read asic data and return the remaining data.
        """
        self.asic_nbytes, self.asic_packets = [], []
        for _ in range(self.nasic):
            nbytes = bytes2val(data[:self._ASIC_NDATA_SZ])
            self.asic_nbytes.append(nbytes)
            data = data[self._ASIC_NDATA_SZ:]
        for nbytes in self.asic_nbytes:
            if nbytes == 0:
                ## No data for current asic.
                self.asic_packets.append(None)
            else:
                self.asic_packets.append(AsicPacket(data[:nbytes]))
                data = data[nbytes:]
        return data

class DataPackets(object):
    """
    Class for managing the parsing of flat binary data files,
    to produce other formats.
    Currently produces hdf5.
    Need to investigate dirfiles!
    """

    ## _hdf5_asic_fields:
    ##      data that we extract from each asic, and will have a
    ##      dataset in hdf5 under `/asicXX/`.
    _hdf5_asic_fields = [
        "event_ids",
        "start_bits",
        "stop_bits",
        "trigger_bits",
        "seu_bits",
        "dummy_status",
        "channel_status",
        "cm_status",
        "data",
        "cm_data",
        "dummy_data",
    ]
    ## _hdf5_top_fields:
    ##      Top-level data that is common to all asic's,
    ##      with a single value per event.
    _hdf5_top_fields = [
        "event_counter",
        "event_type",
        "live_time_counter",
        "real_time_counter",
    ]
    ## _hdf5_asttrs:
    ##      Scalars that apply to the entire data run.
    _hdf5_attrs = ["n_packet", "n_asic"]

    @staticmethod
    def iter_data_packets(data, n_packet=0):
        """
        Iterator to parse data or data binary file, yielding data packets.
        If `n_packet` is provided (and > 0), then iterator will yield
        this number of data packets.
        """
        if type(data) is str:
            data = open(data, "rb").read()
        assert type(data) is bytes
        n_dp, start_byte = 0, 0
        while start_byte < len(data):
            dp = DataPacket(data[start_byte:])
            yield dp
            start_byte += dp.packet_size
            data = data[dp.packet_size:]
            n_dp += 1
            if n_packet > 0 and n_dp >= n_packet:
                break

    @classmethod
    def from_binary(cls, data, n_packet=0):
        """
        Load the data from a flat binary file of data packets, or a byte string.
        If `n_packet` is 0, then entire data file/stream will be parsed.
        If `n_packet` > 0, then only read the requested number of packets.
        """
        self = cls()
        dps = [dp for dp in self.iter_data_packets(data, n_packet=n_packet)]
        self.n_packet = len(dps)
        self.n_asic = dps[0].nasic
        self.alloc_data()

        for j, dp in enumerate(dps):
            assert self.n_asic == dp.nasic
            ##self.time[j] = dp.time
            self.event_counter[j] = dp.real_time_counter
            self.real_time_counter[j] = dp.real_time_counter
            self.live_time_counter[j] = dp.live_time_counter
            for i, ap in enumerate(dp.asic_packets):
                self.event_ids[i, j] = ap.event_id
                self.start_bits[i, j] = ap.start_bit
                self.stop_bits[i, j] = ap.stop_bit
                self.trigger_bits[i, j] = ap.trigger_bit
                self.seu_bits[i, j] = ap.seu_bit
                self.dummy_status[i, j] = ap.dummy_status
                self.channel_status[i, j, :] = ap.channel_status
                self.cm_status[i, j] = ap.cm_status
                self.data[i, j, :] = ap.data
                self.cm_data[i, j] = ap.cm_data

        return self

    def alloc_data(self):
        """
        Initialize/allocate all data arrays here.
        """
        sz = (
            self.n_asic,
            self.n_packet,
        )
        ##self.time = np.zeros(self.n_packet, dtype=np.uint64)
        self.event_type = np.zeros(self.n_packet, dtype=np.uint16)
        self.event_counter = np.zeros(self.n_packet, dtype=np.uint32)
        self.real_time_counter = np.zeros(self.n_packet, dtype=np.uint64)
        self.live_time_counter = np.zeros(self.n_packet, dtype=np.uint64)
        self.event_ids = np.zeros(sz, dtype=np.uint32)
        self.start_bits = np.zeros(sz, dtype=np.bool)
        self.stop_bits = np.zeros(sz, dtype=np.bool)
        self.trigger_bits = np.zeros(sz, dtype=np.bool)
        self.seu_bits = np.zeros(sz, dtype=np.bool)
        self.dummy_status = np.zeros(sz, dtype=np.bool)
        self.channel_status = np.zeros(sz + (AsicPacket.N_CHANNEL,), dtype=np.bool)
        self.cm_status = np.zeros(sz, dtype=np.bool)
        self.cm_data = np.zeros(sz, dtype=np.uint16)
        self.dummy_data = np.zeros(sz, dtype=np.uint16)
        self.data = np.zeros(sz + (AsicPacket.N_CHANNEL,), dtype=np.uint16)

    def write_hdf5(self, fname):
        """
        Write data to hdf5 file.
        XXX To Do: Put in compression here!
        """
        f = h5py.File(fname, "w")
        for field in self._hdf5_asic_fields:
            full_data = getattr(self, field)
            for n in range(self.n_asic):
                data = full_data[n, ...]
                field_name = "asic%02d/%s" % (n, field,)
                f.create_dataset(
                    field_name, shape=data.shape, dtype=data.dtype, data=data
                )
        for field in self._hdf5_top_fields:
            data = getattr(self, field)
            f.create_dataset(field, shape=data.shape, dtype=data.dtype, data=data)

        for field in self._hdf5_attrs:
            f.attrs[field] = getattr(self, field)
        f.close()

    @classmethod
    def from_hdf5(cls, fname):
        """
        Read an hdf5 at the given path to populate and return a `DataPackets` object.
        """
        self = cls()
        f = h5py.File(fname, "r")
        for field in self._hdf5_attrs:
            setattr(self, field, f.attrs[field])
        for field in self._hdf5_top_fields:
            setattr(self, field, f[field][...])
        for field in self._hdf5_asic_fields:
            data = []
            for n in range(self.n_asic):
                field_name = "asic%02d/%s" % (n, field,)
                data.append(f[field_name][...])
            setattr(self, field, np.array(data))
        return self


## vim: set ts=4 sw=4 sts=4 et:
