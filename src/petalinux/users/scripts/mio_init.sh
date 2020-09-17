#!/bin/sh
#Assuming MIO0 base offset is 906

#Set up MIO0 as an output (FEE shutdown_n)
echo 906 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio906/direction

#Set up MIO9 as an output, (LED5 and SW3)
echo 915 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio915/direction

#Set up MIO7 as an output, (LED1 on Trenz Module, Green, only works when zynq PS is running, otherwise TE CPLD)
echo 913 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio913/direction