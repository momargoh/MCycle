MCycle Constants
================================

Many of the constants here are repetitions of CoolProp constants originally defined in structs. Cython currently doesn't offer a way to define a struct that can be accessed at both the Cython level and Python level (ie, there is no ``cpdef struct`` yet), hence these constants are just repeated as is.

MCycle constants must be defined and declared in the file ``mcycle._constants.pyx``. The setup script will automatically generate ``mcycle.constants.py``.

.. note:: For developers: the ``.py`` version should only be used in pure Python modules/scripts, otherwise always ``cimport`` the required constants from the ``.pyx`` file.


Tolerances
***********
``TOLABS_X`` : double. 1e-10. Tolerance of quality for determining whether FlowState instance is in the two-phase liquid-vapour region.

CoolProp input_pairs
*********************
unsigned char : Copy of CoolProp ``input_pairs`` struct values. See `CoolProp documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_.

CoolProp imposed phases
************************
unsigned char : Copy of CoolProp ``phases`` struct values. See `CoolProp documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_.

MCycle PHASE
************************
unsigned char : Mostly a copy of CoolProp ``phases`` with a two additional phases for the saturated liquid and vapour points.

=====  ========================================================== 
Value  phase    
=====  ========================================================== 
0      PHASE_LIQUID 
1      PHASE_SUPERCRITICAL
2      PHASE_SUPERCRITICAL_GAS  
3      PHASE_SUPERCRITICAL_LIQUID
4      PHASE_CRITICAL_POINT
5      PHASE_VAPOUR, PHASE_VAPOR, PHASE_GAS
6      PHASE_TWOPHASE
7      PHASE_UNKNOWN
8      PHASE_NOT_IMPOSED
9      PHASE_SATURATED_LIQUID
10     PHASE_SATURATED_VAPOUR, PHASE_SATURATED_VAPOR
=====  ==========================================================  

MCycle UNITPHASE
************************
unsigned char : Combinations of pairs of phases (inlet phase & outlet phase), used when components are unitised. Used to look up heat transfer methods in :meth:`METHODS <mcycle.defaults.METHODS>`.

=====  ========================================================== 
Value  unit phase    
=====  ========================================================== 
0      UNITPHASE_NONE 
1      UNITPHASE_ALL
2      UNITPHASE_LIQUID  
3      UNITPHASE_VAPOUR, UNITPHASE_VAPOR, UNITPHASE_GAS
4      UNITPHASE_TWOPHASE_EVAPORATING, UNITPHASE_TP_EVAP
5      UNITPHASE_TWOPHASE_CONDENSING, UNITPHASE_TP_COND
6      UNITPHASE_SUPERCRITICAL
7      UNITPHASE_ALL_SINGLEPHASE
8      UNITPHASE_ALL_TWOPHASE, UNITPHASE_ALL_TP
=====  ==========================================================

MCycle TRANSFER
************************
unsigned char : Different energy transfer mechanisms.

=====  ========================================================== 
Value  transfer mechanisms   
=====  ========================================================== 
0      TRANSFER_NONE 
1      TRANSFER_ALL
2      TRANSFER_HEAT  
3      TRANSFER_FRICTION
=====  ==========================================================  

MCycle FLOW
************************
unsigned char : Component flows.

=====  ========================================================== 
Value  flow 
=====  ========================================================== 
0      FLOW_NONE 
1      FLOW_ALL
2      FLOW_PRIMARY, FLOW1, WORKING_FLUID  
3      FLOW_SECONDARY, FLOW2, SECONDARY_FLUID
=====  ==========================================================    

MCycle FLOWSENSE
************************
unsigned char : Heat exchanger flow sense.

=====  ========================================================== 
Value  flow sense
=====  ========================================================== 
0      FLOWSENSE_UNDEFINED 
1      COUNTERFLOW
2      PARALLELFLOW
3      CROSSFLOW
=====  ==========================================================


MCycle Info
************
``SOURCE_URL`` : str. ``'https://github.com/momargoh/MCycle'``. Url of source code repo.

``DOCS_URL`` : str. ``'https://mcycle.momarhughes.com'``. Url of hosted documentation.
