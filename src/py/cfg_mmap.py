#!/usr/bin/env python2
"""
Stupid script to create the configuration data file.
"""
import os
import mmap
import struct

CFG_FNAME = "cfg_reg_cal.dat"
NBYTE = 68

IRAMP = 15
VTHRESH = 31

LITTLE_ENDIAN = '<' ## little
BIG_ENDIAN = '>' ## big

##ENDIAN = LITTLE_ENDIAN
ENDIAN = ''

def write_bit_one(mm, bit_loc):
    byte_loc = int(bit_loc / 8)
    bit_offset = bit_loc % 8
    cur_val = struct.unpack(ENDIAN + 'B', mm[byte_loc])[0];
    new_val = cur_val | (1 << bit_offset)
    mm[byte_loc] = struct.pack(ENDIAN + 'B', new_val)

def write_bit(mm, bit_loc, bit_value):
    byte_loc = int(bit_loc / 8)
    bit_offset = bit_loc % 8
    cur_val = struct.unpack(ENDIAN + 'B', mm[byte_loc])[0];
    if bit_value == 1:
        new_val = cur_val | (1<<bit_offset)
    else:
        new_val = cur_val & ~(1<<bit_offset)
        if new_val < 0:
            new_val += (1<<8)
    mm[byte_loc] = struct.pack(ENDIAN + "B", new_val)

def write_value(mm, bit_loc, value, nbits):
    for i in range(bit_loc, bit_loc+nbits):
        bit_val = value & 0x01
        if bit_val > 0:
            write_bit_one(mm, i)
        value = value >> 1

def get_bit(mm, bit_loc):
    byte_loc = int(bit_loc / 8)
    bit_offset = bit_loc % 8
    val = struct.unpack(ENDIAN + 'B', mm[byte_loc])[0]
    return (val >> bit_offset) & 0x01

def get_value(mm, bit_loc, nbits):
    value = 0
    for i in range(0, nbits):
        value |= (get_bit(mm, bit_loc+i) << i)
    return value

def get_mm_file(clear_data=False, cfg_fname=CFG_FNAME):
    if clear_data:
        f = open(cfg_fname, "w")
        for i in range(NBYTE):
            f.write('\x00')
        f.close()

    fd = os.open(cfg_fname, os.O_RDWR)
    return mmap.mmap(fd, 0)
    
def write_cfg(mm):
    write_bit(mm, 9, 1);
    write_bit(mm, 17, 1);
    write_bit(mm, 20, 1); ## Internal calibrator
    write_value(mm, 470, VTHRESH, 5);
    write_value(mm, 475, 10, 4);
    write_value(mm, 479, IRAMP, 4);
    write_value(mm, 496, 1, 3);
    write_value(mm, 499, 5, 3);
    write_value(mm, 514, 6, 3);

def write_cal_cfg(mm):
    ## ASIC setup
    ## readout all channels:
    write_bit(mm, 9, 1)
    write_bit(mm, 17, 1)
    ##  Other junk to set bias dac and readout:
    write_value(mm, 475, 10, 4);
    write_value(mm, 479, IRAMP, 4);
    write_value(mm, 496, 1, 3);
    write_value(mm, 499, 5, 3);
    write_value(mm, 514, 6, 3);
    
    ## CAL setup
    write_bit(mm, 24, 1)  ## Turn on external calibrator
    write_bit(mm, 435, 1) ## Set channel 0

def test_cfg(mm):
    assert get_bit(mm, 9) == 1
    assert get_bit(mm, 17) == 1
    assert get_bit(mm, 20) == 1
    assert get_value(mm, 470, 5) == VTHRESH
    assert get_value(mm, 475, 4) == 10
    assert get_value(mm, 479, 4) == IRAMP
    assert get_value(mm, 496, 3) == 1
    assert get_value(mm, 499, 3) == 5
    assert get_value(mm, 514, 3) == 6

def test_cal_cfg(mm):
    assert get_bit(mm, 9) == 1
    assert get_bit(mm, 17) == 1
    assert get_bit(mm, 24) == 1
    assert get_bit(mm, 435) == 1

def main(calibrate=True):
    if calibrate:
        mm = get_mm_file(clear_data=True, cfg_fname="cfg_reg_cal.dat")
        write_cal_cfg(mm)
        test_cal_cfg(mm)
    else:
        mm = get_mm_file(clear_data=True, cfg_fname="cfg_reg_norm.dat")
        write_cfg(mm)
        test_cfg(mm)
    

if __name__ == '__main__':
    main(calibrate=False)
    ##mm = get_mm_file(clear_data=False)
    ##test_cfg(mm)

## vim: set ts=4 sw=4 sts=4 et:
