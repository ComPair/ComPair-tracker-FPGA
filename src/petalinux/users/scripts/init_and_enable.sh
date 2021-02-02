#!/bin/sh
echo "Enabling mio..."
./mio_init.sh

echo "Configuring IIC GPIO..."
./iic_gpio_init.sh

echo "Enabling FEE..."
./fee_enable.sh