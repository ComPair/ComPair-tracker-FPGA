#!/bin/bash
## Set the time on the zynq.
## This will roughly set it. Good enough to run make commands.

if [ -z "$1" ]; then
    echo "Usage: $0 ZYNQIP"
    exit 1
fi

IP_ADDR=$1
SILAYER=root@${IP_ADDR}

d=$(date +"%Y-%m-%d")
ssh ${SILAYER} "date --set ${d}" >/dev/null
t=$(date +"%H:%M:%S" --utc)
ssh ${SILAYER} "date --set ${t}" >/dev/null

## vim: set ts=4 sw=4 sts=4 et:
