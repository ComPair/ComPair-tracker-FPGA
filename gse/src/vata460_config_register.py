#!/usr/bin/env python
'''
Handler module for easy generation of configuration registers.
'''
import pandas as pd
import numpy as np

class register:
    
    def __init__(self, name, first_bit, length, description, value=0, little_endian=True):
        self.name = name
        self.first_bit = first_bit
        self.length = length
        self.value = value
        self.value_bin = "{0:b}".format(value)
        self.little_endian = little_endian
        if little_endian:
            self.value_bin = self.value_bin[::-1]
        
        
        if type(description) == str:
            self.description = description
        else:
            self.description = None
        
    def __str__(self):
        
        #formatter = "{0:d}b".format(length)
        #formatted = "{0:0" + formatter + "}"
        #ormatted_bin = formatted.format(self.value)  
        
        return "Name: {0:18s}\n\
        \tfirst_bit: {1:d}\
        \tlength: {2:5d}\
        \n\t\tvalue: {3:d}\
        \tvalue_bin:  {4:s}".format(self.name, self.first_bit, self.length, self.value, self.value_bin)
    
    def __len__(self):
        '''
        Quick way of getting the register length.
        '''
        
        return self.length

    def set_value(self, value):
        
        self.value = value
        format_str = "0{0:d}".format(self.length)
        format_str = "{0:" + format_str + "b}"
        
        self.value_bin = format_str.format(value)
        if self.little_endian:
            self.value_bin = self.value_bin[::-1]

    
