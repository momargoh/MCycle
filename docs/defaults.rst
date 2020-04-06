MCycle Defaults
================================

Attributes
-----------
.. attribute:: mcycle.defaults.TOLATTR

  str : FlowState attribute for checking convergence of component and cycle functions. Defaults to 'h'.
.. attribute:: mcycle.defaults.TOLABS

  double : General absolute tolerance used for convergence of component and cycle functions. Defaults to 1e-7.
.. attribute:: mcycle.defaults.TOLREL

  double : General relative tolerance used for convergence of component and cycle functions. Defaults to 1e-7.
.. attribute:: mcycle.defaults.DIV_T

  double : Increment of temperature for unitisation processes [K]; lower value = higher accuracy. Defaults to 5 K.
.. attribute:: mcycle.defaults.DIV_X

  double : Increment of quality for unitisation processes [-]; lower value = higher accuracy. Defaults to 0.1.
.. attribute:: mcycle.defaults.MAXITER_CYCLE

  int : Maximum iterations for convergence of **run** and **size** methods of Cycle objects. Defaults to 50.
.. attribute:: mcycle.defaults.MAXITER_COMPONENT

  int : Maximum iterations for convergence of **run** and **size** methods of Component objects. Defaults to 50.
.. attribute:: mcycle.defaults.MAX_WALLS

  int : Maximum number of walls for a Component (eg; heat exchangers). Defaults to 200.
.. attribute:: mcycle.defaults.TRY_BUILD_PHASE_ENVELOPE

  bool : Get CoolProp to try to build the phase envelope for FlowState mixtures during construction. If CoolProp fails to do so the ``_canBuildPhaseEnvelope`` attribute is set to ``False`` which overrides ``TRY_BUILD_PHASE_ENVELOPE`` to prevent wasting computation time on repeated failures. Defaults to True.
.. attribute:: mcycle.defaults.GRAVITY

  double : Vertical cceleration due to gravity. Defaults to 9.80665 m/s^2.
.. attribute:: mcycle.defaults.COOLPROP_EOS

  str : CoolProp Equation of State backend. Must be 'HEOS' or 'REFPROP', depending on whether RefProp backend has been configured (see `using RefProp <http://www.coolprop.org/coolprop/REFPROP.html>`_, `primary backends <http://www.coolprop.org/develop/backends.html#derived-backends>`_). Defaults to 'HEOS'.
.. attribute:: mcycle.defaults.MPL_BACKEND

  str : Matplotlib backend (see `documentation <https://matplotlib.org/tutorials/introductory/usage.html#backends>`_). Defaults to 'TkAgg'.
.. attribute:: mcycle.defaults.PLOT_DIR

  str : Directory to save plots in. Will be created if it doesn't already exist. Defaults to 'plots'.
.. attribute:: mcycle.defaults.PLOT_DPI

  int : DPI of plots (see `explanation <http://www.focus97.com/blog/photography/dpi-dots-per-inch-explained-how-much-do-i-need-and-what-is-it-anyway/>`_). Defaults to 600.
.. attribute:: mcycle.defaults.PLOT_FORMAT

  str : File format for plots. Must be 'png' or 'jpg'. Defaults to 'png'.
.. attribute:: mcycle.defaults.PLOT_COLOR

  list of str : List of plot colours for distinguishing plotlines. Can be set to a list of the same colour if not required. See `link to tutorial <https://matplotlib.org/3.1.0/tutorials/colors/colors.html>`_ for more info. Defaults to ``['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9']``.
.. attribute:: mcycle.defaults.PLOT_LINESTYLE

  list : List of linestyles for distinguishing plotlines. See `link to documentation <https://matplotlib.org/3.1.0/gallery/lines_bars_and_markers/linestyles.html>`_ for more info on defining linestyles.
.. attribute:: mcycle.defaults.PLOT_MARKER

  list of str : List of markers for distinguishing plotlines. Set to [''] if you do not require markers. See `link to documentation <https://matplotlib.org/3.1.0/api/markers_api.html>`_ for more info.
.. attribute:: mcycle.defaults.UNITS_SEPARATOR_NUMERATOR

  str : Separator style for the numerator of units; ie: 'W.h' compared to 'W-h', or 'W h'. Defaults to ``'.'``.
.. attribute:: mcycle.defaults.UNITS_SEPARATOR_DENOMINATOR

  str : Separator style for the denominator of units; ie: 'J/kg.K' compared to 'J/kg-K', or 'J/kg/K'.Defaults to '.'.
.. attribute:: mcycle.defaults.UNITS_FORMAT

  str : Style of spacing between value and units. Must be '', 'parentheses', 'brackets', 'braces' or 'comma', with or without suffix '-nospace'. Eg, 'comma' would produce ``1.0, m^3/kg``, 'comma-nospace' would produce ``1.0,m^3/kg``, 'braces' would produce ``1.0 {m^3/kg}``. Defaults to 'comma'.
.. attribute:: mcycle.defaults.PRINT_FORMAT_FLOAT

  str : Format for printing floats, used with Python strings' format() method (see `documentation <https://docs.python.org/3.6/library/string.html#formatspec>`_). Defaults to ``'{: .4e}'``.
.. attribute:: mcycle.defaults.RST_HEADINGS

  list : Characters used for successive levels of reStructuredText headings. Defaults to ['=', '-', '^', '"'].
.. attribute:: mcycle.defaults.CONFIG

  Config : Default ``Config`` instance used in classes with a ``config`` attribute. When constructing, set ``config=None`` to use this default instance. This promotes sharing of a single ``Config`` instance throughout a script, as opposed to each individual component/class having its own. Defaults to ``None`` which is then set to ``Config()`` by :meth:`check() <mcycle.defaults.check>` during importation of MCycle.
.. attribute:: mcycle.defaults.METHODS

  dict : Dictionary of methods set to :meth:`Config.methods <mcycle.bases.config.Config.methods>` attribute.
.. attribute:: mcycle.defaults.DIMENSIONS

  dict : Dictionary of attribute dimensions looked up by ``summary`` methods. Each dictionary value is another dictionary containing a default value under the ``''`` key, and class-specific values where necessary. Eg, for attribute ``'h'``, the value is the dictionary::
    
   'h': {
        '': 'power/area-temperature',
        'GeomHxPlateFinStraight': 'length',
        'GeomHxPlateFinOffset': 'length',
        'FlowState': 'energy/mass',
        'FlowStatePoly': 'energy/mass'
    },

So if the class of the object that has called ``summary`` is ``FlowState`` the dimension returned is ``'energy/mass'`` (enthalpy), if the object is not listed in the above dictionary the dimension returned is ``'power/area-temperature'`` (heat transfer coefficient for heat exchangers).
  
Methods
--------
.. automodule:: mcycle.defaults
   :members:
   :undoc-members:
   :inherited-members:
   :show-inheritance:

               
