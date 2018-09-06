.. _doc-changelog:
CHANGELOG
==========

.. contents::
   :depth: 2
               
[Unreleased]
-------------

- The latest version of MCycle will be uploaded to PyPI once the cross-platform build requirements are sorted (looking into using skbuild).
- It is planned to be able to choose alternative thermodynamic properties backends (such as `thermo <https://pypi.org/project/thermo/>`_)
  

[1.0.1] - 04/09/2018
------------------------

Added
*******

- components.general for non-specific/non-realistic components. Currently just contains FixedOut

Changed
********

- logger now saves as name of script, with '.log' appended
- ``flowSense`` attribute of heat exchangers changed from ``"counterflow"`` to ``"counter"``
- attribute ``Q`` of ``ClrBasic`` and ``HtrBasic`` components changed to ``QCool`` and ``QHeat`` respectively so as not to compete with ``Q()`` method of heat exchangers.

Deprecated
***********

Removed
*********

- mcycle.logger.LOG_FILE (see changed feature above)

Fixed
******

- Fixed run() method of RankineBasic



[1.0.0] - 31/07/2018
------------------------ 

MCycle is now partially written using Cython in an effort to speed up the code. Thus, Cython is now a required package for installation. 
Release not currently available from pip: must install from source.

Added
*******

- logging functionality included (``mcycle.logger``)
- runBounds attribute of Component added

Changed
********

- moved heat transfer methods from /library to /methods
- rename of cycle/component attributes from *Bracket to *Bounds

Deprecated
***********

Removed
*********

- ``Methods`` class removed, incorporated into new ``Config`` class
  
Fixed
******
    
- debugging/updates to component models

[0.0.1] - 07/05/2018
------------------------

Initial MCycle release, written purely in Python.