class vata460_config_register:
    
    def __init__(self, filename=None, little_endian=True):
    
        data = pd.read_csv("vata460_config_register.csv")
        blacklist = [8, 9, 11, 28, 31]

        config_dict = {}
        
        indices = []

        for i, d in data.iterrows():
            if int(d['first_bit']) not in blacklist:
                config_dict[d['first_bit'] - 1] = register(d['name'],
                                                           d['first_bit'] - 1,
                                                           d['number_bits'],
                                                           d['description'],
                                                           little_endian=little_endian)
                indices += [d['first_bit'] -1]
            else:
                continue
                
        self.config_dict = config_dict
        self.indices = indices
        
        #If we're passing a filename we will load the configuration register from it.
        if filename is not None:
            self.set_register_binary(self.load_binary_register(filename))
        
    def __str__(self):
        all_regs = ""
        for key in self.config_dict.keys():
            all_regs += "Register {0:s}\n\n".format(self.config_dict[key].__str__())
        
        all_regs += "--------------\n" + self.make_binary_str()
        return all_regs

    def make_binary_mask(self, channel):
        #This value represents the mask in binary.
        return 2**(channel)
    
    def get_register(self, index):
        if index not in self.indices:
            raise ValueError("Invalid register index: {0:d} does not exist or is reserved.")
        else:
            return self.config_dict[index]
                
    def set_register_value(self, register, value):
        self.config_dict[register].set_value(value)
        ##if register != 0:
        ##    self.config_dict[register].set_value(value)
        ##else:
        ##    #Register zero is little-endian. 
        ##    self.config_dict[register].value = value
        ##    self.config_dict[register].value_bin = "{0:07b}".format(value)[::-1]
        
    def set_internal_cal_dac(self, cal_dac):
        '''
        Set the internal calibration DAC value to the configuration register. 
        Also turns on the internal calibration generator.
        '''
        
        if cal_dac > 2**7 -1 or cal_dac < 0:
            raise ValueError
        else:
            self.set_register_value(0, cal_dac)
            self.set_register_value(20, 1)
            
        return
    
    def set_iramp_values(self, dac, f3, fb, f2):
        '''
        Set the iramp DAC values and modifier bits. 
        '''
        
        iramp_registers = [479, 13, 14, 15]
        iramp_values = [dac, f3, fb, f2]
        for reg, val in zip(iramp_registers, iramp_values):
            self.set_register_value(reg, val)
            
        return
    
    def set_vthr(self, vthr):
        '''
        Set internal Vthr DAC.
        '''
        
        if vthr < 2**5 -1 and vthr >= 0:
            self.set_register_value(470, vthr)
        else:
            raise ValueError("Vthr={0:d} is out of bounds [0, 31)".format(vthr))

    def set_polarity(self, polarity):
        if str(polarity) in ['1', 'p', 'pos', '+', "positive"]:
            self.set_register_value(22, 0) #nside
            self.set_register_value(26, 0) #negQ                
        elif str(polarity) in ['-1', 'n', 'neg', '-', "negative"]:
            self.set_register_value(22, 1) #nside
            self.set_register_value(26, 1) #negQ                
        else:
            raise ValueError("{0:s} is an unrecognized polarity value.".format(str(polarity)))

        return

    
    def set_test_channel(self, channel):       
        self.set_register_value(435, self.make_binary_mask(channel))

        return
        
    def set_readout_all(self, readout_all = True):
        for i in [9, 17]:
            self.set_register_value(i, int(readout_all))      

        return
            
    def make_binary_str(self, verbose=False):
        binary_vals = np.array(['0' for i in range(520)], dtype=str)

        for index in self.indices: 
            r = self.get_register(index)
            binary_vals[index:index+len(r)] = [ch for ch in r.value_bin]

        binary_str = str("".join(binary_vals)) #convert to one long string
        if verbose:
            print(binary_str)
            
        return binary_str
            
    def set_register_binary(self, binary_str, verbose=False):
        '''
        Set the registers given a binary string.
        '''
        for i in self.indices:
            reg = self.get_register(i)
            bin_val = binary_str[i:i + len(reg)]
            if i == 0:
                bin_val = bin_val[::-1]
            if verbose:
                print(i, reg.name, bin_val, int(bin_val, 2))
                
            self.set_register_value(i, int(bin_val, 2))

        return 
    
    def load_binary_register(self, filename):
        '''
        Load a register from a binary file and turn it into a string.
        '''
        with open(filename, 'rb') as f:
            binary_cfg = f.read()

        binary_str = ""
        for b in binary_cfg:
            binary_str += "{0:08b}".format(b)
        
        return binary_str
        
    def write_binary_register(self, filename, zeropad_32bit=False):
        """
        Write the full register to disk in binary.
        * filename: where the configuration register is to be written
        * zeropad_32bit: Whether to pad the tail of the file with zeros,
          so that file length is multiple of 32 bits.
        """
        #Split configuration file into byte-sized chunks (ha!).
        binstr = self.make_binary_str(verbose=False)
        ## Perform byte-wise reordering here
        binstr_bytes = [binstr[i:i+8][::-1] for i in range(0, len(binstr), 8)]

        #Cast these to integers and then into a byte array.
        binstr_ints = [int(b, 2) for b in binstr_bytes]
        binstr_bytes = bytearray(binstr_ints)
        
        with open(filename, 'wb') as f:
            f.write(binstr_bytes)
            if zeropad_32bit:
                n_bytes_add = 4 - (len(binstr_bytes) % 4)
                for _ in range(n_bytes_add):
                    f.write(b'\x00')
        return


def main():
    '''
    Run an example config file generation. 
    '''

    reg = vata460_config_register()
    
    reg.set_vthr(15)
    reg.set_register_value(24, 1) ## test enable
    reg.set_polarity(1)
    reg.set_test_channel(0)
    reg.set_iramp_values(10, 0, 0, 0)

    reg.set_register_value(475, 10)
    reg.set_register_value(496, 1)
    reg.set_register_value(499, 5)

    reg.set_readout_all(True)

    reg.make_binary_str()

    print(reg)
    #print(reg.make_binary_str())

    return reg

if __name__ =="__main__":
    reg = main()
    ##reg.write_binary_register('test-cal-le-vthr8.dat', True)
    reg.write_binary_register('test-cal-vthr15-iramp10.dat', True)

## vim: set ts=4 sw=4 sts=4 et:
