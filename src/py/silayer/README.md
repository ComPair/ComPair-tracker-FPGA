# silayer

`silayer` is a python package containing code for interacting
with the silayer server, and dealing with data sent to/from
a silayer's zynq.

* `silayer.client`
An API to the silayer server is provided by `silayer.client`.

* `silayer.raw2hdf`
Data parsing tools are found in `silayer.raw2hdf`. This module
was initially written with a focus on converting the raw binary
data packets emitted from the silayer zynq to hdf5 files, hence
the name.

* `silayer.cfg_reg`
The `cfg_reg` is a self-contained module for writing/reading
VATA 460.3 config registers.

* `silayer.data_recvr`
`data_recvr` exists to run a thread dedicated to receiving raw
data from the silayer data emitter, and writing to a flat binary
file. 

