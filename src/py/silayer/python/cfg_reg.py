"""Module for writing and reading the VATA 460.3 configuration register.

The ``VataCfg`` class provides a dictionary-like interface for
manipulating specific registers within the configuration register.

The ``Register`` and ``ChannelRegister`` classes are helpers that
you probably won't need to worry about instantiating.

Examples
--------
Open a configuration file, at path "default.vcfg":

>>> vcfg = VataCfg.open("default.vcfg")

Set channel ``n`` to take external calibration pulses:

>>> vcfg.test_channel(n)

Get the binary data for the ``VataCfg``:

>>> config_bytes = vcfg.to_binary()

Save the configuration data to a binary file:

>>> vcfg.write("new-config.vcfg")

Create a new configuration, initialized with the default values for all registers:

>>> new_cfg = VataCfg()

A few examples using the dictionary like interface:
Set "vthr" to 10:

>>> new_cfg["vthr"] = 10

Attempt to set "vthr" to an unreasonable value:

>>> new_cfg["vthr"] = 1000
...
ValueError: Attempt to set vthr to 1000. Max value: 31

Turn the ``VataCfg`` into an honest dictionary:

>>> cfg_dict = {}
>>> for reg_name in vcfg:
...     cfg_dict[reg_name] = vcfg[reg_name] 

That last example isn't super useful, but I believe that pattern is,
of iterating over the ``VataCfg`` register names.
"""
from typing import List, Dict, Union


def val2bits(value: int, n_bits: int) -> List[int]:
    """Convert an integer to a bit list (list of 1's and 0's)

    Parameters
    ----------
    value: int
        The number to convert to a bit list.
    n_bits: int
        Length of bit list to return

    Returns
    -------
    bit_list: list
        Bit representation of ``value``. Ordering is little-endian,
        so 0th index of ``bit_list`` is the least-significant bit.
    """
    return [(value >> i) & 1 for i in range(n_bits)]


def bits2val(bits: List[int]) -> int:
    """Convert bit list to an unsigned integer.

    Parameters
    ----------
    bits: list
        List of 1's and 0's with little-endian ordering.

    Returns
    -------
    value: int
        Unsigned integer that the provided bits-list represents.
    """
    val = 0
    for i, bit in enumerate(bits):
        val += bit * (1 << i)
    return val


class Register:
    """Representation of a single register within the vata configuration register.
    """

    def __init__(
        self, start_bit: int, n_bits: int, value: int = 0, name: str = ""
    ) -> None:
        """
        Parameters
        ----------
        start_bit: int
            Bit number within the configuration register binary where this
            register starts.
        n_bits: int
            How many bits wide the register is.
        value: int, optional
            What value to initialize the register to. Defaults to 0.
        name: str, optional
            Name for the register. Defaults to ""
        """
        self.start_bit = start_bit
        self.n_bits = n_bits
        self.max_value = (1 << n_bits) - 1
        self.value = value
        self.name = name

    @property
    def value(self) -> int:
        """Get the value property for the register.

        Examples
        --------
        >>> reg = Register(0, 10, value=3, name="test")
        >>> reg.value
        3
        """
        return self._value

    @value.setter
    def value(self, value: int) -> None:
        """Set the value property for the register.

        Raises
        ------
        ValueError
            If provided value is negative or is too large for the register length.

        Examples
        --------
        >>> reg = Register(0, 10, value=3, name="test")
        >>> reg.value
        3
        >>> reg.value = 7
        >>> reg.value
        7
        """
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
        """Get the bit-list corresponding to the register

        Returns
        -------
        bits: list of 0's and 1's
            The bit representation of the register value.
            Ordered LSB..MSB
        """
        return val2bits(self.value, self.n_bits)

    @classmethod
    def from_bits(cls, start_bit: int, bits: List[int], name: str = ""):
        """Create a register from the given bit list.
        
        Parameters
        ----------
        start_bit: int
            Starting location within the full vata configuration for these bits
        bits: list of 0's and 1's
            Bits to initialize the register from.
        name: str, optional
            Name for the register.

        Returns
        -------
        register: Register
            A `Register` instance for the given bits.
        """
        return cls(start_bit, len(bits), bits2val(bits), name=name)


