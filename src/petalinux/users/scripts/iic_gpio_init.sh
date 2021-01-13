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
  this_sw=$(cat /sys/class/gpio/gpio$((offset+i))/value)
  echo "DIP$i = $this_sw"
  dip_switches=$((dip_switches+this_sw*2**i))
done
echo "Value = $dip_switches"


<<COMMENT1
echo 887 > /sys/class/gpio/export
echo 888 > /sys/class/gpio/export
echo 889 > /sys/class/gpio/export
echo 890 > /sys/class/gpio/export

echo 891 > /sys/class/gpio/export
echo 892 > /sys/class/gpio/export
echo 893 > /sys/class/gpio/export
echo 894 > /sys/class/gpio/export

echo 895 > /sys/class/gpio/export # LED 1
echo 896 > /sys/class/gpio/export # LED 2
echo 897 > /sys/class/gpio/export # LED 3
echo 898 > /sys/class/gpio/export # LED 4
                                 
echo 899 > /sys/class/gpio/export #IIC-gpb4
echo 900 > /sys/class/gpio/export #IIC-gpb5
echo 901 > /sys/class/gpio/export #IIC-A-eeprom-csn
echo 902 > /sys/class/gpio/export #IIC-B-eeprom-csn


echo in > /sys/class/gpio/gpio887/direction
echo in > /sys/class/gpio/gpio888/direction
echo in > /sys/class/gpio/gpio889/direction
echo in > /sys/class/gpio/gpio890/direction
                               
echo in > /sys/class/gpio/gpio891/direction
echo in > /sys/class/gpio/gpio892/direction
echo in > /sys/class/gpio/gpio893/direction
echo in > /sys/class/gpio/gpio894/direction
                               
echo out > /sys/class/gpio/gpio895/direction # LED 1
echo out > /sys/class/gpio/gpio896/direction # LED 2
echo out > /sys/class/gpio/gpio897/direction # LED 3
echo out > /sys/class/gpio/gpio898/direction # LED 4
                                            
echo out > /sys/class/gpio/gpio899/direction #IIC-gpb4
echo out > /sys/class/gpio/gpio900/direction #IIC-gpb5
echo out > /sys/class/gpio/gpio901/direction #IIC-A-eeprom-csn
echo out > /sys/class/gpio/gpio902/direction #IIC-B-eeprom-csn



cat /sys/class/gpio/gpio887/value
cat /sys/class/gpio/gpio888/value
cat /sys/class/gpio/gpio889/value
cat /sys/class/gpio/gpio890/value
                   
cat /sys/class/gpio/gpio891/value
cat /sys/class/gpio/gpio892/value
cat /sys/class/gpio/gpio893/value
cat /sys/class/gpio/gpio894/value
                            
echo 1 > /sys/class/gpio/gpio895/value # LED 1
echo 0 > /sys/class/gpio/gpio896/value # LED 2
echo 0 > /sys/class/gpio/gpio897/value # LED 3
echo 0 > /sys/class/gpio/gpio898/value # LED 4
                           
echo 0 > /sys/class/gpio/gpio899/value #IIC-gpb4
echo 0 > /sys/class/gpio/gpio900/value #IIC-gpb5
echo 0 > /sys/class/gpio/gpio901/value #IIC-A-eeprom-csn
echo 0 > /sys/class/gpio/gpio902/value #IIC-B-eeprom-csn
COMMENT1