#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 ZYNQIP"
    exit 1
fi


IP_ADDR=$1

DEST_DIR=/home/root/

ssh root@${IP_ADDR} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"
scp -r scripts/ root@${IP_ADDR}:${DEST_DIR}
scp -r scripts2/ root@${IP_ADDR}:${DEST_DIR}