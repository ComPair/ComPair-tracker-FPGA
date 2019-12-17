#!/usr/bin/env python3
import numpy as np
import h5py

def byte2bits(byte):
    """
    Return a list of bits, LSB..MSB
    """
    return [byte >> i & 1 for i in range(8)]

def bits2val(bitarr):
    """
    Convert list of bits to unsigned integer
    """
    val, fac = 0, 1
    for bit in bitarr:
        val += bit * fac
        fac *= 2
    return val

def bytes2bits(bytestr):
    """
    Return entire byte array as bit array, LSB .. MSB
    """
    bits = [byte2bits(byte) for byte in bytestr]
    ret = []
    for byte_bit in bits:
        for bit in byte_bit:
            ret.append(bit)
    return ret

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
            if field == "all_channel_data":
                setattr(self, field, self.bits[start_bit : start_bit + n_bits])
            else:
                setattr(
                    self,
                    field,
                    bits2val(self.bits[start_bit : start_bit + n_bits]),
                )
        self.parse_channel_data()

    def parse_channel_data(self):
        start_bit = 0
        self.data = []
        self.dummy_data = bits2val(
            self.all_channel_data[start_bit : start_bit + 10]
        )
        for _ in range(self.N_CHANNEL):
            start_bit += 10
            bits = self.all_channel_data[start_bit : start_bit + 10]
            self.data.append(bits2val(bits))
        start_bit += 10
        self.cm_data = bits2val(self.all_channel_data[start_bit : start_bit + 10])

class DataPacket(object):
    """
    Class to parse a multi-asic, single event data packet.
    """
    N_ASIC = 2 ## This should get included in the data packet soon!
    def __init__(self, data):
        """
        Initialize the DataPacket.
        `data` can be:
            * bytes
            * file name
        """
        if type(data) is str:
            data = open(data, "rb").read()
        assert type(data) is bytes
        self.npacket = bytes2val(data[0:4])
        self.nasic = self.N_ASIC
        n_asic_data = [ 4*bytes2val(data[i:i+4]) for i in range(4, 4*(self.nasic+1), 4) ]
        self.asic_packets = []
        offset = 4*(self.nasic+1)
        for n_data in n_asic_data:
            self.asic_packets.append(AsicPacket(data[offset:offset+n_data]))
            offset += n_data
        self.nbytes = sum(n_asic_data) + 4*(self.nasic + 1)

class DataPackets(object):
    """
    Class for managing the parsing of flat binary data files,
    to producte other formats.
    Currently produces hdf5. Probably easy to put in dirfiles?
    """

    _hdf5_fields = [
        "event_ids",
        "start_bits",
        "stop_bits",
        "trigger_bits",
        "seu_bits",
        "status",
        "data",
        "cm_data",
        "dummy_data",
    ]

    @staticmethod
    def iter_data_packets(data):
        """
        Parse data or data binary file, yielding data packets.
        """
        if type(data) is str:
            data = open(data, "rb").read()
        assert type(data) is bytes
        ii = 0
        while ii < len(data):
            dp = DataPacket(data[ii:])
            ii += dp.nbytes
            yield dp
        
    @classmethod
    def from_binary(cls, data):
        """
        Load the data from a flat binary file of data packets, or a byte string.
        """
        self = cls()
        dps = [dp for dp in self.iter_data_packets(data)]
        n_packet = len(dps)
        n_asic = dps[0].nasic
        sz = (n_asic, n_packet,)
        self.event_ids = np.zeros(sz, dtype=np.uint32)
        self.start_bits = np.zeros(sz, dtype=np.bool)
        self.stop_bits = np.zeros(sz, dtype=np.bool)
        self.trigger_bits = np.zeros(sz , dtype=np.bool)
        self.seu_bits = np.zeros(sz, dtype=np.bool)
        self.status = np.zeros(sz, dtype=np.uint64)
        self.cm_data = np.zeros(sz, dtype=np.uint16)
        self.dummy_data = np.zeros(sz, dtype=np.uint16)
        self.data = np.zeros(sz + (AsicPacket.N_CHANNEL,), dtype=np.uint16)
        self.n_packet = n_packet
        self.n_asic = n_asic

        for j, dp in enumerate(dps):
            for i, ap in enumerate(dp.asic_packets):
                self.event_ids[i,j] = ap.event_id
                self.start_bits[i,j] = ap.start_bit
                self.stop_bits[i,j] = ap.stop_bit
                self.trigger_bits[i,j] = ap.trigger_bit
                self.seu_bits[i,j] = ap.seu_bit
                self.status[i,j] = ap.status_bits
                self.data[i, j, :] = ap.data
                self.cm_data[i,j] = ap.cm_data

        return self

    def write_hdf5(self, fname):
        """
        Write data to hdf5 file.
        XXX To Do: Put in compression here!
        """
        f = h5py.File(fname, "w")
        for field in self._hdf5_fields:
            full_data = getattr(self, field)
            for n in range(self.n_asic):
                data = full_data[n,...]
                field_name = "asic%02d/%s" % (n, field,)
                f.create_dataset(field_name, shape=data.shape, dtype=data.dtype, data=data)
        f.attrs["n_packet"] = self.n_packet
        f.attrs["n_asic"] = self.n_asic
        f.close()

    @classmethod
    def from_hdf5(cls, fname):
        self = cls()
        f = h5py.File(fname, "r")
        self.n_packet = f.attrs["n_packet"]
        self.n_asic = f.attrs["n_asic"]
        for field in self._hdf5_fields:
            data = []
            for n in range(self.n_asic):
                field_name = "asic%02d/%s" % (n, field,)
                data.append(f[field_name][...])
            setattr(self, field, np.array(data))
        return self

## vim: set ts=4 sw=4 sts=4 et:
