#!/usr/bin/env python 

import time
import pyRigolCtl as RC

supplies = RC.RigolArray('supply_defaults.yaml')

supplies.power_down_all(verbose=True)