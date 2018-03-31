"""setup file for mcycle"""
from setuptools import setup, find_packages
from os import path

here = path.abspath(path.dirname(__file__))
with open(path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='mcycle',
    version='0.1.3',
    description='Power cycle sizing and analysis package',
    long_description=long_description,
    url='https://github.com/momargoh/MCycle',
    author='Momar Hughes',
    author_email='momar.hughes@unsw.edu.au',
    license='Apache License 2.0',
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
    keywords='thermodynamics organic Rankine cycle power cycle evaporator expander condenser compressor heat exchanger heater cooler',
    packages=find_packages(),
    install_requires=['numpy', 'scipy', 'matplotlib', 'CoolProp'],
    dependency_links=['https://github.com/CoolProp/CoolProp.git'],
    extras_require={},
    python_requires='>=3',
    package_data={},
    include_package_data=True,
    data_files=[],
    entry_points={}, )
