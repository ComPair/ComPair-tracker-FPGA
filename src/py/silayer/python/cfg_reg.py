"""
Module for writing and reading the VATA 460.3 configuration register.
"""
from typing import List, Dict, Union

def val2bits(value: int, n_bits: int) -> List[int]:
    return [(value >> i) & 1 for i in range(n_bits)]


def bits2val(bits: List[int]) -> int:
    val = 0
    for i, bit in enumerate(bits):
        val += bit * (1 << i)
    return val


class Register:
    """
    Class for a single register within the vata configuration register.
    """

    def __init__(
        self, start_bit: int, n_bits: int, value: int = 0, name: str = ""
    ) -> None:
        self.start_bit = start_bit
        self.n_bits = n_bits
        self.max_value = (1 << n_bits) - 1
        self.value = value
        self.name = name

    @property
    def value(self) -> int:
        return self._value

    @value.setter
    def value(self, value: int) -> None:
        if value > self.max_value:
            raise ValueError(
                f"Attempt to set {self.name} to {value}. Max value: {self.max_value}"
            )
        elif value < 0:
            raise ValueError(
                f"Attempt to set {self.name} to {value}. Value must be >= 0"
            )
        self._value = value

    def __len__(self) -> int:
        return self.n_bits

    def __str__(self) -> str:
        return str(self.value)

    def __repr__(self) -> str:
        return repr(self.value)

    def bits(self) -> List[int]:
        return val2bits(self.value, self.n_bits)

    @classmethod
    def from_bits(cls, start_bit: int, bits: List[int], name: str = ""):
        """
        Create a register from the given bit list.
        You must also supply the starting location (`start_bit`)
        """
        return cls(start_bit, len(bits), bits2val(bits), name=name)


class ChannelRegister:
    """
    Class for registers which record the 32 fields together.
    """

    N_CHANNELS = 32

    def __init__(
        self,
        start_bit: int,
        n_bits: int,
        values: Union[int, List[int]] = 0,
        name: str = "",
    ) -> None:
        """
        start_bit: Where this register begins
        n_bits: total number of bits for the field. Must be divisible by 32!
        values: If integer, the value to set all channels to. Can also be 32-length iterable
        """
        if int(n_bits / self.N_CHANNELS) != n_bits / self.N_CHANNELS:
            hd = f"{name}: " if name else ""
            raise Exception(
                f"{hd}Number of bits ({n_bits}) not divisible by number of channels ({self.N_CHANNELS})"
            )
        self.start_bit = start_bit
        self.n_bits = n_bits
        self.n_bits_per_channel = n_bits // self.N_CHANNELS
        if not hasattr(values, "__iter__"):
            values = self.N_CHANNELS * [
                values,
            ]
        name_pfx = f"{name}_" if name else ""
        self.channel_registers = []
        itr = range(
            start_bit,
            start_bit + self.N_CHANNELS * self.n_bits_per_channel,
            self.n_bits_per_channel,
        )
        for i, j in enumerate(itr):
            self.channel_registers.append(
                Register(
                    j,
                    self.n_bits_per_channel,
                    value=values[i],
                    name=f"{name_pfx}chan{i:02d}",
                )
            )

    def __len__(self) -> int:
        return self.n_bits

    def __getitem__(self, k: int) -> int:
        """
        Get the corresponding channel's value.
        """
        return self.channel_registers[k].value

    def __setitem__(self, k: int, value: int) -> None:
        """
        Set the corresponding channels' value.
        """
        self.channel_registers[k].value = value

    def get_all_channel_values(self) -> List[int]:
        """
        Return all channel values as a list.
        """
        return [reg.value for reg in self.channel_registers]

    def set_all_channel_values(self, values: Union[int, List[int]]) -> None:
        """
        Set all channel values. If values is a single value,
        then all channels' values are set to that value.
        Else, values should be 32-length list of values to set.
        """
        if not hasattr(values, "__iter__"):
            values = self.N_CHANNELS * [
                values,
            ]
        for i, value in enumerate(values):
            self.channel_registers[i].value = value

    def __repr__(self) -> str:
        return repr([reg.value for reg in self.channel_registers])

    def __str__(self) -> str:
        return str([reg.value for reg in self.channel_registers])

    def bits(self) -> List[int]:
        """
        Concatenate all bits of all channel values together 
        """
        ret = []
        for reg in self.channel_registers:
            ret += reg.bits()
        return ret

    @classmethod
    def from_bits(cls, start_bit: int, bits: List[int], name: str = ""):
        n_bits = len(bits)
        n_bits_per_channel = n_bits // cls.N_CHANNELS
        values = [
            bits2val(bits[i : i + n_bits_per_channel])
            for i in range(0, n_bits, n_bits_per_channel)
        ]
        return cls(start_bit, n_bits, values, name)


