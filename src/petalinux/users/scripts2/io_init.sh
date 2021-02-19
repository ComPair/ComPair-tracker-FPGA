#!/bin/sh

INITLOCK=/home/root/.IOinitlock

if [ -f "$INITLOCK" ]; then 
  echo "FPGA I/O already initialized." 
else 
  echo "Initializing MIO and GPIO..." 
  
  /home/root/scripts/mio_init.sh
  /home/root/scripts/iic_gpio_init.sh
  touch $INITLOCK
fi