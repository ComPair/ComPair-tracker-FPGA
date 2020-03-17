#!/bin/bash
channel=0
scale="$(cat /sys/bus/iio/devices/iio\:device3/in_voltage${channel}_scale)"
raw_value="$(cat /sys/bus/iio/devices/iio\:device3/in_voltage${channel}_raw)"
echo "Channel = ${channel}"
echo "Scale = ${scale}"
echo "Raw value = ${raw_value}"
#scaled_voltage=$((scale \* raw_value))
scaled_voltage_mv=$(echo "$scale * $raw_value" | bc )
echo "Voltage = ${scaled_voltage_mv} mV"
#awk "BEGIN{printf (\"%d\n\", (40603 + 0) * 0.044250488)}"