class VataCfg:
    """
    Representation of the 520 bit configuration register.
    """

    N_BITS = 520

    ## Configuration register locations. Values are (start_bit, n_bits), or
    ## (start_bit, n_bits, default_value).
    _register_info = {
        "int_cal_dac": (0, 7),
        "all2": (9, 1, 1),
        "iramp_f3": (13, 1),
        "iramp_fb": (14, 1),
        "iramp_f2": (15, 1,),
        "cm_thr_dis": (16, 1,),
        "ro_all": (17, 1, 1),
        "ck_en": (18, 1),
        "prebi_hp": (19, 1),
        "cal_gen_on": (20, 1),
        "slew_on_b": (21, 1),
        "nside": (22, 1),
        "cc_on": (23, 1),
        "test_on": (24, 1),
        "low_gain": (25, 1),
        "negq": (26, 1),
        "adc_on_b": (28, 1),
        "va_ro": (29, 1),
        "ileak_offset": (31, 1),
        "adc_test1": (32, 1),
        "adc_test2": (33, 1),
        "dummy_delay": (34, 6),
        "chan_delay": (40, 192),
        "cm_disable_ref": (232, 1),
        "cm_disable_chan": (233, 32),
        "dthr": (265, 10,),
        "chan_disable": (275, 32),
        "chan_trim": (307, 128),
        "test_enable": (435, 32),
        "shabi_lg": (467, 1),
        "pos_il_1": (468, 1),
        "pos_il_2": (469, 1),
        "vthr": (470, 5),
        "bias_dac_ifp": (475, 4),
        "bias_dac_iramp": (479, 4),
        "bias_dac_ck_bi": (483, 4),
        "bias_dac_twbi": (487, 3),
        "bias_dac_sha_bias": (490, 3),
        "bias_dac_ifss": (493, 3),
        "bias_dac_ifsf": (496, 3),
        "bias_dac_vrc": (499, 3),
        "bias_dac_sbi": (502, 3),
        "bias_dac_pre_bias": (505, 3),
        "bias_dac_ibuf": (508, 3),
        "bias_dac_obi": (511, 3),
        "bias_dac_ioffset": (514, 3),
        "bias_dac_disc3_bi": (517, 3),
    }

    ## Which of the above registers are channel registers:
    _channel_registers = [
        "chan_delay",
        "cm_disable_chan",
        "chan_disable",
        "chan_trim",
        "test_enable",
    ]

    def __init__(self, **kwargs) -> None:
        """
        Initialize the configuration register.
        Any kwargs can be supplied, which will initialize the given register to the kwarg value.
        All other registers initialized to their defaults
        """
        self.registers = {}
        for name, args in self._register_info.items():
            start_bit, n_bits = args[0], args[1]
            value = 0 if len(args) < 3 else args[2]
            if name in self._channel_registers:
                self.registers[name] = ChannelRegister(
                    start_bit, n_bits, value, name=name
                )
            else:
                self.registers[name] = Register(start_bit, n_bits, value, name=name)
        for k, v in kwargs.items():
            self[k] = v

    def __iter__(self):
        """ Implement iterator that goes through register names. """
        return self._register_info.__iter__()

    ## __getitem__ and __setitem__ used to avoid directly interacting with registers.
    ## Requested set/get directly sets the register value.
    def __getitem__(self, k: Union[str, tuple]) -> int:
        """
        Get a register's value.
        For a channel register, possible to index with [name,chan] to
        retrieve a specific channel's value within the named register.
        """
        if hasattr(k, "__len__") and k[0] in self._channel_registers:
            return self.registers[k[0]][k[1]]
        elif k in self._channel_registers:
            return self.registers[k].get_all_channel_values()
        else:
            return self.registers[k].value

    def __setitem__(self, k: Union[str, tuple], value: int) -> None:
        """
        Set a register's value.
        For channel registers, possible to set with index [name,chan]
        to set a specific channel's value within the named register.
        """
        if hasattr(k, "__len__") and k[0] in self._channel_registers:
            self.registers[k[0]][k[1]] = value
        elif k in self._channel_registers:
            self.registers[k].set_all_channel_values(value)
        else:
            self.registers[k].value = value

    def __str__(self) -> str:
        s = ""
        for name in self:
            s += f"{name}: {self[name]}\n"
        return s[:-1]

    def __repr__(self) -> str:
        s = "VataCfg:\n"
        for name in self:
            s += f"  * {name}: {self[name]}\n"
        return s[:-1]

    def bits(self) -> List[int]:
        """
        Return list of bits for the configuration register.
        """
        bits = [0 for _ in range(self.N_BITS)]
        for reg in self.registers.values():
            bits[reg.start_bit : reg.start_bit + reg.n_bits] = reg.bits()
        return bits

    @classmethod
    def open(cls, fname: str):
        """
        Open the binary file found at `fname`, and parse to create a VataCfg
        """
        bits = []
        with open(fname, "rb") as f:
            for val in f.read():
                bits += val2bits(val, 8)
        bits = bits[: cls.N_BITS]

        self = cls()

        for name, args in self._register_info.items():
            start_bit, n_bits = args[0], args[1]
            reg_bits = bits[start_bit : start_bit + n_bits]
            if name in self._channel_registers:
                self.registers[name] = ChannelRegister.from_bits(
                    start_bit, reg_bits, name=name
                )
            else:
                self.registers[name] = Register.from_bits(
                    start_bit, reg_bits, name=name
                )

        return self

    def write(self, fname: str, pad_32bits: bool = True) -> None:
        """
        Write the configuration register to the specified file.
        pad_32bits is flag, whether to fill out configuration register
        so that length is divisible by 32.
        """
        bits = self.bits()
        if pad_32bits:
            n_pad = 32 - (len(bits) % 32)
            bits += n_pad * [0]
        bytestr = bytearray(bits2val(bits[i : i + 8]) for i in range(0, len(bits), 8))
        with open(fname, "wb") as f:
            f.write(bytestr)

    def set_polarity(self, polarity: Union[int, str]) -> None:
        if str(polarity) in ["1", "p", "pos", "+", "positive"]:
            self["nside"] = self["negq"] = 0
        elif str(polarity) in ["-1", "n", "neg", "-", "negative"]:
            self["nside"] = self["negq"] = 1
        else:
            raise ValueError(f"{polarity} is an unrecognized polarity value.")

    def set_iramp_values(self, dac_iramp: int, iramp_speed: int = 0) -> None:
        """
        Configure the DAC's iramp settings.
        * dac_iramp: Time for the ADC ramp voltage to increase by 1V.
        * iramp_speed: Speed of the ramp. Can only take the following values:
            -1: 1/2 of default speed (200 μs).
            0: default speed (100 μs).
            1: 2 x default speed (50 μs).
            2: 4 x default speed (25 μs).
        """
        if iramp_speed not in [-1, 0, 1, 2]:
            raise ValueError("Provided iramp_speed must be -1, 0, 1, or 2.")
        self["bias_dac_iramp"] = dac_iramp
        self["iramp_f3"] = 1 if iramp_speed == 2 else 0
        self["iramp_f2"] = 1 if iramp_speed == 2 or iramp_speed == 1 else 0
        self["iramp_fb"] = 1 if iramp_speed == -1 else 0

    def test_channel(self, channel: int) -> None:
        """
        Set the calibrator to test the given channel.
        """
        self["test_enable"] = 0
        self["test_enable", channel] = 1
        self["test_on"] = 1

    def test_off(self) -> None:
        self["test_on"] = self["test_enable"] = 0

    def set_readout_all(self, readout_all: bool = True) -> None:
        self["all2"] = self["ro_all"] = int(readout_all)

    
