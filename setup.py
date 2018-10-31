#!/usr/bin/env python3
"""Setup file for mcycle"""
USE_CYTHON = 'auto'

import os
from setuptools import setup
from setuptools import find_packages
#from distutils.core import setup
#from distutils.extension import Extension
from setuptools.extension import Extension
import numpy

here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.rst'), encoding='utf-8') as f:
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
    '''raise ImportError(
        "Exiting installation - Could not import Cython. Try running the command: pip3 install Cython"
    )'''

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
compiler_directives = {
    'embedsignature': True,
    "language_level": 3,
    "boundscheck": False,
    "wraparound": False
}


def scanForExtension(directory, extension, files=[]):
    "Find all files with extension in directory and any subdirectories, modified from https://github.com/cython/cython/wiki/PackageHierarchy"
    for f in os.listdir(directory):
        path = os.path.join(directory, f)
        if os.path.isfile(path) and path.endswith(extension):
            files.append(path[:-2])
        elif os.path.isdir(path):
            scanForExtension(path, extension, files)
    return files


if USE_CYTHON:
    pyx_exts = scanForExtension("mcycle", ".pyx")
    for ext in pyx_exts:
        ext_modules += cythonize(
            "mcycle/*.pyx", compiler_directives=compiler_directives)
    cmdclass.update({'build_ext': build_ext})
else:
    c_exts = scanForExtension("mcycle", ".c")
    for ext in c_exts:
        ext_modules += [Extension(ext, ['{}.c'.format(ext)])]
meta = {}
with open('mcycle/__meta__.py') as fp:
    exec (fp.read(), meta)  # get variables from mcycle/__meta__
setup(
    name='mcycle',
    version=meta['version'],
    description=meta['description'],
    long_description=long_description,
    url=meta['url'],
    author=meta['author'],
    author_email=meta['author_email'],
    license=meta['license'],
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
    keywords=meta['keywords'],
    packages=find_packages(),
    install_requires=['numpy', 'scipy', 'matplotlib', 'Cython', 'CoolProp'],
    dependency_links=['https://github.com/CoolProp/CoolProp.git'],
    extras_require={},
    python_requires='>=3',
    include_package_data=True,
    package_data={
        'mcycle': ['*.pxd', '*.pyx'],
        'mcycle/*': ['*.pxd', '*.pyx'],
        'mcycle/*/*': ['*.pxd', '*.pyx'],
        'mcycle/*/*/*': ['*.pxd', '*.pyx']
    },
    data_files=[],
    entry_points={},
    cmdclass=cmdclass,
    include_dirs=include_dirs,
    ext_modules=ext_modules,
    zip_safe=False,
)
