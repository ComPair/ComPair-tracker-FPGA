#!/usr/bin/env python3
from functools import reduce
import numpy as np
import h5py

from . import _raw2hdf

"""
This module should parse the raw, flat, binary file to produce an hdf5 file.
"""

_add = lambda a, b: a + b


class DataSz:
    """
    Stupid thing to keep track of data sizes in bytes.
    """

    u8 = 1
    u16 = 2
    u32 = 4
    u64 = 8
    ## Data types. Try and force lengths to be what we want.
    to_type = {
        u8: np.dtype(f"<u{u8}"),
        u16: np.dtype(f"<u{u16}"),
        u32: np.dtype(f"<u{u32}"),
        u64: np.dtype(f"<u{u64}"),
    }


def byte2bits(byte, nbits=8):
    """
    Return a list of bits for the given byte, LSB..MSB
    Defaults to interpret a byte.
    Change nbits to interpret different sized unsigned data.
    (for example, nbits=4 for a nibble)
    """
    if type(byte) is not int:
        byte = int(byte)
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


def bits2bytes(bits):
    """
    Return the bytes corresponding to the list of bits.
    Length of bits list must be divisible by 8
    """
    return bytes(bits2val(bits[i : i + 8]) for i in range(0, len(bits), 8))


def bytes2val(bytestr):
    """
    Interpret string of bytes as single unsigned integer.
    So, length 4 bytestring should be interpreted as 32 bit integer.
    """
    return bits2val(bytes2bits(bytestr))


def hexstr2bytes(hexstr):
    """
    Given a string of hex data, as printed out for example by
    vatactrl's --read-fifo option, return the bytes this corresponds to.
    """
    ## Flip the hex string for each 32 bit read to get the correct ordering
    flipstr = reduce(_add, [hexstr[i : i + 8][::-1] for i in range(0, len(hexstr), 8)])
    ## Get the bits
    bits = reduce(_add, [byte2bits(int(val, 16), nbits=4) for val in flipstr])
    return bits2bytes(bits)

def lame_byte_iterator(fname, npacket=0):
    """
    This is a lame, temporary iterator that should
    yield bytes, where each yielded bytes is an
    entire data packet.

    This will continue to yield data packets infinitely if npacket=0;
    otherwise, it will yield `npacket` number of packets.
    """
    data = open(fname, "rb").read()
    n = 0
    while True:
        ndata = len(data)
        if ndata < 2:
            data = open(fname, "rb").read()
            continue
        nbytes = bytes2val(data[:2])
        if ndata < nbytes:
            data = open(fname, "rb").read()
            continue
        packet = data[:nbytes]
        yield packet
        n += 1
        if npacket > 0 and n >= npacket:
            break
        data = data[nbytes:]


