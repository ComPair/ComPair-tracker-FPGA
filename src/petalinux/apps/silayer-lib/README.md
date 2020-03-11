# silayer-lib

This contains the source to build the `sictrl` library used
for controlling stuff on the silayer. Consists of the
vata, cal, and dac control classes.

## To build: (someday... see note right below this)

1) scp this directory onto the zynq, then ssh to the zynq and cd to the directory.

2) run `make && make install`


## Note on badness
*Currently this must be built in the vivado SDK!!!*
I am having issues cross-compiling the `cal_ctrl` stuff
with petalinux. Project compiles, but no actions seem to
happen.

*SO*:all code in src/ and include/ needs to be copied
into a vivado library project to successfully build a library.
Then, the include/ headers and built library need to be scp'd
to the zynq.

