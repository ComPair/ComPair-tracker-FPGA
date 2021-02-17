#!/bin/bash

if [ $# -ne 1 ] 
then 
  echo "Usage: $0 <highest_asic_number>"
  exit 1
fi

for i in $(eval echo {0..$1})
do
  vatactrl $i --set-config ~/zynq/config/calCh8_ramp10_pos_vthr15.vcfg
  vatactrl $i --get-config ~/zynq/config/readback.vcfg
  diff ~/zynq/config/calCh8_ramp10_pos_vthr15.vcfg ~/zynq/config/readback.vcfg
done


for i in $(eval echo {0..$1})
do
  vatactrl $i --force-trigger
  
done

for i in $(eval echo {0..$1})
do
  vatactrl $i --read-fifo
done

  
echo "Done!"