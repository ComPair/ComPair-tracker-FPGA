#!/bin/bash
## This script will download the loguru logging utility, and compile + install on the zynq.

VERSION="2.1.0" ## This the latest loguru version
SRCDIR=loguru-${VERSION}
TARBALL=v${VERSION}.tar.gz

if [ -z "$1" ]; then 
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1
SILAYER=root@${IP_ADDR} 

wget https://github.com/emilk/loguru/archive/v${VERSION}.tar.gz

if [ ! -f $TARBALL ]; then
    echo "ERROR: loguru tarball wasn't downloaded?"
    exit 2
fi

DEST_DIR=/home/root/local/src/
ssh ${SILAYER} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"

tar -xvf $TARBALL 1>/dev/null

scp -r $SRCDIR ${SILAYER}:$DEST_DIR 1>/dev/null

echo "==== Building loguru ===="
ssh ${SILAYER} << EOF
    cd ${DEST_DIR}/${SRCDIR}
    g++ -std=c++11 loguru.cpp -c -lpthread -pthread -ldl
    ar rcs libloguru.a loguru.o
    cp loguru.hpp ../../include/
    cp libloguru.a ../../lib/
    cd ${DEST_DIR}
    ln -s ${SRCDIR} loguru
EOF

rm $TARBALL
rm -r $SRCDIR

## vim: set ts=4 sw=4 sts=4 et:
