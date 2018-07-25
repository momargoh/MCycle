#!/usr/bin/env python3
"""Setup file for mcycle"""
USE_CYTHON = 'auto'

from setuptools import setup
from setuptools import find_packages
#from skbuild import setup
from os import path
from distutils.core import setup
from distutils.extension import Extension
import numpy

here = path.abspath(path.dirname(__file__))
with open(path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()
try:
    import Cython
    v = Cython.__version__.split(".")
    if int(v[0]) == 0 and int(v[1]) < 27:
        raise ImportError(
            "Exiting installation - Please upgrade Cython to at least v0.28. Try running the command: pip3 install --upgrade Cython"
        )
    else:
        USE_CYTHON = True
except ImportError:
    USE_CYTHON = False
    raise ImportError(
        "Exiting installation - Could not import Cython. Try running the command: pip3 install Cython"
    )  # Cython is required for installation
if USE_CYTHON:
    try:
        from Cython.Distutils import build_ext
        from Cython.Build import cythonize
    except ImportError as exc:
        if USE_CYTHON == 'auto':
            USE_CYTHON = False
        else:
            raise ImportError(
                """Exiting installation - Importing Cython unexpectedly failed due to: {}
Try re-installing Cython by running the commands:
pip3 uninstall Cython
pip3 install Cython""".format(exc))

cmdclass = {}
ext_modules = []
include_dirs = [numpy.get_include()]
compiler_directives = {'embedsignature': True, "language_level": 3}
if USE_CYTHON:
    ext_modules = cythonize(
        "mcycle/*.pyx", compiler_directives=compiler_directives) + cythonize(
            "mcycle/*/*.pyx",
            compiler_directives=compiler_directives) + cythonize(
                "mcycle/*/*/*.pyx", compiler_directives=compiler_directives)
    cmdclass.update({'build_ext': build_ext})
else:
    ext_modules += [
        Extension(
            "mcycle/*", ["mcycle/*.c"],
            compiler_directives=compiler_directives),
        Extension(
            "mcycle/*/*", ["mcycle/*/*.c"],
            compiler_directives=compiler_directives),
        Extension(
            "mcycle/*/*/*", ["mcycle/*/*/*.c"],
            compiler_directives=compiler_directives),
        Extension(
            "mcycle/*/*/*/*", ["mcycle/*/*/*/*.c"],
            compiler_directives=compiler_directives)
    ]

setup(
    name='mcycle',
    version='1.0.0',
    description='Power cycle sizing and analysis package',
    long_description=long_description,
    url='https://github.com/momargoh/MCycle',
    author='Momar Hughes',
    author_email='momar.hughes@unsw.edu.au',
    license='Apache-2.0',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: Apache Software License',
        'Natural Language :: English',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Education',
        'Topic :: Scientific/Engineering',
        'Topic :: Scientific/Engineering :: Chemistry',
        'Topic :: Scientific/Engineering :: Physics',
    ],
    keywords=
    'thermodynamics organic Rankine cycle power cycle evaporator expander condenser compressor heat exchanger heater cooler',
    packages=find_packages(),
    install_requires=['numpy', 'scipy', 'matplotlib', 'Cython', 'CoolProp'],
    dependency_links=['https://github.com/CoolProp/CoolProp.git'],
    extras_require={},
    python_requires='>=3',
    package_data={'mcycle': ['*.pxd', '*.pyx']},
    include_package_data=True,
    data_files=[],
    entry_points={},
    cmdclass=cmdclass,
    include_dirs=include_dirs,
    ext_modules=ext_modules,
)
