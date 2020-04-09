#!/usr/bin/env python3
import os
import multiprocessing as mp
import zmq
import time

from . import data_recvr
from .cfg_reg import VataCfg

SILAYER_HOST = "si-layer.local"
DATA_PORT = 9998
SERVER_PORT = 5556

DAC_SIDES = ["A", "B"]
DAC_CHOICES = ["cal", "vth"]

def byte2bits(byte):
    return [byte >> i & 1 for i in range(8)]


def bytes2bits(bytes):
    ret = []
    for byte in bytes:
        ret += byte2bits(byte)
    return ret


def bytes2val(bytes):
    bits = bytes2bits(bytes)
    ret = 0
    for i, bit in enumerate(bits):
        ret += bit * (1 << i)
    return ret


class Client:
    """
    Class for interacting with a silayer server.
    """

    def __init__(
        self,
        host=SILAYER_HOST,
        server_port=SERVER_PORT,
        data_port=DATA_PORT,
        n_thread_context=1,
    ):
        """
        The client will connect to tcp://{host}:{server_port}

        On starting up a client, a process to handle receiving data from the
        silayer will also be started.
        """
        self.ctx = zmq.Context(n_thread_context)
        ## Main socket for communicating with the server:
        self.sock = self.ctx.socket(zmq.REQ)
        self.sock.connect(f"tcp://{host}:{server_port}")

        ## Set up the data receiver:
        self.recv_ctrl_sock = self.ctx.socket(zmq.REQ)
        ctrl_port = self.recv_ctrl_sock.bind_to_random_port(
            "tcp://*", min_port=64000, max_port=65000
        )
        self.recv_proc = mp.Process(
            target=data_recvr.main,
            args=(ctrl_port,),
            kwargs={"host": host, "data_port": data_port},
        )
        self.recv_proc.daemon = True  ## Force process to die when parent process does.
        self.recv_proc.start()
        self.data_streaming = False

    def send_recv(self, msg, return_binary=False):
        """
        Send and receive a message from the layer server
        """
        if type(msg) is str:
            msg = msg.encode()
        self.sock.send(msg)
        ret = self.sock.recv()
        if return_binary:
            return ret
        else:
            return ret.decode()

    def send_recv_uint(self, msg, nbytes_returned=0):
        """
        Send a message, expecting an unsigned int value to be sent back.
        If nbits_returned > 0, then check if returned number of bits
        matches nbits_returned. If not, raise ValueError.
        """
        ret = self.send_recv(msg, return_binary=True)
        if nbytes_returned > 0 and len(ret) != nbytes_returned:
            raise ValueError(f"Response: {ret.decode()}. Unexpected Length")
        return bytes2val(ret)

    def send_and_set_config(self, vata, config_register):
        """
        Send and set a VATA configuration register.
        params:
            vata: Which ASIC to configure. 
            config_register: full path to vata .vcfg binary register or a VataCfg instance.
        """
        if type(config_register) is str:
            if not os.path.isfile(config_register):
                raise ValueError(f"Specified path ({config_register}) is not a file.")
            with open(config_register, "rb") as f:
                payload = f.read()
        elif type(config_register) is VataCfg:
            payload = config_register.to_binary()

        ready = self.send_recv(f"vata {vata} set-config-binary")
        
        if ready != "ready":
            raise ValueError(f"Server is not ready: {ready}")
        else:
            return self.send_recv(payload)


    def set_config_zynq_path(self, vata, path):
        """
        Set the configuration to what is stored at `path` (on the silayer zynq!).
        Sets for the given asic.
        This should get updated to send raw data over!
        """
        return self.send_recv(f"vata {vata} set-config {path}")

    def get_config(self, vata):
        """
        Return the current configuration register for the given vata.
        """
        data = self.send_recv(f"vata {vata} get-config-binary", return_binary=True)
        return VataCfg.from_binary(data)

    def set_hold(self, vata, hold):
        return self.send_recv(f"vata {vata} set-hold {hold}")

    def get_hold(self, vata):
        msg = f"vata {vata} get-hold"
        return self.send_recv_uint(msg, nbytes_returned=4)

    def get_vata_counters(self, vata):
        """
        Return the running-time, live-time for the given asic.
        """
        ret = self.send_recv(f"vata {vata} get-counters", return_binary=True)
        if len(ret) != 16:
            raise ValueError(f"Response: {ret.decode()}. Unexpected Length.")
        return bytes2val(ret[:8]), bytes2val(ret[8:])

    def trigger_enable_bit(self, vata, bit_number=None):
        """
        Enable the trigger bit for the given asic.
        If `bit_number` is None, then enable all triggers.
        """
        if bit_number is None:
            bit_number = "all"
        return self.send_recv(f"vata {vata} trigger-enable-bit {bit_number}")

    def trigger_disable_bit(self, vata, bit_number=None):
        """
        Disable the trigger bit for the given asic.
        If `bit_number` is None, then disable all triggers.
        """
        if bit_number is None:
            bit_number = "all"
        return self.send_recv(f"vata {vata} trigger-disable-bit {bit_number}")

    def trigger_enable_asic(self, vata, asic_number=None):
        """
        Enable triggers from the local asic.
        If asic_number is `None`, then enable triggers from all asics
        (equivalent to having a local "fast-or" trigger)
        """
        if asic_number is None:
            asic_number = "all"
        return self.send_recv(f"vata {vata} trigger-enable-asic {asic_number}")

    def trigger_disable_asic(self, vata, asic_number=None):
        """
        Disable triggers from the local asic.
        If asic_number is `None`, then disable triggers from all asics.
        """
        if asic_number is None:
            asic_number = "all"
        return self.send_recv(f"vata {vata} trigger-disable-asic {asic_number}")

    def trigger_enable_tm_hit(self, vata):
        """
        Enable triggering off the trigger-module hit signal.
        """
        return self.send_recv(f"vata {vata} trigger-enable-tm-hit")
    
    def trigger_disable_tm_hit(self, vata):
        """
        Disable triggering off the trigger-module hit signal.
        """
        return self.send_recv(f"vata {vata} trigger-disable-tm-hit")

    def trigger_enable_tm_ack(self, vata):
        """
        Enable triggering off the trigger-module ack signal.
        """
        return self.send_recv(f"vata {vata} trigger-enable-tm-ack")
    
    def trigger_disable_tm_ack(self, vata):
        """
        Disable triggering off the trigger-module ack signal.
        """
        return self.send_recv(f"vata {vata} trigger-disable-tm-ack")

    def trigger_enable_forced(self, vata):
        """
        Enable triggering off the force-trigger signal.
        """
        return self.send_recv(f"vata {vata} trigger-enable-forced")
    
    def trigger_disable_forced(self, vata):
        """
        Disable triggering off the force-trigger signal.
        """
        return self.send_recv(f"vata {vata} trigger-disable-forced")

    def get_event_count(self, vata):
        """
        Return the event count for the given asic.
        """
        msg = f"vata {vata} get-event-count"
        return self.send_recv_uint(msg, nbytes_returned=4)

    def reset_event_count(self, vata):
        """
        Reset the asic's event count.
        """
        return self.send_recv(f"vata {vata} reset-event-count")

    def clear_fifo(self, vata):
        """
        Clear the asic's fifo.
        """
        return self.send_recv(f"vata {vata} clear-fifo")

    def get_n_fifo(self, vata):
        """
        Return the number of event packets in the asic's fifo.
        XXX THIS IS CURRENTLY RETURNING NUMBER OF BYTES XXX
        """
        return self.send_recv_uint(f"vata {vata} get-n-fifo", nbytes_returned=4)

    def cal_settings(
        self,
        cal_pulse_width,
        vata_trigger_delay,
        repeat_delay,
        cal_pulse_ena=True,
        vata_trigger_ena=False,
        vata_fast_or_disable=False,
    ):
        """
        Configure the external calibrator. Returns dictionary showing the return message
        from writing each setting. All values should be "ok"
        """
        return {
            "pulse-ena": self.send_recv(f"cal pulse-ena {1 if cal_pulse_ena else 0}"),
            "trigger-ena": self.send_recv(
                f"cal trigger-ena {1 if vata_trigger_ena else 0}"
            ),
            "fast-or-disable": self.send_recv(
                f"cal fast-or-disable {1 if vata_fast_or_disable else 0}"
            ),
            "pulse-width": self.send_recv(f"cal pulse-width {cal_pulse_width}"),
            "trigger-delay": self.send_recv(f"cal trigger-delay {vata_trigger_delay}"),
            "repeat-delay": self.send_recv(f"cal repeat-delay {repeat_delay}"),
        }

    def cal_pulse_start(self):
        """
        Start sending endless calibration pulses.
        """
        return self.send_recv("cal start-inf")

    def cal_pulse_stop(self):
        """
        Stop sending endless calibration pulses.
        """
        return self.send_recv("cal stop-inf")

    def cal_pulse_n_times(self, n):
        """
        Send out `n` calibration pulses according to current settings.
        """
        return self.send_recv(f"cal n-pulses {n}")

    def dac_set_delay(self, delay=200):
        """
        Set the spi clock speed. I think the default here of 200 is 
        what is recommended.
        """
        return self.send_recv(f"dac set-delay {delay}")

    def dac_get_delay(self):
        """
        Return the current DAC delay setting.
        """
        return self.send_recv_uint("dac get-delay", nbytes_returned=4)

    @staticmethod
    def check_dac_choices(side, dac_choice):
        """
        Raise `ValueError` if invalid `side` or `dac_choice` is used.
        Valid sides: 'A' or 'B'
        Valid dac choices: 'cal' or 'vth'
        """
        side = side.upper()
        dac_choice = dac_choice.lower()
        if side not in DAC_SIDES:
            raise ValueError(f"Invalid side: {side} must be in {DAC_SIDES}")
        if dac_choice not in DAC_CHOICES:
            raise ValueError(f"Invalid dac_choice: {dac_choice} must be in {DAC_CHOICES}")
        return side, dac_choice

    def dac_set_counts(self, side, dac_choice, counts):
        """
        Set the dac counts for the corresponding dac121s101.
        `side` must be 'A' or 'B'
        `dac_choice` must be 'cal' or 'vth'
        """
        side, dac_choice = self.check_dac_choices(side, dac_choice)
        return self.send_recv(f"dac set-counts {side} {dac_choice} {counts}")

    def dac_get_input(self):
        """
        Get the current dac input according to what is on the AXI register.
        """
        return self.send_recv_uint("dac get-input", nbytes_returned=4)

    def sync_counter_reset(self):
        """
        Reset the global, synchronous counter
        """
        return self.send_recv("sync counter-reset")

    def sync_counter(self):
        """
        Get the current synchronous counter value"
        """
        return self.send_recv_uint("sync get-counter", nbytes_returned=8)

    def sync_force_trigger(self):
        """
        Synchronously trigger all asics to take data
        """
        return self.send_recv("sync force-trigger")

    def start_data_stream(self, fname):
        """
        Start streaming data. Data will be saved to `fname`.
        """
        if self.data_streaming:
            raise Exception(
                "Attempted to start streaming data when we are already streaming"
            )
        self.recv_ctrl_sock.send(f"start {fname}".encode())
        msg = self.recv_ctrl_sock.recv().decode()
        self.send_recv("emit start")
        self.data_streaming = True
        if msg != "ok":
            raise ValueError(
                f"Data receiver process send unexpected message: {ret_msg}"
            )

    def stop_data_stream(self):
        """
        Stop streaming data.
        """
        if not self.data_streaming:
            raise Exception(
                "Attempted to stop streaming data when we are not streaming"
            )
        self.recv_ctrl_sock.send(f"stop".encode())
        msg = self.recv_ctrl_sock.recv().decode()
        self.send_recv("emit stop")
        self.data_streaming = False
        if msg != "ok":
            raise ValueError(
                f"Data receiver process send unexpected message: {ret_msg}"
            )

    def exit(self):
        """
        Call this before exiting! Using since __del__ didn't do what I thought it would.
        This will clean up the data recv process for you.
        """
        if self.data_streaming:
            self.recv_ctrl_sock.send(f"stop".encode())
            self.recv_ctrl_sock.recv()
        self.recv_ctrl_sock.send(f"exit".encode())
        self.recv_ctrl_sock.recv()
        self.recv_proc.join()
