from distutils.core import setup, Extension

with open('requirements.txt') as f:
    requirements = f.read().splitlines()

raw2hdf_ext = Extension(
    "silayer._raw2hdf", sources=["src/raw2hdf.c"], depends=["src/raw2hdf.h"],
    extra_compile_args=["-std=c99"]
)

setup(
    name="silayer",
    version="0.0",
    packages=["silayer",],
    package_dir={"silayer": "python"},
    ext_modules=[raw2hdf_ext,],
	install_requires=requirements,    
)
