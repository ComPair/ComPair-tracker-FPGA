#
# This is the vatactrl application recipe
# You will have to edit the `COMPAIR_TRACKER_FPGA_ROOT` to reflect where that git repository
# was cloned.
#

SUMMARY = "vatactrl autoconf application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://vatactrl \
        "
S = "${WORKDIR}/vatactrl"
COMPAIR_TRACKER_FPGA_ROOT = "/home/lucas/fpga/ComPair-tracker-FPGA"

CFLAGS_prepend = "-I ${S}/include -I${COMPAIR_TRACKER_FPGA_ROOT}/work/zynq/zynq.sdk/standalone_bsp_0/ps7_cortexa9_0/include"
inherit autotools
