#!/bin/bash

if [ $# -ne 2 ] 
then 
  echo "Usage: $0 <max asic number> <selected asic>"
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
	vatactrl $i --trigger-disable 2
done

vatactrl $2 --trigger-enable 2

for i in $(eval echo {0..$1})
do
  vatactrl $i --force-trigger
  
done

for i in $(eval echo {0..$1})
do

	echo "Channel " $i
	
	vatactrl $i --read-fifo
done

  
echo "Done!"
