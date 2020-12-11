#!/usr/bin/env python3
import os
import sys
from time import sleep
import argparse
from silayer import Client
from silayer.cfg_reg import VataCfg

from silayer.cfg_reg import neg_default_vcfg, pos_default_vcfg

N_VATA = 12
DAC_COUNTS = 4000
HOLD_DELAY = 125    ## Clock cycles
PULSE_DELAY_MS = 10 ## milliseconds

def main(channel, cfg, n_pulse, pulse_delay_ms=PULSE_DELAY_MS):
    """
    Take cal pulse data.
    """
    client = Client("10.10.0.20") ## Connect to the silicon layer server.

    cfg.test_channel(channel) ## We will be sending cal pulses to this channel

    ## Update each asic's config:
    for vata in range(N_VATA):
        client.set_config(vata, cfg)
        client.trigger_enable_asic(vata)

    client.dac_set_delay()
    client.dac_set_counts("A", "cal", DAC_COUNTS)
    repeat_delay = int(pulse_delay_ms * 100000) ## Convert milliseconds to number of clock cycles
    client.cal_settings(200, 100, repeat_delay)

    ##channel_dir = f"data/chan-{channel:02d}"
    ##if not os.path.isdir(channel_dir):
    ##    os.system(f"mkdir -p {channel_dir}")

    for vata in range(N_VATA):
        client.set_hold(vata, HOLD_DELAY)
        client.reset_event_count(vata)
        client.clear_fifo(vata)
    ##client.start_data_stream(f"{channel_dir}/chan-{channel:02d}-hold-{hold_time:04d}.rdat")
    client.start_data_stream()
    sleep(0.1)
    client.cal_pulse_n_times(n_pulse)
    sleep(pulse_delay_ms * 1e-3 * n_pulse * 1.5) ## Wait for cal pulses to end, with 50% buffer
    sleep(1)
    client.stop_data_stream()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run hold-time sweep on a channel")
    parser.add_argument("channel", type=int)    
    parser.add_argument("--config-file", "-c", type=str, default=None)
    parser.add_argument("--pulse-delay", "-p", type=int, default=PULSE_DELAY_MS) ## In milliseconds
    parser.add_argument("--n-pulses", "-n", type=int, default=100)

    args = parser.parse_args()

    

    if args.config_file is None:
        config = neg_default_vcfg
    elif not os.path.isfile(args.config_file):
        raise ValueError(f"Config file: {args.config_file}. Not found.")
    else:
        with open(config_file, "rb") as f:
            config = VataCfg.from_binary(f.read())

    main(args.channel, config, args.n_pulses, args.pulse_delay)
