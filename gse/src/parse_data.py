#!/usr/bin/env python3
import numpy as np
import h5py


def byte2bits(byte):
    """
    Return a list of bits for the given byte, LSB..MSB
    """
    return [byte >> i & 1 for i in range(8)]


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


def bytes2val(bytestr):
    """
    Interpret string of bytes as single unsigned integer.
    So, length 4 bytestring should be interpreted as 32 bit integer.
    """
    return bits2val(bytes2bits(bytestr))


class AsicPacket(object):
    """
    Class for parsing binary data from a single asic, single event.
    """

    N_BYTES = 52
    N_CHANNEL = 32
    ADC_NBITS = 10

    ## _field_info: values are start_bit, n_bits for each field
    _field_info = {
        "event_id": (0, 32),
        "start_bit": (32, 1),
        "chip_data_bit": (33, 1),
        "trigger_bit": (34, 1),
        "seu_bit": (35, 1),
        "status_bits": (36, 34),
        "all_channel_data": (70, 340),
        "stop_bit": (410, 1),
    }

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
        self.bits = bytes2bits(data)
        self.parse_bits()

    def parse_bits(self):
        for field, (start_bit, n_bits) in self._field_info.items():
            bits = self.bits[start_bit : start_bit + n_bits]
            if field == "all_channel_data":
                self.set_channel_data(bits)
            elif field == "status_bits":
                self.set_status_bits(bits)
            else:
                setattr(self, field, bits2val(bits))

    def set_channel_data(self, bits):
        start_bit = 0
        self.data = []
        self.dummy_data = bits2val(bits[start_bit : start_bit + self.ADC_NBITS])
        for _ in range(self.N_CHANNEL):
            start_bit += self.ADC_NBITS
            channel_bits = bits[start_bit : start_bit + self.ADC_NBITS]
            self.data.append(bits2val(channel_bits))
        start_bit += self.ADC_NBITS
        self.cm_data = bits2val(bits[start_bit : start_bit + self.ADC_NBITS])

    def set_status_bits(self, bits):
        self.dummy_status = bits[0]
        self.channel_status = bits[1:-1]
        self.cm_status = bits[-1]


class DataPacket(object):
    """
    Class to parse a multi-asic, single event data packet.
    An intermediate class... unlikely to be instantiated directly when producing `DataPackets`.
    """

    N_HEADER = 3  ## Number of bytes in header.
    N_ASIC = 2  ## This may get included in the data packet?

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
        self.npacket = bytes2val(data[0:4])
        self.n_asic = self.N_ASIC
        self.time = bytes2val(data[4 : 4 * self.N_HEADER])
        ## Read the number of bytes in each asic's data packet from the header:
        n_asic_data = [
            4 * bytes2val(data[i : i + 4])
            for i in range(4 * self.N_HEADER, 4 * (self.n_asic + self.N_HEADER), 4)
        ]
        self.asic_packets = []
        offset = 4 * (self.n_asic + self.N_HEADER)
        for n_data in n_asic_data:
            self.asic_packets.append(AsicPacket(data[offset : offset + n_data]))
            offset += n_data
        self.nbytes = sum(n_asic_data) + 4 * (self.n_asic + self.N_HEADER)


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
        "time",
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
            start_byte += dp.nbytes
            n_dp += 1
            if n_packet > 0 and n_dp >= n_packet:
                break

    @classmethod
    def from_binary(cls, data, n_packet=0):
        """
        Load the data from a flat binary file of data packets, or a byte string.
        If `n_packet` is 0, then entire data file/stream will be parsed.
        If `n_packet` > 0, then only read the requeted number of packets.
        """
        self = cls()
        dps = [dp for dp in self.iter_data_packets(data, n_packet=n_packet)]
        self.n_packet = len(dps)
        self.n_asic = dps[0].n_asic
        self.alloc_data()

        for j, dp in enumerate(dps):
            assert self.n_asic == dp.n_asic
            self.time[j] = dp.time
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
        self.time = np.zeros(self.n_packet, dtype=np.uint64)
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
