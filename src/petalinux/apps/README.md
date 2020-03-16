# petalinux/apps directory

This directory will contain source code that builds *on* the silicon layer
processor (as opposed to being built by petalinux).

This is housed under petalinux/, which seemed sort of reasonable, as
this directory contains programs that will run on our petalinux
system.

This directory includes a makefile. If you edit the variables defined
at the top of the makefile, there's a good chance typing "make" will
result in copying things over and building on the zynq for you. Of course for
this to work, you'll have to have built bsp_petalinux
