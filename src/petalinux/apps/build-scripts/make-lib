#!/bin/bash

if [ -z "$1" ]; then 
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1

#if ! ping -c 1 -w 1 $IP_ADDR 1>/dev/null; then
#    echo "Could not ping $IP_ADDR"
#    echo "Check SILAYER_IP in Makefile"
#    exit 2 
#fi

LIB_DIR=$(pwd)/../silayer-lib
DEST_DIR=/home/root/zynq/src/

ssh root@${IP_ADDR} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"
scp -r ${LIB_DIR} root@${IP_ADDR}:${DEST_DIR}
ssh root@${IP_ADDR} "cd ${DEST_DIR}/silayer-lib && make && make install"

## vim: set ts=4 sw=4 sts=4 et:
