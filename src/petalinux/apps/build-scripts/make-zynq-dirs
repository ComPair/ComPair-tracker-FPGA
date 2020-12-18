#!/bin/bash

## This script scp's the xilinx bsp headers to the zynq. 

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 BUILD ZYNQIP"
    exit 1
fi

BUILD=$1
IP_ADDR=$2

#if ! ping -c 1 -w 1 $IP_ADDR 1>/dev/null; then
#    echo "Could not ping $IP_ADDR"
#    echo "Check SILAYER_IP in Makefile"
#    exit 2 
#fi

BSP_DIR=$(pwd)/../../../../work/$BUILD/zynq/zynq.sdk/bsp_petalinux/ps7_cortexa9_0/include/
echo $BSP_DIR
ls $BSP_DIR

if [ ! -d $BSP_DIR ]; then
    echo "BSP directory not found"
    echo "Check BUILD in Makefile, or build the petalinux_bsp"
    exit 3 
fi

DEST_DIR=/home/root/zynq/include/bsp/
ETC_DIR=/home/root/zynq/etc/

ssh root@${IP_ADDR} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"
scp ${BSP_DIR}/* root@${IP_ADDR}:${DEST_DIR}
ssh root@${IP_ADDR} "if [ ! -d ${ETC_DIR} ]; then mkdir -p ${ETC_DIR}; fi"

## vim: set ts=4 sw=4 sts=4 et:
