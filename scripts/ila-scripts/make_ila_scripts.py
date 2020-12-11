#!/usr/bin/env python3
import subprocess as sp

for i in range(1, 13):
    script = f"gen_ila{i}.tcl"
    sp.check_call(["cp", "gen_ila0.tcl", script])
    sp.check_call(["sed", "-i", f"s/inter_0/inter_{i}/g", script])
    sp.check_call(["sed", "-i", f"s/ila_0/ila_{i}/g", script])
    sp.check_call(["sed", "-i", f"s/ASIC_0/ASIC_{i}/g", script])

