#!/bin/sh
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