"""trigger_mask

All trigger-enable mask information should be put in this module.

Current trigger fields
----------------------
Possible things to trigger off of:
* asics: other asic's on the layer.
* tm_hit: trigger module hit signal
* tm_ack: trigger module ack signal
* force_trigger: force-trigger signals.
"""

## This should be informed by vata_constants.hpp:
bit_locations = {
    "asics": (0, 12), ## Range of asic triggers, really [first-bit, last-bit)
    "tm_hit": 12,
    "tm_ack": 13,
    "force_trigger": 14,
}

def bit2bool(value, bit_num):
    """Check the bit-location within an unsigned integer.

    Parameters
    ----------
    value: int
        The number (LSB-ordered) that we are inspecting
    bit_num: The bit location to check within `value`

    Returns
    -------
    bit_value: True if the bit location is '1', False otherwise.
    """
    return ((value >> bit_num) & 1) == 1

def trigger_ena_dict(mask_value):
    """Get the trigger-enable dictionary corresponding to a given value.

    Parameters
    ----------
    val: int
        Number to interpret as a trigger-enable mask.

    Returns
    -------
    trigger_dict: dict
        Dictionary giving trigger-mask value for each trigger source.
        Dictionary keys are the field names, values are booleans.
        In the case of the "asics" field, the value is a list of 12
        bool's.
        All dictionary values are boolean.
    """
    return TriggerEnaMask(mask_value).to_dict()


class TriggerEnaMask:
    """Class for comprehending the vata trigger enable mask
    """

    def __init__(self, mask_value):
        """Initialize with the integer value for the mask
        """
        ## Asics are always the first 12 bits
        self.asics = [ bit2bool(mask_value, i) for i in range(12) ]
        ## get the rest from _bit_locations dict.
        for field in bit_locations:
            if field == "asics":
                continue
            setattr(self, field, bit2bool(mask_value, bit_locations[field]))

    def to_dict(self):
        """Get a dictionary representation.

        Returns
        -------
        ena_dict: A dictionary of the trigger-enable values.
        """
        ena_dict = dict((field, getattr(self, field)) for field in bit_locations if field != "asics")
        ena_dict["asics"] = self.asics
        return ena_dict
