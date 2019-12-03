=================
MCycle README
=================
   
.. warning::
  MCycle is currently undergoing an overhaul and a new version will be published shortly. I'd consider waiting for the new version to avoid having to rework your scripts later!

.. contents::

Meta
=========

:Version:
   1.0.1
:Author:
   Momar Hughes
:Contact:
   momarhughes@outlook.com
:Topic:
   Thermodynamic power-cycle sizing and analysis
:Licence:
   Apache License 2.0
:Requires:
   numpy, scipy, matplotlib, Cython, CoolProp
.. image:: http://joss.theoj.org/papers/10.21105/joss.00710/status.svg
   :target: https://doi.org/10.21105/joss.00710
   :alt: JOSS Publication
.. image:: https://readthedocs.org/projects/mcycle/badge/?version=latest
   :target: https://mcycle.momarhughes.com/?badge=latest
   :alt: Docs Build Status
	
About
=========

MCycle is a Python3 module for 1-dimensional analysis and sizing of thermodynamic heat cycles. Sizing methods are based on empirical and theoretical correlations. Users may analyse cycles consisting of components including heaters, coolers, compressors, expanders and heat exchangers. The two main modes for analysing cycles or components are:
  
* ``size`` : calculates a component characteristic/dimension required to satisfy a desired component outlet flow state/cycle flow states. This mode is used for sizing components.

* ``run`` : calculates working fluid cycle flow states/ component outlet flow state based on user-defined characteristics/dimensions of the components.

Thermodynamic Properties
=========================

All thermodynamic fluid properties are computed using CoolProp. The latest list of available pure and pseudo-pure fluids can be found here: `link <http://www.coolprop.org/fluid_properties/PurePseudoPure.html#list-of-fluids>`_. Mixtures are also supported, though due to their complexity, may only be defined by pressure/quality, temperature/quality or pressure/temperature. See here for more info about mixtures: `link <http://www.coolprop.org/fluid_properties/Mixtures.html>`_. CoolProp can also use `REFPROP <https://www.nist.gov/srd/refprop>`_ as its backend, so you may use any REFPROP fluids if you have a licence (see https://github.com/usnistgov/REFPROP-cmake for instructions on installing REFPROP shared library). Your REFPROP `FORTRAN` and `FLUID` folders will need to be added to PATH (and renamed to lowercase `fortran` and `fluid` on Linux & OSX), or you may use the following function to point CoolProp towards your REFPROP build directory (see here for more info about PATH issues http://www.coolprop.org/coolprop/REFPROP.html#path-issues) ::

  mcycle.setupREFPROP(ALTERNATIVE_REFPROP_PATH='/path/to/REFPROP/directory', ALTERNATIVE_REFPROP_LIBRARY_PATH='', ALTERNATIVE_REFPROP_HMX_BNC_PATH='')

Code Source
=========================

The Github project page can be found at `https://github.com/momargoh/MCycle <https://github.com/momargoh/MCycle>`_. The documentation is hosted at https://mcycle.momarhughes.com.

Contributions towards the project source code will be gratefully received. Feel free to contact the author via email with any queries. If using this package for your own research, please cite the following `publication <https://doi.org/10.21105/joss.00710>`_.

.. code-block:: none

  Hughes, M. (2018). MCycle: A Python package for 1D sizing and analysis of thermodynamic power cycles. Journal of Open Source Software, 3(28), 710, https://doi.org/10.21105/joss.00710

  @article{hughes2018mcycle,
    title={{MCycle}: A Python package for 1D sizing and analysis of thermodynamic power cycles},
    author={Momar Graham-Orr Hughes},
    journal={Journal of Open Source Software (JOSS)},
    volume={3},
    number={28},
    pages={710},
    year={2018},
    month=aug,
    publisher={The Open Journal},
    url={https://doi.org/10.21105/joss.00710},
    doi={10.21105/joss.00710},
  }
            
.. _section-README-installation:

Installation
============

Requirements::
  
  sudo apt install build-essential python3 python3-dev python3-pip python3-tk cython3 git
  pip3 install Cython
  pip3 install numpy
  pip3 install scipy
  pip3 install matplotlib

MCycle also requires `CoolProp <http://www.coolprop.org>`_, a free and open-source thermodynamic properties library. The latest version can be installed from pip::

  pip3 install CoolProp

MCycle should now be ready to be installed. For the latest updates, clone/download the source code from the `Github page <https://github.com/momargoh/MCycle>`_ and run from the package directory::

  python3 setup.py install
  
.. note:: A deprecated version of MCycle is available from pip. This will soon be replaced by the most recent version (requiring Cython).
..   For the latest stable release, MCycle is also available from pip by running:: 

..  pip3 install mcycle
     
.. readme-link-marker
   
.. _section-README-quickstart:


Quick start
===========

Have a look through the `quick start example <https://mcycle.momarhughes.com/examples/quickstart.html>`_ that demonstrates some of the basic functionality of MCycle. The `examples folder <https://mcycle.momarhughes.com/examples/contents.html>`_ also contains more advanced examples, any of which can easily be copied to your local directory and modified as required.

