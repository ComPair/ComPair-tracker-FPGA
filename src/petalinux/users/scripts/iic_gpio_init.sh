#!/bin/sh
#i2cset -y 0 0x20 0x01 0xCF #hex(0b11001111), set LED and EEPROM CS to outputs, leave gbp4/5 as inputs


offset=890
flash_delay=0.25
for ((i=0; i<14; i++)) ; do
   this_pin=$((offset+i))
   echo "Setting up pin $this_pin" 
   echo $this_pin > /sys/class/gpio/export
done

for ((i=0; i<8; i++)) ; do
   this_pin=$((offset+i))
   echo "Setting $this_pin to IN" 
   echo in > /sys/class/gpio/gpio$this_pin/direction
   echo 1 > /sys/class/gpio/gpio$this_pin/active_low
done

for ((i=8; i<14; i++)) ; do
   this_pin=$((offset+i))
   echo "Setting $this_pin to OUT" 
   echo out > /sys/class/gpio/gpio$this_pin/direction
done


for ((i=8; i<14; i++)) ; do
   this_pin=$((offset+i))
   #echo "Setting pin $this_pin low" 
   echo 0 > /sys/class/gpio/gpio$this_pin/value
done
