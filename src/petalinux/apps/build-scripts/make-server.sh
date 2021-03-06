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

SERVER_DIR=$(pwd)/../silayer-server
DEST_DIR=/home/root/zynq/src/
LOGURU_PATH=/home/root/local/lib/libloguru.a

if ! ssh root@${IP_ADDR} "ls $LOGURU_PATH >/dev/null 2>/dev/null"; then
    echo "==== Loguru dependency has not been installed. Installing now. ===="
    ./make-loguru.sh $IP_ADDR
fi

echo "==== Copying server source to zynq ===="
ssh root@${IP_ADDR} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"
scp -r ${SERVER_DIR} root@${IP_ADDR}:${DEST_DIR}
echo "==== Building server ===="
ssh root@${IP_ADDR} << EOF
    cd ${DEST_DIR}/silayer-server
    make
    make install
EOF

## vim: set ts=4 sw=4 sts=4 et:
