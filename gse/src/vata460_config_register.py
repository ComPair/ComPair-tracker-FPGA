#!/usr/bin/env python
'''
Handler module for easy generation of configuration registers.
'''

import pandas as pd
import numpy as np

class register:
    
    def __init__(self, name, first_bit, length, description, value = 0):
        self.name = name
        self.first_bit = first_bit
        self.length = length
        self.value = value
        self.value_bin = "{0:b}".format(value)
        
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

    
class vata460_config_register:
    
    def __init__(self):
    
        data = pd.read_csv("vata460_config_register.csv")
        blacklist = [8, 9, 11, 28, 31]

        config_dict = {}
        
        indices = []

        for i, d in data.iterrows():
            if int(d['first_bit']) not in blacklist:
                config_dict[d['first_bit'] - 1] = register(d['name'], d['first_bit'] - 1, d['number_bits'], d['description'])
                indices += [d['first_bit'] -1]
            else:
                continue
                
        self.config_dict = config_dict
        self.indices = indices
        
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
        if register != 0:
            self.config_dict[register].set_value(value)
        else:
            #Register zero is little-endian. 
            self.config_dict[register].value = value
            self.config_dict[register].value_bin = "{0:07b}".format(value)[::-1]
            
        
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
        
        if vthr < 2**5 -1 and vthr > 0:
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
            
    def load_binary_register(self, binary_str, verbose=False):
        for i in self.indices:
            reg = self.get_register(i)
            bin_val = binary_str[i:i + len(reg)]
            if i == 0:
                bin_val = bin_val[::-1]
            if verbose:
                print(i, reg.name, bin_val, int(bin_val, 2))
                
            self.set_register_value(i, int(bin_val, 2))

        return 

def main():
    '''
    Run an example config file generation. 
    '''

    reg = vata460_config_register()
    
    reg.set_vthr(10)
    reg.set_polarity(-1)
    reg.set_test_channel(5)
    reg.set_iramp_values(12, 1, 1, 1)
    reg.set_readout_all(True)
    reg.make_binary_str()

    print(reg)
    print(reg.make_binary_str())

if __name__ =="__main__":
    main()