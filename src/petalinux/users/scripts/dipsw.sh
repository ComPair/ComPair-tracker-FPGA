#!/bin/sh

offset=890
dip_switches=0
for ((i=0; i<8; i++)) ; do
  this_sw=$(cat /sys/class/gpio/gpio$((offset+7-i))/value)
  dip_switches=$((dip_switches+this_sw*2**i))
done
echo $dip_switches