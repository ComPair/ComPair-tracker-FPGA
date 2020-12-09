from setuptools import setup, Extension

import os
from glob import glob


def get_scripts():
    """Return executables found under ./bin, to be installed by the setup function.
    """
    return [f for f in glob("bin/*") if os.access(f, os.X_OK)]


# with open('requirements.txt') as f:
#    requirements = f.read().splitlines()

raw2hdf_ext = Extension(
    "silayer._raw2hdf",
    sources=["src/raw2hdf.c"],
    depends=["src/raw2hdf.h"],
    extra_compile_args=["-std=c99"],
)

setup(
    name="silayer",
    version="0.1",
    packages=["silayer"],
    ext_modules=[raw2hdf_ext],
    install_requires=["numpy", "h5py"],
    scripts=get_scripts(),
    # install_requires=requirements,
)
