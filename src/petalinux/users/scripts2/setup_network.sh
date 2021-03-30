#!/bin/bash

### Board startup script. 
### Person to blame: Sean Griffin 

SCRIPTDIR=/home/root/scripts2/

INITLOCK=/home/root/.initlock

if [ -f "$INITLOCK" ]; then 
  echo "MIO and GPIO already initialized." 
else 
  echo "Initializing MIO and GPIO..." 
  ~/scripts/io_init.sh
  touch $INITLOCK
fi

echo "Reading DIP configuration for board IP..."
offset=890
dip_switches=0
for ((i=0; i<8; i++)) ; do
  this_sw=$(cat /sys/class/gpio/gpio$((offset+7-i))/value)
  dip_switches=$((dip_switches+this_sw*2**i))
done
#echo $dip_switches


echo "Setting up board IP; target IP: 10.10.0.$dip_switches"
cp $SCRIPTDIR/interfaces_default $SCRIPTDIR/interfaces
sed -i "s/10.10.0.20/10.10.0.$dip_switches/" $SCRIPTDIR/interfaces

cp $SCRIPTDIR/interfaces /etc/network/interfaces

ifdown eth0; ifup eth0


hostname si-layer-$dip_switches


echo "Done!"
