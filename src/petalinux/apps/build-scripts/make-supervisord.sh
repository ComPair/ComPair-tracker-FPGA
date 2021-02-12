#!/bin/bash
## This script will download supervisord and install it on the Zynq.

#ZMQ_VERSION="4.3.2" ## This is the latest zmq version
#ZMQ_SRCDIR=zeromq-${ZMQ_VERSION}
#ZMQ_TARBALL=${ZMQ_SRCDIR}.tar.gz

if [ -z "$1" ]; then 
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1

SILAYER=root@${IP_ADDR} 


echo "Installing setuptools..."
#wget https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz 1>/dev/null 2>/dev/null
wget https://files.pythonhosted.org/packages/b6/af/40f3587d4ebd54cdeb8f87ad7d189618e166e8057ebefd2acd4443aa94f4/setuptools-50.0.0.zip 1>/dev/null 2>/dev/null
SETUPTOOLS_ZIP=setuptools-50.0.0.zip
SETUPTOOLS_SRCDIR=setuptools-50.0.0

if [ ! -f $SETUPTOOLS_ZIP ]; then
    echo "ERROR: setuptools zip file wasn't downloaded?"
    exit 3
fi

DEST_DIR=/home/root/py/src/
ssh ${SILAYER} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"

unzip $SETUPTOOLS_ZIP 1>/dev/null
scp -r $SETUPTOOLS_SRCDIR ${SILAYER}:$DEST_DIR 1>/dev/null

ssh ${SILAYER} "cd ${DEST_DIR}/${SETUPTOOLS_SRCDIR} && python3 setup.py install" 

rm $SETUPTOOLS_ZIP
rm -r $SETUPTOOLS_SRCDIR


#echo "Installing supervisor..."
wget https://files.pythonhosted.org/packages/11/35/eab03782aaf70d87303b21a67c345b953d3b59d4e3971a568c51e523f5c0/supervisor-4.2.1.tar.gz 1>/dev/null 2>/dev/null	
SUPERVISOR_TARBALL=supervisor-4.2.1.tar.gz
SUPERVISOR_SRCDIR=supervisor-4.2.1

if [ ! -f $SUPERVISOR_TARBALL ]; then
    echo "ERROR: supervisord tarball wasn't downloaded?"
    exit 3
fi

tar -xvf $SUPERVISOR_TARBALL 1>/dev/null
scp -r $SUPERVISOR_SRCDIR ${SILAYER}:$DEST_DIR 1>/dev/null

ssh ${SILAYER} "cd ${DEST_DIR}/${SUPERVISOR_SRCDIR} && python3 setup.py install" 

rm ${SUPERVISOR_TARBALL}
rm -r ${SUPERVISOR_SRCDIR}

echo "Done."
## vim: set ts=4 sw=4 sts=4 et:
