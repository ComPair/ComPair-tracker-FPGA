#!/bin/bash
## This script will download zeromq version 4.3.2 and build+install on the zynq.
## cppzmq (c++ header-only code) will then be downloaded, version 4.6.0, and installed.

ZMQ_VERSION="4.3.2" ## This is the latest zmq version
ZMQ_SRCDIR=zeromq-${ZMQ_VERSION}
ZMQ_TARBALL=${ZMQ_SRCDIR}.tar.gz

if [ -z "$1" ]; then 
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1

# if ! ping -c 1 -w 1 $IP_ADDR 1>/dev/null; then
#     echo "Could not ping $IP_ADDR"
#     echo "Check SILAYER_IP in Makefile"
#     exit 2 
# fi
SILAYER=root@${IP_ADDR} 

wget https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz 1>/dev/null 2>/dev/null

if [ ! -f $ZMQ_TARBALL ]; then
    echo "ERROR: ZMQ tarball wasn't downloaded?"
    exit 3
fi

DEST_DIR=/home/root/local/src/
ssh ${SILAYER} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"

tar -xvf $ZMQ_TARBALL 1>/dev/null
scp -r $ZMQ_SRCDIR ${SILAYER}:$DEST_DIR 1>/dev/null

## Issue with incorrect automake version during make, which shouldn't matter.
## Hence the autoconf hack:
AUTOCONF_HACK="AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=:"
ssh ${SILAYER} "cd ${DEST_DIR}/${ZMQ_SRCDIR} && ./configure --prefix=/home/root/local && make -j2 ${AUTOCONF_HACK} && make install ${AUTOCONF_HACK}"

rm $ZMQ_TARBALL
rm -r $ZMQ_SRCDIR

## Now get zmq.hpp, v4.6.0 (latest version as of 3/12/2020)
wget https://raw.githubusercontent.com/zeromq/cppzmq/v4.6.0/zmq.hpp 1>/dev/null 2>/dev/null

if [ ! -f "zmq.hpp" ]; then
    echo "ERROR: zmq.hpp was not downloaded"
    exit 4
fi
scp zmq.hpp ${SILAYER}:/home/root/local/include/
rm zmq.hpp

## vim: set ts=4 sw=4 sts=4 et:
