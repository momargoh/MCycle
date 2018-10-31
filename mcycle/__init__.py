r"""
:Abstract: *mcycle* is a power cycle analysis/sizing package. All units are SI. The project homepage can be found at `<https://github.com/momargoh/mcycle>`_, the documentation can be found at `<https://mcycle.readthedocs.io>`_.
:Author: Momar Hughes
:Contact: momarhughes@outlook.com
:License: Apache License 2.0
:Requirements: Cython, numpy, scipy, matplotlib, CoolProp
"""
from . import __meta__
from .__meta__ import version as __version__
from .logger import *
updateLogger()
from . import DEFAULTS
DEFAULTS.updateDefaults()
from .DEFAULTS import getUnits, timeThis, updateDefaults
from . import bases
from .bases import *
from .components import *
from .cycles import *
from .geometries import *
from . import library
from .library import *
from . import methods
from .methods import *
