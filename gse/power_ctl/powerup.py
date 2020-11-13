#!/usr/bin/env python 

import time
import pyRigolCtl as RC

supplies = RC.RigolArray('supply_defaults.yaml')

supplies.power_up_all(verbose=False)
print("Waiting for FPGA to come online...")
time.sleep(5)
print("Done.")
supplies.report_status()