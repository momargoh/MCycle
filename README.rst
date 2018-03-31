=================
MCycle README
=================

.. contents::

About
=========

:Version:
   0.1
:Author:
   Momar Hughes
:Contact:
   momar.hughes@unsw.edu.au
:Topic:
   Thermodynamic power cycle sizing and analysis
:Licence:
   Apache License 2.0
:Requires:
   numpy, scipy, matplotlib, CoolProp
	

MCycle is a Python3 module for 1-dimensional analysis and sizing of thermodynamic heat cycles, particularly the organic Rankine cycle. Sizing methods are based on empirical and theoretical correlations. Users may analyse cycles consisting of components including heaters, coolers, compressors, expanders and heat exchangers. The two main modes for analysing cycles or components are:
  
* *size* : calculates a component characteristic/dimension required to satisfy a desired component outlet flow state/cycle flow states. This mode is used for sizing components.

* *run* : calculates working fluid cycle flow states/ component outlet flow state based on user-defined characteristics/dimensions of the components.

The Github project page can be found at `https://github.com/momargoh/MCycle <https://github.com/momargoh/MCycle>`_. The documentation is hosted at `https://mcycle.readthedocs.io <https://mcycle.readthedocs.io>`_ or can be built using Sphinx (using Python3).


Installation
============

Requirements::
  
  sudo apt install build-essential python3 python3-dev python3-pip python3-tk cython3 git
  pip3 install numpy
  pip3 install scipy
  pip3 install matplotlib

MCycle also requires `CoolProp  <http://www.coolprop.org>`_, a free and open-source thermodynamic properties library. It is recommended to manually install the latest version of CoolProp before installing MCycle (rather than installing from pip which is not the latest version). Refer to their `guide on manual installation <http://www.coolprop.org/coolprop/wrappers/Python/index.html#manual-installation>`_, summarised below.::
  
  cd PATH/TO/CLONE/FOLDER
  git clone https://github.com/CoolProp/CoolProp.git --recursive  
  cd wrappers/Python
  sudo python3 setup.py install

MCycle should now be ready to be installed. For the latest updates, clone/download the source code from the `Github page <https://github.com/momargoh/MCycle>`_ and run::

  python3 setup.py install
  
For the latest stable release, MCycle is available from pip by running:: 

  pip3 install mcycle
  
Contributions towards the project source code will be gratefully received. Feel free to contact the author via email or GitHub with any queries.

Quick start
===========

Have a look through ``mcycle/examples`` to get a feel for how to use the module (`link to documentaion <https://mcycle.readthedocs.io/examples/contents.html>`_). These examples can be easily copied to your local directory and modified to get you started.


Notes on installing CoolProp from source for Python3
=====================================================

Once, the installation failed because /usr/local/lib/python3.6/dist-packages did not exist, thus I ran::
  
  sudo mkdir -p /usr/local/lib/python3.6/dist-packages

Another time, I had to rename the original cloned CoolProp folder to stop Python3 finding it when importing::
  
  sudo mv PATH/TO/CLONE/FOLDER/CoolProp PATH/TO/CLONE/FOLDER/_CoolProp-master

