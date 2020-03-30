#!/usr/bin/env bash

## This script should be run on the "client" computer.
## If ntp is already running on the zynq, then nothing is done.
## Otherwise, it will first set the zynq system time to the client's
## time, then start ntp.

ZYNQ_HOST='silayer'

if ssh root@${ZYNQ_HOST} '/etc/init.d/ntp status >/dev/null'; then
    ## NTP is already running.
    ## Exit.
    echo "NTP already running on the zynq."
    exit 0 
fi

echo -n "Starting NTP on the zynq..."
curtime=$(date -u)
if ssh root@${ZYNQ_HOST} "date --set=\"${curtime}\" >/dev/null && /etc/init.d/ntp start"; then
    echo " done."
    exit 0
else
    echo " error!"
    exit 1
fi

