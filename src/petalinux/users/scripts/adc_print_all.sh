#!/bin/bash
for adcnumber in {0..3}
do
for channel in {0..7}
do
  scale="$(cat /sys/bus/iio/devices/iio\:device${adcnumber}/in_voltage${channel}_scale)"
  raw_value="$(cat /sys/bus/iio/devices/iio\:device${adcnumber}/in_voltage${channel}_raw)"
  raw_value="$(cat /sys/bus/iio/devices/iio\:device${adcnumber}/in_voltage${channel}_raw)"
  raw_value="$(cat /sys/bus/iio/devices/iio\:device${adcnumber}/in_voltage${channel}_raw)"
#  echo "Channel = ${channel}"
#  echo "Scale = ${scale}"
#  echo "Raw value = ${raw_value}"
  #scaled_voltage=$((scale \* raw_value))
  scaled_voltage_mv=$(echo "$scale * $raw_value" | bc )
  echo "ADC=${adcnumber}, Channel=${channel}, Voltage = ${scaled_voltage_mv} mV, raw=${raw_value}"
done
done