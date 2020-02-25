#
# This is the vatactrl application recipe
#

SUMMARY = "vatactrl autoconf application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://vatactrl \
        "
S = "${WORKDIR}/vatactrl"
COMPAIR_TRACKER_FPGA_ROOT = "${TOPDIR}/../../../../"

CFLAGS_prepend = "-I ${S}/include -I${COMPAIR_TRACKER_FPGA_ROOT}/work/dbe_production/zynq/zynq.sdk/bsp_petalinux/ps7_cortexa9_0/include"
CXXFLAGS_prepend = "-I ${S}/include -I${COMPAIR_TRACKER_FPGA_ROOT}/work/dbe_production/zynq/zynq.sdk/bsp_petalinux/ps7_cortexa9_0/include"
inherit autotools
