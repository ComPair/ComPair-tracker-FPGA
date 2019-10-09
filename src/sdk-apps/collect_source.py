#!/usr/bin/env python3
import os
import glob
##import shutil

IGNORE_APPS = [
    "webtalk", "zynq_bd_wrapper_hw_platform_0", "RemoteSystemsTempFiles", "standalone_bsp_0"
]

def main():
    apps = [ os.path.basename(d.rstrip('/')) for d in glob.iglob("../../work/zynq/zynq.sdk/*/") ]
    apps = [ app for app in apps if app not in IGNORE_APPS ]
    for app in apps:
        if os.path.isdir(app):
            os.system("rm -r %s" % app)
        os.makedirs(app)
        src = "../../work/zynq/zynq.sdk/%s/src/*.c" % app
        os.system("cp %s %s" % (src, app,))

if __name__ == '__main__':
    main()

## vim: set ts=4 sw=4 sts=4 et:
