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
scp -r cfg/ root@${IP_ADDR}:${DEST_DIR}/zynq/config/
scp -r lucas/profile.d/* root@${IP_ADDR}:/etc/profile.d/
scp -r sean/profile.d/* root@${IP_ADDR}:/etc/profile.d/


ssh root@${IP_ADDR} "mkdir -p ${DEST_DIR}/zynq/log/supervisord/"
ssh root@${IP_ADDR} "ln -fs ${DEST_DIR}/scripts/fee_disable.sh /etc/rc6.d/K999_fee_disable.sh"
ssh root@${IP_ADDR} "ln -fs ${DEST_DIR}/scripts2/onboot.sh /etc/rcS.d/S999_onboot.sh"
