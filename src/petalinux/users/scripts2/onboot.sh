#!/bin/sh

### Board startup script. 
### Person to blame: Sean Griffin 

INITLOCK=/home/root/.IOinitlock
rm $INITLOCK 

/home/root/scripts2/io_init.sh
/home/root/scripts2/setup_network.sh