class AsicPacket(object):
    """
    Class for parsing binary data from a single asic, single event.

    Ideally, only the class attributes will need to be changed as the packet
    structure evolves.
    """

    N_CHANNEL = 32
    ADC_NBITS = 10
    N_READS_PER_PACKET = 18  ## Number of 32-bit reads per asic packet.

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
        ("event_number", 32),
        ("trigger_status", 32),
        ("running_time", 64),
        ("live_time", 64),
        ("start_bit", 1),
        ("chip_data_bit", 1),
        ("trigger_bit", 1),
        ("seu_bit", 1),
        ("status_bits", 34),
        ("all_channel_data", 340),
        ("stop_bit", 1),
    ]
    N_BYTES = DataSz.u32 * N_READS_PER_PACKET  ## Expected packet size, in bytes.

    def __init__(self, data):
        """
        Initialize the AsicPacket
        `data` can be:
            * bytes
            * file name
            * None to get an unpecified asic packet
        """
        if data is not None:
            if type(data) is str:
                data = open(data, "rb").read(self.N_BYTES)
            assert type(data) is bytes
            bits = bytes2bits(data)
            self.parse_bits(bits)

    def __repr__(self):
        digs = [ f"{data:04d}" for data in self.data ]
        return f"AsicPacket<{'|'.join(digs)}>"

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
        self.dummy_data = bits2val(bits[: self.ADC_NBITS])
        bits = bits[self.ADC_NBITS :]
        for _ in range(self.N_CHANNEL):
            self.data.append(bits2val(bits[: self.ADC_NBITS]))
            bits = bits[self.ADC_NBITS :]
        self.cm_data = bits2val(bits[: self.ADC_NBITS])

    def set_status_bits(self, bits):
        self.dummy_status = bits[0]
        self.channel_status = bits[1:-1]
        self.cm_status = bits[-1]

    def to_bits(self, pad=True):
        """
        Return the bits for this asic data packet.
        Pads out to whole-bytes if pad is True
        """
        bits = []
        for field, nbits in self._DATA_LAYOUT:
            if field == "all_channel_data":
                bits += byte2bits(self.dummy_data, nbits=self.ADC_NBITS)
                for i in range(self.N_CHANNEL):
                    bits += byte2bits(self.data[i], nbits=self.ADC_NBITS)
                bits += byte2bits(self.cm_data, nbits=self.ADC_NBITS)
            elif field == "status_bits":
                bits += [self.dummy_status] + self.channel_status + [self.cm_status]
            else:
                bits += byte2bits(getattr(self, field), nbits=nbits)
        if pad and (len(bits) % 8) != 0:
            npad = 8 - (len(bits) % 8)
            bits += npad * [0]
        return bits

    @classmethod
    def from_hexstr(cls, hexstr):
        """
        Given the hex string printed out by something like
        `vatactrl 0 --read-fifo`, get the data packet.
        """
        return cls(hexstr2bytes(hexstr))


class DataPacket(object):
    """
    Class to parse a multi-asic, single event data packet.

    Expect packet to start with header info,
    then present the number of bytes for each asic,
    then the asic data.
    """

    ## Header content, and data size for each field
    _HEADER_LAYOUT = [
        ("packet_size", DataSz.u16),  ## was npacket
        ("header_size", DataSz.u8),
        ("packet_flags", DataSz.u16),
        ("packet_time", DataSz.u64),
        ("nasic", DataSz.u8),
    ]
    _ASIC_NDATA_SZ = DataSz.u16

    ##N_HEADER = 3  ## Number of bytes in header.
    ##N_ASIC = 2  ## This may get included in the data packet?

    def __init__(self, data):
        """
        Initialize the DataPacket.
        `data` can be:
            * bytes
            * file name
            * None (to not set anything)
        NOTE: 4's used everywhere as this is u32 data size in bytes.
        """
        if data is not None:
            if type(data) is str:
                data = open(data, "rb").read()
            assert type(data) is bytes
            self.parse_asic_data(self.parse_header(data))
            ##self.packet_size = 91  ## XXX KLUDGE XXX FIXME XXX

    def __repr__(self):
        ##return f"DataPacket<event_type={self.event_type},event_counter={self.event_counter},n_asic={self.nasic}>"
        return f"DataPacket<n_asic={self.nasic},time={self.packet_time}>"

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
            nbytes = bytes2val(data[: self._ASIC_NDATA_SZ])
            self.asic_nbytes.append(nbytes)
            data = data[self._ASIC_NDATA_SZ :]
        for nbytes in self.asic_nbytes:
            if nbytes == 0:
                ## No data for current asic.
                self.asic_packets.append(None)
            else:
                self.asic_packets.append(AsicPacket(data[:nbytes]))
                data = data[nbytes:]
        return data

    def to_bytes(self, return_bits=False):
        """
        This will return the bytes for the data packet.
        XXX NOT TESTED AT ALL YET!!!!! XXX
        """
        bits = []
        for field, nbytes in self._HEADER_LAYOUT:
            val = getattr(self, field)
            bits += byte2bits(getattr(self, field), nbits=8 * nbytes)
        for i in range(self.nasic):
            bits += byte2bits(self.asic_nbytes[i], nbits=8 * self._ASIC_NDATA_SZ)
        for ap in self.asic_packets:
            bits += ap.to_bits(pad=True)
        if return_bits:
            return bits
        else:
            return bits2bytes(bits)


