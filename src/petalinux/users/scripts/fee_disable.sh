#!/bin/sh
echo -n "spi1.2" > /sys/bus/spi/drivers/at25/unbind
echo -n "spi2.2" > /sys/bus/spi/drivers/at25/unbind
echo 0 > /sys/class/gpio/gpio906/value