#!/bin/sh
echo 1 > /sys/class/gpio/gpio906/value
echo "Pausing for FEE power up..."
sleep 1
echo -n "spi1.2" > /sys/bus/spi/drivers/at25/bind
echo -n "spi2.2" > /sys/bus/spi/drivers/at25/bind