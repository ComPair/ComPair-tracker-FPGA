#!/bin/sh

echo 906 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio906/direction