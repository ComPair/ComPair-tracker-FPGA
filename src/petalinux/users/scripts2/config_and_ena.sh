#!/bin/bash

if [ $# -ne 1 ]
then
  echo "Usage: $0 <highest_asic_number>"
  exit 1
fi

for i in $(eval echo {0..$1})
do
  vatactrl $i --set-config ~/zynq/config/pos_default.vcfg
  vatactrl $i --get-config ~/zynq/config/readback.vcfg
  diff ~/zynq/config/pos_default.vcfg ~/zynq/config/readback.vcfg
done


echo "Done!"