class ChannelRegister:
    """Class for registers which record the 32 fields together.

    Knows how to pack the channel data together, and provides
    tools to access a specific channel's data within the larger
    register.
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
        Parameters
        ----------
        start_bit: int
            Where this register begins within the full vata configuration.
        n_bits: int
            Total number of bits for the full field (not just the width for a single channel).
            .. warning:: Must be divisible by 32.
        values: int, list
            If integer, the value to set all channels to.
            If `values` is a list (or any iterable), then iterate over this and set each channel's
            data accordingly
        name: str
            Name for the full channel register.
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
        """Get the corresponding channel's value.

        Parameters
        ----------
        k: int
            Channel number. Must be in [0, 31].
        
        Example
        -------
        >>> values = [ i*i for i in range(32) ]
        >>> reg = ChannelRegister(10, 32*16, values=values)
        >>> reg[4]
        16
        >>> reg[31]
        961
        """
        return self.channel_registers[k].value

    def __setitem__(self, k: int, value: int) -> None:
        """Set the corresponding channels' value.
        
        Parameters
        ----------
        k: int
            Channel number. Must be in [0, 31]
        value: int
            Set the channel's register to this value.
        
        Example
        -------
        >>> reg = ChannelRegister(10, 32*16)
        >>> reg[0]
        0
        >>> reg[0] = 123
        >>> reg[0]
        123
        """
        self.channel_registers[k].value = value

    def get_all_channel_values(self) -> List[int]:
        """
        Returns
        -------
        values: list
            Returns all channel values as a list of int's.
        """
        return [reg.value for reg in self.channel_registers]

    def set_all_channel_values(self, values: Union[int, List[int]]) -> None:
        """Set all the channel values.

        Parameters
        ----------
        values: int or list 
            If a single int, then set all channels to this value.
            Otherwise, set n-th register to the n-th value within the list.
            .. warning:: If `values` is a list, it must be of length 32.
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
        """Concatenate all bits of all channel values together 
        
        Returns
        -------
        bit_list: list of 0's and 1's
            The bit representation of all channel data concatenated together.
        """
        ret = []
        for reg in self.channel_registers:
            ret += reg.bits()
        return ret

    @classmethod
    def from_bits(cls, start_bit: int, bits: List[int], name: str = ""):
        """Parse a bits list to produce a ChannelRegister

        Parameters
        ----------
        start_bit: int
            Where the channel register starts within the full vata configuration
            binary.
        bits: list of 0's and 1's
            Data to initialize channel values from.
            .. warning:: length of `bits` should be divisible by 32.
        name: str, optional
            Name for the channel register. Defaults to ""
        """
        n_bits = len(bits)
        n_bits_per_channel = n_bits // cls.N_CHANNELS
        values = [
            bits2val(bits[i : i + n_bits_per_channel])
            for i in range(0, n_bits, n_bits_per_channel)
        ]
        return cls(start_bit, n_bits, values, name)


