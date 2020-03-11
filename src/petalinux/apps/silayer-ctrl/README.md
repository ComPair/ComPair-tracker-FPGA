# silayer-ctrls

This contains the "main" executables for `vatactrl`, `calctrl` and `dacctrl`.

They all rely on the sictrl library to be built and installed first, along
with the sictrl headers. Read the silayer-lib readme first.

Ultimately, scp this directory onto the zynq, and run `make && make install`
after installing the sictrl library.
