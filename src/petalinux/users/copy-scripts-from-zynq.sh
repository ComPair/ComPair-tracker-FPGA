#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 ZYNQIP"
    exit 1
fi


IP_ADDR=$1

SRC_DIR=/home/root/


scp -pr root@${IP_ADDR}:${SRC_DIR}/scripts/* scripts/ 
scp -pr root@${IP_ADDR}:${SRC_DIR}/scripts2/* scripts2/ 
