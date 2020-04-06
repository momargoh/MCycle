.. _doc-changelog:
CHANGELOG
==========

.. contents::
   :depth: 2
               
[1.1.0] - 06/04/2020
------------------------------

- The latest version of MCycle will be uploaded to PyPI once the cross-platform build requirements are sorted (looking into using skbuild).
- It is planned to be able to choose alternative thermodynamic properties backends (such as `thermo <https://pypi.org/project/thermo/>`_)
- Error checking for HxFlowConfig

Added
*******

- ``constants`` module: repeats a bunch of CoolProp constants, eg; input_pairs, phases.
- ``HxPlateFin`` and ``HxPlateCorrugated`` (later is renaming of ``HxPlate``)
- ``GeomHxPlateFinStraight`` and ``GeomHxPlateFinOffset`` added to ``geometries``.
- heat transfer methods added for HxPlateFin geometries

Changed
********

- ``defaults`` module split into ``defaults`` and ``constants``. Defaults for matplotlib configuration added and ``getPlotDir()`` renamed and slight reworked to ``makePlotDir()``.
- ``HxPlate`` renamed to ``HxPlateCorrugated``, new ``HxPlate`` is now a superclass of ``HxPlateFin`` and ``HxPlateCorrugated`` .
- ``geomPlateWf`` and ``geomPlateSf`` attributes of ``HxPlate`` and ``HxUnitPlate`` renamed to ``geomWf`` and ``geomSf``.
- METHODS dictionary changed to a more nested structure
- ``timeThis`` decorator renamed to ``timer``
- efficiency attirbutes/properties renamed to ``efficiency*`` from ``eff*``

Deprecated
***********

Removed
*********


Fixed
******
  
[1.0.2] - 16/01/2019
------------------------

Added
*******

- ``library.conversions`` significantly expanded and reorganised. A couple of functions have has slight name changes.
- ``defaults.TRY_BUILD_PHASE_ENVELOPE``: whether CoolProp should always try to build the phase envelope for mixtures

Changed
********

- ``flowSense`` attribute of heat exchangers expanded to HxFlowConfig class, which now stores more info: sense, passes, vertical or horizontal

Deprecated
***********

Removed
*********

- ``Pr`` data key removed from ``RefData.data`` attribute as it's not an explicit property

Fixed
******

[1.0.1] - 04/09/2018
------------------------

Added
*******

- 

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
