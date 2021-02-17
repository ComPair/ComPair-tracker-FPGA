#!/bin/sh
#i2cset -y 0 0x20 0x01 0xCF #hex(0b11001111), set LED and EEPROM CS to outputs, leave gbp4/5 as inputs

offset=890
flash_delay=0.25



for ((i=8; i<14; i++)) ; do
   this_pin=$((offset+i))
   echo "Setting pin $this_pin low" 
   echo 0 > /sys/class/gpio/gpio$this_pin/value
done

for ((i=8; i<12; i++)) ; do
   echo 1 > /sys/class/gpio/gpio$((offset+i))/value
done
sleep $flash_delay
for ((i=8; i<12; i++)) ; do
   echo 0 > /sys/class/gpio/gpio$((offset+i))/value
done
sleep $flash_delay
for ((i=8; i<12; i++)) ; do
   echo 1 > /sys/class/gpio/gpio$((offset+i))/value
done
sleep $flash_delay
for ((i=8; i<12; i++)) ; do
   echo 0 > /sys/class/gpio/gpio$((offset+i))/value
done
sleep $flash_delay
for ((i=8; i<12; i++)) ; do
   echo 1 > /sys/class/gpio/gpio$((offset+i))/value
done
sleep $flash_delay
for ((i=0; i<4; i++)) ; do
   #echo 0 > /sys/class/gpio/gpio$((offset+11-i))/value
   echo 0 > /sys/class/gpio/gpio$((offset+8+i))/value
   sleep $flash_delay
done

dip_switches=0
for ((i=0; i<8; i++)) ; do
  this_sw=$(cat /sys/class/gpio/gpio$((offset+7-i))/value)
  echo "DIP$i = $this_sw"
  dip_switches=$((dip_switches+this_sw*2**i))
done
echo "Value = $dip_switches"