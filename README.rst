=================
MCycle README
=================
   
.. contents::

About
=========

:Version:
   1.0.0
:Author:
   Momar Hughes
:Contact:
   momar.hughes@unsw.edu.au
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
   :target: https://mcycle.readthedocs.io/?badge=latest
   :alt: Docs Build Status
	

MCycle is a Python3 module for 1-dimensional analysis and sizing of thermodynamic heat cycles. Sizing methods are based on empirical and theoretical correlations. Users may analyse cycles consisting of components including heaters, coolers, compressors, expanders and heat exchangers. The two main modes for analysing cycles or components are:
  
* ``size`` : calculates a component characteristic/dimension required to satisfy a desired component outlet flow state/cycle flow states. This mode is used for sizing components.

* ``run`` : calculates working fluid cycle flow states/ component outlet flow state based on user-defined characteristics/dimensions of the components.

The Github project page can be found at `https://github.com/momargoh/MCycle <https://github.com/momargoh/MCycle>`_. The documentation is hosted at `https://mcycle.readthedocs.io <https://mcycle.readthedocs.io>`_.

Contributions towards the project source code will be gratefully received. Feel free to contact the author via email with any queries. If using this package for your own research, please cite the following the publication.

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

MCycle also requires `CoolProp <http://www.coolprop.org>`_, a free and open-source thermodynamic properties library. The latest stable version can be installed from pip::

  pip3 install CoolProp

Alternatively, the latest development version can be installed from the `Github source code <https://github.com/CoolProp/CoolProp>`_ (refer to their `guide on manual installation <http://www.coolprop.org/coolprop/wrappers/Python/index.html#manual-installation>`_, summarised below).::
  
  cd PATH/TO/CLONE/FOLDER
  git clone https://github.com/CoolProp/CoolProp.git --recursive  
  cd wrappers/Python
  sudo python3 setup.py install

MCycle should now be ready to be installed. For the latest updates, clone/download the source code from the `Github page <https://github.com/momargoh/MCycle>`_ and run from the package directory::

  python3 setup.py install
  
.. note:: A deprecated version of MCycle is available from pip. This will soon be replaced by the most recent version (requiring Cython).
..   For the latest stable release, MCycle is also available from pip by running:: 

..  pip3 install mcycle

.. readme-link-marker
   
.. _section-README-quickstart:

Quick start
===========

Have a look through the `quick start example <https://mcycle.readthedocs.io/examples/quickstart.html>`_ that demonstrates some of the basic functionality of MCycle. The `examples folder <https://mcycle.readthedocs.io/examples/contents.html>`_ also contains more advanced examples, any of which can easily be copied to your local directory and modified as required.


