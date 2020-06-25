#!/usr/bin/env python3
import os
import time
import json
import multiprocessing as mp
import zmq

from . import data_recvr
from .cfg_reg import VataCfg
from .trigger_mask import trigger_ena_dict

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
        """Connect to the silayer server on `f"tcp://{host}:{server_port}"`
        
        Parameters
        ----------
        host: str
            Hostname for the zynq where the silayer server is running
        port: int
            Port number to connect on.
        data_port: int
            Port number that data will be streamed from.
        n_thread_context: int
            Number of threads to use to manage ZMQ context.

        Notes
        -----
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
        """Send and receive a message from the layer server.
        
        Parameters
        ----------
        msg: str or bytes
            Message to send to the silayer server
        return_binary: bool, optional
            When True, return the received message as bytes. Otherwise, decode
            and return as a str.

        Returns
        -------
        response: str or bytes
            Message received from the silayer server. Type depends on what was
            set with the return_binary flag.
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
        """Send a message, expecting an unsigned int value to be sent back.
        
        Parameters
        ----------
        msg: str or bytes
            The message to send to the server.
        nbytes_returned: int, optional
            If nbytes_returned > 0, then check the returned number of bytes.

        Returns
        -------
        n: Interprets and returns the received message as an LSB-aligned unsigned integer.

        Raises
        ------
        ValueError
            Raised when nbytes_returned > 0, and returned message length does not
            match nbytes_returned.
        """
        ret = self.send_recv(msg, return_binary=True)
        if nbytes_returned > 0 and len(ret) != nbytes_returned:
            raise ValueError(f"Response: {ret.decode()}. Unexpected Length")
        return bytes2val(ret)

    def get_n_vata(self):
        """Get the number of vata's running on the layer.

        Returns
        -------
        nvata: int
            Number of vata's
        """
        return self.send_recv_uint("get-n-vata", nbytes_returned=1)

    def set_config(self, vata, config_register):
        """Set the configuration register on the designated VATA.
        
        Parameters
        ----------
        vata: int
            Which VATA to configure.
        config_register: str or VataCfg
            Full path to a vata .vcfg binary file or a VataCfg instance.
        """
        if type(config_register) is str:
            if not os.path.isfile(config_register):
                raise ValueError(f"Specified path ({config_register}) is not a file.")
            with open(config_register, "rb") as f:
                payload = f.read()
        elif type(config_register) is VataCfg:
            payload = config_register.to_binary()
        else:
            raise ValueError(
                f"Provided configuration register must be a string or a VataCfg"
            )

        ready = self.send_recv(f"vata {vata} set-config-binary")

        if ready != "ready":
            raise ValueError(f"Server is not ready: {ready}")
        else:
            return self.send_recv(payload)

    def send_and_set_config(self, vata, config_register):
        """
        See Also
        --------
        set_config: renaming this method to `set_config`
        .. warning:: This will be deprecated soon in favor of the `set_config` method.
        """
        print(
            "send_and_set_config is going away soon. Update scripts to use set_config"
        )
        return self.set_config(vata, config_register)

    def set_config_zynq_path(self, vata, path):
        """Set the configuration using a configuration file that is stored remotely
        on the silayer zynq.

        Parameters
        ----------
        vata: int
            Which vata is being configured
        path: str
            Path to the configuration file, on the zynq.

        Notes
        -----
        The `set_config` method is probably what you should use.
        """
        return self.send_recv(f"vata {vata} set-config {path}")

    def get_config(self, vata):
        """Get the current configuration register for a vata.
        
        Parameters
        ----------
        vata: int
            The vata to grab the configuration from.

        Returns
        -------
        vcfg: VataCfg
            The received vata configuration.
        """
        data = self.send_recv(f"vata {vata} get-config-binary", return_binary=True)
        return VataCfg.from_binary(data)

    def set_hold(self, vata, hold):
        """Set the hold delay for a vata.

        Parameters
        ----------
        vata: int
            Which vata's hold delay to set.
        hold: int
            The hold delay. Hold delay will be (`hold` * 10ns).
            .. warning:: `hold` should be less than 2^16
        """
        return self.send_recv(f"vata {vata} set-hold {hold}")

    def get_hold(self, vata):
        """Inspect the current hold-delay setting for a vata.

        Parameters
        ----------
        vata: int
            Which vata to query.

        Returns
        -------
        hold_delay: int
            The current hold delay
        """
        msg = f"vata {vata} get-hold"
        return self.send_recv_uint(msg, nbytes_returned=4)

    def get_vata_counters(self, vata):
        """Get the internal counters for the given vata.

        Parameters
        ----------
        vata: int
            Which vata to query.

        Returns
        -------
        counters: (int, int)
            A tuple with the running-time, live-time counters. 
        """
        ret = self.send_recv(f"vata {vata} get-counters", return_binary=True)
        if len(ret) != 16:
            raise ValueError(f"Response: {ret.decode()}. Unexpected Length.")
        return bytes2val(ret[:8]), bytes2val(ret[8:])

    def trigger_enable_bit(self, vata, bit_number=None):
        """Enable the trigger bit for the given asic.

        Parameters
        ----------
        vata: int
            Which vata's trigger mask is being changed.
        bit_number: int, optional
            The bit location within the trigger-ena mask that is being disabled.
            When bit_number is `None`, then all triggers are disabled.

        Notes
        -----
        What each bit corresponds to is not set in stone.
        The other trigger_enable_* methods are preferred over this one
        """
        if bit_number is None:
            bit_number = "all"
        return self.send_recv(f"vata {vata} trigger-enable-bit {bit_number}")

    def trigger_disable_bit(self, vata, bit_number=None):
        """Disable the trigger bit for the given asic.

        Parameters
        ----------
        vata: int
            Which vata's trigger mask is being changed.
        bit_number: int, optional
            The bit location within the trigger-ena mask that is being disabled.
            When bit_number is `None`, then all triggers are disabled.

        Notes
        -----
        What each bit corresponds to is not set in stone.
        The other trigger_disable_* methods are preferred over this one.
        """
        if bit_number is None:
            bit_number = "all"
        return self.send_recv(f"vata {vata} trigger-disable-bit {bit_number}")

    def trigger_enable_asic(self, vata, asic_number=None):
        """Enable triggers from a local asic or all local asics.
        
        Parameters
        ----------
        vata: int
            Which vata's local trigger mask is being changed.
        asic_number: int, optional
            The asic's whose triggers are being enabled.
            If asic_number is None, then enables triggers from all local asics
            (equivalent to a local "fast-or" trigger")
        """
        if asic_number is None:
            asic_number = "all"
        return self.send_recv(f"vata {vata} trigger-enable-asic {asic_number}")

    def trigger_disable_asic(self, vata, asic_number=None):
        """Disable triggers from a local asic or for all asics.

        Parameters
        ----------
        vata: int
            Which vata's local trigger mask is being changed.
        asic_number: int, optional
            The asic's whose triggers are being disabled.
            If asic_number is None, then disable triggers from all local asics.
        """
        if asic_number is None:
            asic_number = "all"
        return self.send_recv(f"vata {vata} trigger-disable-asic {asic_number}")

    def trigger_enable_tm_hit(self, vata):
        """Enable triggering off the trigger-module hit signal.
        
        Parameters
        ----------
        vata: int
            Which vata's TM-hit-trigger to enable.
        """
        return self.send_recv(f"vata {vata} trigger-enable-tm-hit")

    def trigger_disable_tm_hit(self, vata):
        """Disable triggering off the trigger-module hit signal.
        
        Parameters
        ----------
        vata: int
            Which vata's TM-hit-trigger to disable.
        """
        return self.send_recv(f"vata {vata} trigger-disable-tm-hit")

    def trigger_enable_tm_ack(self, vata):
        """Enable triggering off the trigger-module ack signal.
        
        Parameters
        ----------
        vata: int
            Which vata's TM-hit-ack to enable.
        """
        return self.send_recv(f"vata {vata} trigger-enable-tm-ack")

    def trigger_disable_tm_ack(self, vata):
        """Disable triggering off the trigger-module ack signal.
        
        Parameters
        ----------
        vata: int
            Which vata's TM-hit-ack to disable.
        """
        return self.send_recv(f"vata {vata} trigger-disable-tm-ack")

    def trigger_enable_forced(self, vata):
        """Enable triggering off the force-trigger signal.
        
        Parameters
        ----------
        vata: int
            Which vata's force-trigger to enable.
        """
        return self.send_recv(f"vata {vata} trigger-enable-forced")

    def trigger_disable_forced(self, vata):
        """Disable triggering off the force-trigger signal.

        Parameters
        ----------
        vata: int
            Which vata's force-trigger to disable.
        """
        return self.send_recv(f"vata {vata} trigger-disable-forced")

    def get_trigger_enable_mask(self, vata):
        """Get the trigger enable mask for a vata.

        Parameters
        ----------
        vata: int
            Which vata to fetch the trigger-enable mask from.

        Returns
        -------
        ena_mask: dict
            The trigger enable mask.
            Keys are `["asics", "tm_hit", "tm_ack", "force_trigger", "cal_pulse"]`
            Values for `ena_mask["asics"]` is an n-vata long list of bools.
            Values for the others are single boolean. True means "enabled".

        Notes
        -----
        If the trigger enable mask is updated, like if bit-locations change, then
        update the `TriggerEnaMask` class.
        """
        msg = f"vata {vata} get-trigger-ena-mask"
        mask_value = self.send_recv_uint(msg, nbytes_returned=4)
        ena_mask = trigger_ena_dict(mask_value)
        ena_mask["asics"] = ena_mask["asics"][: self.get_n_vata()]
        return ena_mask

    def get_event_count(self, vata):
        """Return the event count for the given asic.
        
        Parameters
        ----------
        vata: int
            Which vata's event counter to reset.

        Returns
        -------
        count: int
            The vata's internal event counter.
        """
        msg = f"vata {vata} get-event-count"
        return self.send_recv_uint(msg, nbytes_returned=4)

    def reset_event_count(self, vata):
        """Reset the vata's event count.
        
        Parameters
        ----------
        vata: int
            Which vata's event counter to reset.
        """
        return self.send_recv(f"vata {vata} reset-event-count")

    def clear_fifo(self, vata):
        """Clear the vata's fifo.

        Parameters
        ----------
        vata: int
            Which vata's fifo to clear.
        """
        return self.send_recv(f"vata {vata} clear-fifo")

    def get_n_fifo(self, vata):
        """Get the number of event packets in the vata's fifo.

        Parameters
        ----------
        vata: int
            Which vata's fifo to inspect

        Returns
        -------
        n: int
            Number of bytes.
            
        Notes
        -----
        XXX This needs to be updated to return number of events, not bytes!!! XXX
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
        """Configure the external calibrator.

        Parameters
        ----------
        cal_pulse_width: int
            The width of the calibration pulses, in 10ns clock cycles.
        vata_trigger_delay: int
            How long after rising edge of the cal pulse to send out a trigger to the
            vata cores.
        repeat_delay: int
            How long to delay between calibration pulses.
        cal_pulse_ena: bool, optional
            Whether to actually send out the calibration pulse.
        vata_trigger_ena: bool, optional
            Whether to actually send out the trigger signal to the vata cores.
        vata_fast_or_disable: bool, optional
            Whether to disable acceptance of the fast-or signal from the TM when
            the calibrator is running.
                
        Returns
        -------
        settings: dict
            Dictionary with the return messages from the server upon setting each parameter.
            Keys for `settings` are the parameters being set.
            Values within `settings` are the server response upon setting the given parameter.
            All values should be something like "ok".
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
        """Start sending endless calibration pulses.
        """
        return self.send_recv("cal start-inf")

    def cal_pulse_stop(self):
        """Stop sending endless calibration pulses.
        """
        return self.send_recv("cal stop-inf")

    def cal_pulse_n_times(self, n):
        """Repeat a number of uniformly separated calibration pulses according to
        the current calibrator settings.

        Parameters
        ----------
        n: int
            Number of calibration pulses.
        """
        return self.send_recv(f"cal n-pulses {n}")

    def dac_set_delay(self, delay=200):
        """Set the SPI clock speed via the clock delay setting.

        Parameters
        ----------
        delay: int, optional
            Clock delay. The default of 200 I think is the recommended value.
        """
        return self.send_recv(f"dac set-delay {delay}")

    def dac_get_delay(self):
        """ Return the current DAC delay setting.

        Returns
        -------
        delay: int
            The current DAC delay setting.
        """
        return self.send_recv_uint("dac get-delay", nbytes_returned=4)

    @staticmethod
    def check_dac_choices(side, dac_choice):
        """Check if dac parameter set is valid.
        
        Parameters
        ----------
        side: str
            Must be 'A' or 'B'
        dac_choice: str
            Must be 'cal' or 'vth'

        Returns
        -------
        choices: (str, str)
            choices are the provided `(side, dac_choice)`, but lower-cased, as
            is expected by functions using dac choice parameters.
        
        Raises
        ------
        ValueError
            If invalid `side` or `dac_choice` is used.
        """
        side = side.upper()
        dac_choice = dac_choice.lower()
        if side not in DAC_SIDES:
            raise ValueError(f"Invalid side: {side} must be in {DAC_SIDES}")
        if dac_choice not in DAC_CHOICES:
            raise ValueError(
                f"Invalid dac_choice: {dac_choice} must be in {DAC_CHOICES}"
            )
        return side, dac_choice

    def dac_set_counts(self, side, dac_choice, counts):
        """Set the dac counts for the corresponding dac121s101.

        Parameters
        ----------
        side: str
            Which side we are targeting. Must be 'A' or 'B'.
        dac_choice: str
            Which dac we are targeting. Must be 'cal' or 'vth'.
        """
        side, dac_choice = self.check_dac_choices(side, dac_choice)
        return self.send_recv(f"dac set-counts {side} {dac_choice} {counts}")

    def dac_get_input(self):
        """Get the current dac input according to the dac's axi register.

        Returns
        -------
        input: int
            The current dac input value.
        """
        return self.send_recv_uint("dac get-input", nbytes_returned=4)

    def sync_counter_reset(self):
        """Reset the global, synchronous counter
        """
        return self.send_recv("sync counter-reset")

    def sync_counter(self):
        """Read the current synchronous counter value

        Returns
        -------
        counter: int
            Current synchronous counter value
        """
        return self.send_recv_uint("sync get-counter", nbytes_returned=8)

    def sync_force_trigger(self):
        """Synchronously trigger all vatas with force-triggers enabled to take data.
        """
        return self.send_recv("sync force-trigger")

    def start_data_stream(self, dname=None):
        """Start streaming and recording data from the layer. Returns immediately.

        Parameters
        ----------
        dname: str, optional
            Name of directory to be created where data will be saved.
            If no directory name is provided, then a directory will be
            created with the current timestamp as its name.

        Raises
        ------
        Exception
            If this client is already streaming data.
        ValueError
            If the directory name points to an existing directory

        See Also
        --------
        stop_data_stream: method to stop the current data recording.
        """
        if self.data_streaming:
            raise Exception(
                "Attempted to start streaming data when we are already streaming"
            )
        if dname is None:
            dname = f"{int(time.time())}.rdir"

        if os.path.isdir(dname) or os.path.isfile(dname):
            raise ValueError(f"Requested save directory ({dname}) already exists.")

        os.makedirs(dname)
        os.makedirs(f"{dname}/configs")
        ## Collect configurations from server to store in data directory
        n_vata = self.get_n_vata()
        holds, trigger_enas = {}, {}
        for vata in range(n_vata):
            vname = f"asic{vata:02d}"
            holds[vname] = self.get_hold(vata)
            trigger_enas[vname] = self.get_trigger_enable_mask(vata)
            cfg = self.get_config(vata)
            with open(f"{dname}/configs/{vname}.vcfg", "wb") as f:
                f.write(cfg.to_binary())
        with open(f"{dname}/configs/hold-delay.json", "w") as f:
            json.dump(holds, f)
        with open(f"{dname}/configs/trigger-mask.json", "w") as f:
            json.dump(trigger_enas, f)

        ## Start up the data emitter/receiver
        self.recv_ctrl_sock.send(f"start {dname}/data.rdat".encode())
        msg = self.recv_ctrl_sock.recv().decode()
        self.send_recv("emit start")
        self.data_streaming = True
        if msg != "ok":
            raise ValueError(
                f"Data receiver process send unexpected message: {ret_msg}"
            )

    def stop_data_stream(self):
        """Stop streaming data.

        Raises
        ------
        Exception
            If no data is actually being streamed at the moment.
        ValueError
            If server responds with unexpected response.
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

    ##def exit(self):
    ##    """Cleanup the client before exiting a program that instantiated the client.

    ##    Notes
    ##    -----
    ##    Using since __del__ didn't do what I thought it would, so this is necessary to
    ##    cleanup the data receiver process.
    ##
    ##    Not actually sure if this is necessary, so this is commented out for now!
    ##    """
    ##    if self.data_streaming:
    ##        self.recv_ctrl_sock.send(f"stop".encode())
    ##        self.recv_ctrl_sock.recv()
    ##    self.recv_ctrl_sock.send(f"exit".encode())
    ##    self.recv_ctrl_sock.recv()
    ##    self.recv_proc.join()


