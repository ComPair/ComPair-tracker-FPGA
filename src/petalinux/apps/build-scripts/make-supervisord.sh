#!/bin/bash
## This script will download supervisord and install it on the Zynq.
## TODO: Also install config file.

if [ -z "$1" ]; then 
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1
SILAYER=root@${IP_ADDR} 

# if ! ssh $SILAYER 'python3 -c "import setuptools"' 2>/dev/null; then
echo "==== Installing setuptools ===="
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

echo
echo "==== Installing supervisor ===="
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

echo
echo "==== Setting up environment ===="

## Install init script
INIT_DIR=/etc/init.d/
INIT_SCRIPT=resources/${INIT_DIR}/supervisor
if [ ! -f $INIT_SCRIPT ]; then
    echo "supervisord init script not found in resources/${INIT_DIR}"
    exit 3
fi
scp $INIT_SCRIPT ${SILAYER}:${INIT_DIR}

## Install init defaults
ETC_DEFAULT=/etc/default/
INIT_DEFAULT=resources/${ETC_DEFAULT}/supervisor
if [ ! -f $INIT_DEFAULT ]; then
    echo "supervisord init default settings not found in resources/${ETC_DEFAULT}"
    exit 3
fi
scp $INIT_DEFAULT ${SILAYER}:${ETC_DEFAULT}

## Install the config file.
CONFIG_DIR=/etc/supervisor/
CONFIG_FILE=resources/${CONFIG_DIR}/supervisord.conf
if [ ! -f $CONFIG_FILE ]; then
    echo "supervisord config file not found in resources/${CONFIG_DIR}"
    exit 3
fi
ssh ${SILAYER} "if [ ! -d ${CONFIG_DIR} ]; then mkdir -p ${CONFIG_DIR}; fi"
scp $CONFIG_FILE ${SILAYER}:${CONFIG_DIR}

## Make symbolic links for different runlevels
for runlevel in 2 3 4 5; do
    ssh ${SILAYER} "ln -s /etc/init.d/supervisor /etc/rc${runlevel}.d/S01supervisor"
done

for runlevel in 0 1 6; do
    ssh ${SILAYER} "ln -s /etc/init.d/supervisor /etc/rc${runlevel}.d/K01supervisor"
done

## Create log directory for supervised process stdout and stderr
ssh ${SILAYER} "if [ ! -d /home/root/zynq/log/supervisord/ ]; then mkdir -p /home/root/zynq/log/supervisord/; fi"


echo
echo "==== Supervisord install complete ===="
## vim: set ts=4 sw=4 sts=4 et:
