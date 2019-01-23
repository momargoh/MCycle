MCycle Defaults
================================

Attributes
-----------
.. attribute:: mcycle.DEFAULTS.TOLATTR

  str : FlowState attribute for checking convergence of component and cycle functions. Defaults to 'h'.
.. attribute:: mcycle.DEFAULTS.TOLABS

  double : General absolute tolerance used for convergence of component and cycle functions. Defaults to 1e-7.
.. attribute:: mcycle.DEFAULTS.TOLREL

  double : General relative tolerance used for convergence of component and cycle functions. Defaults to 1e-7.
.. attribute:: mcycle.DEFAULTS.TOLABS_X

  double : Absolute tolerance used for the quality of fluids, particularly determining if a fluid is a saturated liquid or vapour. Defaults to 1e-10.
.. attribute:: mcycle.DEFAULTS.DIV_T

  double : Increment of temperature for unitisation processes [K]; lower value = higher accuracy. Defaults to 5.
.. attribute:: mcycle.DEFAULTS.DIV_X

  double : Increment of quality for unitisation processes [-]; lower value = higher accuracy. Defaults to 0.1.
.. attribute:: mcycle.DEFAULTS.MAXITER_CYCLE

  int : Maximum iterations for convergence of **run** and **size** methods of Cycle objects. Defaults to 50.
.. attribute:: mcycle.DEFAULTS.MAXITER_COMPONENT

  int : Maximum iterations for convergence of **run** and **size** methods of Component objects. Defaults to 50.
.. attribute:: mcycle.DEFAULTS.MAX_WALLS

  int : Maximum number of walls for a Component (eg; heat exchangers). Defaults to 200.
.. attribute:: mcycle.DEFAULTS.TRY_BUILD_PHASE_ENVELOPE

  bool : Get CoolProp to always try to build the phase envelope for mixtures. May slow computations if CoolProp repeatedly fails to do so. Defaults to True.
.. attribute:: mcycle.DEFAULTS.GRAVITY

  double : Vertical cceleration due to gravity. Defaults to 9.80665 [m/s^2].
.. attribute:: mcycle.DEFAULTS.COOLPROP_EOS

  str : CoolProp Equation of State backend. Must be 'HEOS' or 'REFPROP', depending on whether RefProp backend has been configured (see `using RefProp <http://www.coolprop.org/coolprop/REFPROP.html>`_, `primary backends <http://www.coolprop.org/develop/backends.html#derived-backends>`_). Defaults to 'HEOS'.
.. attribute:: mcycle.DEFAULTS.MPL_BACKEND

  str : Matplotlib backend (see `documentation <https://matplotlib.org/tutorials/introductory/usage.html#backends>`_). Defaults to 'TkAgg'.
.. attribute:: mcycle.DEFAULTS.PLOT_DIR

  str : Directory to save plots in. Will be created if it doesn't already exist. Defaults to 'plots'.
.. attribute:: mcycle.DEFAULTS.PLOT_DPI

  int : DPI of plots (see `explanation <http://www.focus97.com/blog/photography/dpi-dots-per-inch-explained-how-much-do-i-need-and-what-is-it-anyway/>`_). Defaults to 600.
.. attribute:: mcycle.DEFAULTS.PLOT_FORMAT

  str : File format for plots. Must be 'png' or 'jpg'. Defaults to 'png'.
.. attribute:: mcycle.DEFAULTS.UNITS_SEPARATOR_NUMERATOR

  str : Separator style for the numerator of units; ie: 'kW.h' compared to 'kW-h', or 'kW h'. Defaults to '.'.
.. attribute:: mcycle.DEFAULTS.UNITS_SEPARATOR_DENOMINATOR

  str : Separator style for the denominator of units; ie: 'J/kg.K' compared to 'J/kg-K', or 'J/kg/K'.Defaults to '.'.
.. attribute:: mcycle.DEFAULTS.PRINT_FORMAT_FLOAT

  str : Format for printing floats, used with Python strings' format() method (see `documentation <https://docs.python.org/3.6/library/string.html#formatspec>`_). Defaults to '{:.4e}'.
.. attribute:: mcycle.DEFAULTS.RST_HEADINGS

  list : Characters used for successive levels of reStructuredText headings. Defaults to ['=', '-', '^', '"'].
.. attribute:: mcycle.DEFAULTS.METHODS

  dict : Dictionary of methods set to Config.method attribute. Defaults to
  {'HxPlateCorrChevronHeatWf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp",
                     "tpEvap": "yanLin_tpEvap",
                     "tpCond": "hanLeeKim_tpCond"
                 },
                 'HxPlateCorrChevronFrictionWf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp",
                     "tpEvap": "yanLin_tpEvap",
                     "tpCond": "hanLeeKim_tpCond"
                 },
                 'HxPlateCorrChevronHeatSf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp"
                 },
                 'HxPlateCorrChevronFrictionSf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp"
                 },
                 'HxPlateFinOffsetHeatWf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp",
                     "tpEvap": "",
                     "tpCond": ""
                 },
                 'HxPlateFinOffsetFrictionWf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp",
                     "tpEvap": "",
                     "tpCond": ""
                 },
                 'HxPlateFinOffsetHeatSf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp"
                 },
                 'HxPlateFinOffsetFrictionSf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp"
                 },
                 'HxPlateSmoothHeatWf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp",
                     "tpEvap": "shah_tpEvap",
                     "tpCond": "shah_tpCond"
                 },
                 'HxPlateSmoothFrictionWf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp",
                     "tpEvap": '',
                     "tpCond": ''
                 },
                 'HxPlateSmoothHeatSf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp"
                 },
                 'HxPlateSmoothFrictionSf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp"
                 }}
  
Methods
--------
.. automodule:: mcycle.DEFAULTS
   :members:
   :undoc-members:
   :inherited-members:
   :show-inheritance:

               