class DataPackets(object):
    """
    Class for managing the parsing of flat binary data files,
    to produce other formats.
    Currently produces hdf5.
    """

    ## _hdf5_asic_fields:
    ##      data that we extract from each asic, and will have a
    ##      dataset in hdf5 under `/asicXX/`.
    _hdf5_asic_fields = [
        "event_id",
        "event_number",
        "trigger_status",
        "running_time",
        "live_time",
        "start_bits",
        "stop_bits",
        "trigger_bits",
        "chip_data_bits",
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
        "packet_size",
        "header_size",
        "packet_flags",
        "packet_time",
        ##"event_counter",
        ##"event_type",
        ##"live_time_counter",
        ##"real_time_counter",
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
            n_dp += 1
            if n_packet > 0 and n_dp >= n_packet:
                break

    @staticmethod
    def c_iter_data_packets(fname, n_packet=0):
        """
        Use the _raw2hdf c extension to iterate data packets.
        Here, you must supply a file name as opposed to filename/bytes
        """
        p = _raw2hdf.init_parser(fname)
        n_dp = 0
        while True:
            dp = _raw2hdf.parse_data_packet(p)
            if dp == {}:
                ### Empty dictionary returned on EOF
                break
            self = DataPacket(None)
            for attr, _ in self._HEADER_LAYOUT:
                setattr(self, attr, dp[attr])
            self.asic_nbytes = [
                i + 1 for i in dp["asic_nbytes"]
            ]  ## XXX i+1 for below indexing.
            self.asic_packets = []
            asic_data = dp["asic_data"]
            for n in self.asic_nbytes:
                self.asic_packets.append(AsicPacket(asic_data[:n]))
                asic_data = asic_data[n:]
            yield self
            n_dp += 1
            if n_packet > 0 and n_dp == n_packet:
                break

    @classmethod
    def from_binary(cls, data, n_packet=0, use_c_ext=False):
        """
        Load the data from a flat binary file of data packets, or a byte string.
        If `n_packet` is 0, then entire data file/stream will be parsed.
        If `n_packet` > 0, then only read the requested number of packets.
        """
        self = cls()
        if use_c_ext:
            ## We can currently only iterate from file paths...
            assert type(data) is str
            iter_method = self.c_iter_data_packets
        else:
            iter_method = self.iter_data_packets
        self.data_packets = list(iter_method(data, n_packet=n_packet))
        self.n_packet = len(self.data_packets)
        self.n_asic = self.data_packets[0].nasic
        self.alloc_data()

        for j, dp in enumerate(self.data_packets):
            assert self.n_asic == dp.nasic
            ##self.time[j] = dp.time
            self.packet_size[j] = dp.packet_size
            self.header_size[j] = dp.header_size
            self.packet_flags[j] = dp.packet_flags
            self.packet_time[j] = dp.packet_time
            ##self.event_counter[j] = dp.event_counter
            ##self.real_time_counter[j] = dp.real_time_counter
            ##self.live_time_counter[j] = dp.live_time_counter
            for i, ap in enumerate(dp.asic_packets):
                self.event_id[i, j] = ap.event_id
                self.event_number[i,j] = ap.event_number
                self.trigger_status[i,j] = ap.trigger_status
                self.running_time[i,j] = ap.running_time
                self.live_time[i,j] = ap.live_time
                self.start_bits[i, j] = ap.start_bit
                self.stop_bits[i, j] = ap.stop_bit
                self.trigger_bits[i, j] = ap.trigger_bit
                self.chip_data_bits[i, j] = ap.chip_data_bit
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
        sz = (self.n_asic, self.n_packet)
        u8 = DataSz.to_type[DataSz.u8]
        u16 = DataSz.to_type[DataSz.u16]
        u32 = DataSz.to_type[DataSz.u32]
        u64 = DataSz.to_type[DataSz.u64]

        self.packet_size = np.zeros(self.n_packet, dtype=u16)
        self.header_size = np.zeros(self.n_packet, dtype=u8)
        self.packet_flags = np.zeros(self.n_packet, dtype=u16)
        self.packet_time = np.zeros(self.n_packet, dtype=u64)
        ##self.event_type = np.zeros(self.n_packet, dtype=u16)
        ##self.event_counter = np.zeros(self.n_packet, dtype=u32)
        ##self.real_time_counter = np.zeros(self.n_packet, dtype=u64)
        ##self.live_time_counter = np.zeros(self.n_packet, dtype=u64)
        self.event_id = np.zeros(sz, dtype=u32)
        self.event_number = np.zeros(sz, dtype=u32)
        self.trigger_status = np.zeros(sz, dtype=u32)
        self.running_time = np.zeros(sz, dtype=u64)
        self.live_time = np.zeros(sz, dtype=u64)
        ##self.event_times = np.zeros(sz, dtype=u64)
        self.start_bits = np.zeros(sz, dtype=np.bool)
        self.stop_bits = np.zeros(sz, dtype=np.bool)
        self.trigger_bits = np.zeros(sz, dtype=np.bool)
        self.chip_data_bits = np.zeros(sz, dtype=np.bool)
        self.seu_bits = np.zeros(sz, dtype=np.bool)
        self.dummy_status = np.zeros(sz, dtype=np.bool)
        self.channel_status = np.zeros(sz + (AsicPacket.N_CHANNEL,), dtype=np.bool)
        self.cm_status = np.zeros(sz, dtype=np.bool)
        self.cm_data = np.zeros(sz, dtype=u16)
        self.dummy_data = np.zeros(sz, dtype=u16)
        self.data = np.zeros(sz + (AsicPacket.N_CHANNEL,), dtype=u16)

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
                field_name = "asic%02d/%s" % (n, field)
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
                field_name = "asic%02d/%s" % (n, field)
                data.append(f[field_name][...])
            setattr(self, field, np.array(data))
        return self

    def iter_byte_packets(self):
        """
        Return an iterator that will return the bytes for each packet upon iteration.
        This is the easiest way to get a single data packet at a time.
        """
        for j in range(self.n_packet):
            dp = DataPacket(None)
            for field_name, _ in dp._HEADER_LAYOUT:
                if field_name == "nasic":
                    dp.nasic = self.n_asic
                else:
                    setattr(dp, field_name, getattr(self, field_name)[j])
            ## Assume that we have full data packets
            dp.asic_nbytes = [
                AsicPacket.N_READS_PER_PACKET * DataSz.u32 for _ in range(dp.nasic)
            ]
            dp.asic_packets = []
            for i in range(self.n_asic):
                ap = AsicPacket(None)
                ap.event_id = self.event_id[i, j]
                ##ap.event_time = self.event_times[i, j]
                ap.start_bit = self.start_bits[i, j]
                ap.stop_bit = self.stop_bits[i, j]
                ap.stop_bit = self.stop_bits[i, j]
                ap.trigger_bit = self.trigger_bits[i, j]
                ap.chip_data_bit = self.chip_data_bits[i, j]
                ap.seu_bit = self.seu_bits[i, j]
                ap.dummy_status = self.dummy_status[i, j]
                ap.channel_status = list(self.channel_status[i, j, :])
                ap.cm_status = self.cm_status[i, j]
                ap.cm_data = self.cm_data[i, j]
                ap.dummy_data = self.dummy_data[i, j]
                ap.data = list(self.data[i, j, :])
                dp.asic_packets.append(ap)

            yield dp.to_bytes()

    def to_bytes(self):
        """
        Return the bytes for all data packets.
        """
        return reduce(_add, list(self.iter_byte_packets()))


## vim: set ts=4 sw=4 sts=4 et:
