#!/usr/bin/env python 

import time
from pyRigolCtl import *

supply_IPs = ["10.10.1.50", 
              "10.10.1.51", 
              "10.10.1.52", 
              "10.10.1.53"]


supply_channels = [2, 2, 3, 2] #This can almost certainly be pulled from the supply on connect. 
fpga_pair = [1, 2]

AFE_power_lines = [[0, 1], [0,2], 
                   [1, 0], #Second channel iss the FPGA.
                   [2, 0], [2, 2],
                   [3, 0], [3, 1]
                  ]

supply_handlers = [RigolSupply(ip, n_ch) for ip,n_ch in zip(supply_IPs, supply_channels)]
power_up_all(supply_handlers, verbose=False)
print("Waiting for FPGA to come online...")
time.sleep(5)
print("Done.")
report_status(supply_handlers)