class VataCfg:
    """Representation of the 520 bit configuration register.
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
        """Create the configuration register from a set of values.

        Parameters
        ----------
        **kwargs:
            Provide a set of kwargs for how you wish to initialize specific registers.
            Registers that you don't specify will be initialized to their default values.
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
        """Get a register's value with index syntax.

        Parameters
        ----------
        k: str or tuple
            The register name, or register name and channel number.
            For a channel register, possible to index with [name,chan] to
            retrieve a specific channel's value within the named register.

        Returns
        -------
        value: int or list
            Returns the register's value. If a channel register is being got,
            without specifying the channel number, all channel values are returned
            in a list.
        """
        if hasattr(k, "__len__") and k[0] in self._channel_registers:
            return self.registers[k[0]][k[1]]
        elif k in self._channel_registers:
            return self.registers[k].get_all_channel_values()
        else:
            return self.registers[k].value

    def __setitem__(self, k: Union[str, tuple], value: int) -> None:
        """Set a register's value using index syntax.
        
        Parameters
        ----------
        k: str or tuple
            Name of the register.
            For channel registers, possible to set with index [name,chan]
        value: int or list
            Value to set register to.
            For channel registers, when not indexing with channel number,
            possible to set register values with a length 32 list.
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
        """Get a bit-list representation of the full configuration.

        Returns
        -------
        bit_list: list
            List of 1's and 0's corresponding to the 520 bits for the configuration register.
        """
        bits = [0 for _ in range(self.N_BITS)]
        for reg in self.registers.values():
            bits[reg.start_bit : reg.start_bit + reg.n_bits] = reg.bits()
        return bits

    
    @classmethod
    def from_binary(cls, data: bytes):
        """Parse bytes and return a VataCfg
        
        Parameters
        ----------
        data: bytes
            Bytes to parse.

        Returns
        -------
        vcfg: VataCfg
            The vata configuration register corresponding to the given bytes.
        """
        bits = []
        for val in data:
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

    @classmethod
    def open(cls, fname: str):
        """Parse a binary file to create a VataCfg.

        Parameters
        ----------
        fname: str
            Path to the binary file to parse.

        Returns
        -------
        vcfg: VataCfg
            ``VataCfg`` resulting from parsing the binary file. 
        """
        with open(fname, "rb") as f:
            return cls.from_binary(f.read())

    def to_binary(self, pad_32bits: bool = True) -> bytes:
        """Get the bytes for a configuration.

        Parameters
        ----------
        pad_32bits: bool, optional
            Whether to pad out the returned bytes so that bytes can
            be chunked into full 32-bit wide pieces.
            ``pad_32bits`` should be ``True`` for setting data on
            32-bit wide axi registers.

        Returns
        -------
        data: bytes
            The bytes for this ``VataCfg``.
        """
        bits = self.bits()
        if pad_32bits:
            n_pad = 32 - (len(bits) % 32)
            bits += n_pad * [0]
        return bytes(bits2val(bits[i : i + 8]) for i in range(0, len(bits), 8))

    def write(self, fname: str, pad_32bits: bool = True) -> None:
        """Write the configuration register a file.

        Parameters
        ----------
        fname: str
            Path where file is created.
        pad_32bits: bool, optional
            Whether to pad out the returned bytes so that bytes can
            be chunked into full 32-bit wide pieces.
            ``pad_32bits`` should be ``True`` in almost all cases, as
            data ends up being written to 32-bit wide axi registers.
        """
        bytestr = self.to_binary(pad_32bits=pad_32bits)
        with open(fname, "wb") as f:
            f.write(bytestr)

    def set_polarity(self, polarity: Union[int, str]) -> None:
        """Set the vata's polarity

        Parameters
        ----------
        polarity: int or str
            What to set the polarity to.
            For positive, ``polarity`` should be in ``[1, "1", "p", "pos", "+", "positive"]``
            For negative, ``polarity`` should be in ``[-1, "-1", "n", "neg", "-", "negative"]``
        """
        if str(polarity) in ["1", "p", "pos", "+", "positive"]:
            self["nside"] = self["negq"] = 0
        elif str(polarity) in ["-1", "n", "neg", "-", "negative"]:
            self["nside"] = self["negq"] = 1
        else:
            raise ValueError(f"{polarity} is an unrecognized polarity value.")

    def set_iramp_values(self, dac_iramp: int, iramp_speed: int = 0) -> None:
        """Configure the DAC's iramp settings.
        
        Parameters
        ----------
        dac_iramp: int
            Value to set "bias_dac_iramp" to. Max value is 15.
        iramp_speed: int, optional
            Speed of the ramp, relative to the default speed.
            Must be -1, 0, 1, or 2
            * -1: 1/2 of default speed (200 μs).
            * 0: default speed (100 μs).
            * 1: 2 x default speed (50 μs).
            * 2: 4 x default speed (25 μs).
        """
        if iramp_speed not in [-1, 0, 1, 2]:
            raise ValueError("Provided iramp_speed must be -1, 0, 1, or 2.")
        self["bias_dac_iramp"] = dac_iramp
        self["iramp_f3"] = 1 if iramp_speed == 2 else 0
        self["iramp_f2"] = 1 if iramp_speed == 2 or iramp_speed == 1 else 0
        self["iramp_fb"] = 1 if iramp_speed == -1 else 0

    def test_channel(self, channel: int) -> None:
        """Enable external calibration testing to test a given channel.

        Parameters
        ----------
        channel: int
            Number of the channel to route external calibration pulses to.
        """
        self["test_enable"] = 0
        self["test_enable", channel] = 1
        self["test_on"] = 1

    def test_off(self) -> None:
        """Disable calibration testing
        """
        self["test_on"] = self["test_enable"] = 0

    def set_readout_all(self, readout_all: bool = True) -> None:
        """Set the vata to either readout all or not readout all.
        
        Parameters
        ----------
        readout_all: bool, optional
            The flag specifying if we are reading out all channels or not.
        """
        self["all2"] = self["ro_all"] = int(readout_all)
