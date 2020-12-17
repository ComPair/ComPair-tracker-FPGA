#!/usr/bin/env python3

import silayer
from silayer.cfg_reg import neg_default_vcfg, pos_default_vcfg

import argparse
from time import sleep 

def main(side_A_config, side_B_config, n_pedestals, sleep_time, nostartup):

    """
    Take pedestal data. 
    Assumes the server running at 10.10.0.20
    """
    client = silayer.client.Client(host='10.10.0.20')
    if nostartup is False:
        client.startup_ASICs(side_A_config, side_B_config)

    client.start_data_stream()
    print(f"{n_pedestals}, {sleep_time}")
    n_sent = 0
    n_total = n_pedestals if n_pedestals is not None else "infinity"

    try:
        while True:
            client.sync_force_trigger()
            n_sent += 1 
            sleep(sleep_time / 1000.)

            if n_sent % 10 == 0 and n_sent != 0:
                print(f"Number sent: {n_sent}/{n_total}")
            if n_pedestals is not None and n_sent == n_pedestals:
                break
    except KeyboardInterrupt:
        client.stop_data_stream()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Configure all ASICs and enable forced triggers only for N events.")
    parser.add_argument("--side-A-config", "-A", type=str, default=None)
    parser.add_argument("--side-B-config", "-B", type=str, default=None)
    parser.add_argument("--sleep", "-s", type=int, default=10) ## In milliseconds
    parser.add_argument("--n-pedestals", "-n", type=int, default=None)
    parser.add_argument("--nostartup", "-S", action='store_true')

    args = parser.parse_args()

    #This could be made prettier but I'm on the clock.
    if args.side_A_config is None:
        side_A_config = neg_default_vcfg
    elif not os.path.isfile(args.side_A_config):
        raise ValueError(f"Config file: {args.side_A_config}. Not found.")
    else: 
        with open(config_file, "rb") as f:
            side_A_config = VataCfg.from_binary(f.read())
    
    if args.side_B_config is None:
        side_B_config = pos_default_vcfg
    elif not os.path.isfile(args.side_B_config):
        raise ValueError(f"Config file: {args.side_B_config}. Not found.")
    else: 
        with open(args.side_B_config, "rb") as f:
            side_B_config = VataCfg.from_binary(f.read())
   

    main(side_A_config, side_B_config, args.n_pedestals, float(args.sleep), args.nostartup)