#!/usr/bin/env python 


import time
import silayer
import sys


if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <test cfg>")
    exit()

test_cfg = sys.argv[1]

tx = silayer.client.Client(host='localhost')

#tx.set_config(0, "/home/root//vatactrl/default.config")

#tx.get_n_fifo(0)

try:

    while True:
        for i in range(6):
            print("Sending... ")
            returned = tx.send_recv(f"vata {i} set-config-binary")
            print(f"Received response: [{returned}]")
            if returned == 'ready':
                with open(test_cfg,'rb') as f:
                    payload = f.read()
                    print(payload)
                    readback = tx.send_recv(payload)
                    print(f"Transmitted payload. Readback: {readback}")
            else: 
                print("Did not receive ready response.")
            time.sleep(1)   

except KeyboardInterrupt:
    tx.exit()
    exit()