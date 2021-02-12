# ComPair-tracker-FPGA

This repository will hold the ComPair silicon tracker FPGA design (VHDL, C-code for microprocessor). 

git-lfs used for all binaries (bitstreams, images, etc.) 

When building, you first need to do a 

`export BUILD=<build_type>`

where `<build_type>` is the type of build you are doing. Current options are:

- breakout : Trenz breakout board option
- dbe_production : DBE Rev- production 
- dbe_reva_production : DBE RevA production 
