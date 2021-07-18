r"""
:Abstract: *mcycle* is a power cycle analysis/sizing package. All units are SI. The project homepage can be found at `<https://github.com/momargoh/mcycle>`_, the documentation can be found at `<https://mcycle.readthedocs.io>`_.
:Author: Momar Hughes
:Contact: momarhughes@hotmail.com
:License: Apache License 2.0
:Requirements: Cython, numpy, scipy, matplotlib, CoolProp
"""
from . import __meta__
from .__meta__ import version as __version__
from .logger import *
updateLogger()
#from . import constants
from .constants import *
from . import defaults
defaults.check()
from .defaults import *
from . import bases
from .bases import *
defaults.CONFIG = Config()
from .components import *
from .cycles import *
from .geometries import *
from . import library
from .library import *
from . import methods
from .methods import *
from . import utils
from .utils import *
#
import timeit


def timer(func):
    "Basic decorator to time runs."

    def func_wrapper(*args, **kwargs):
        start = timeit.default_timer()
        ret = func(*args, **kwargs)
        runTime = timeit.default_timer() - start
        msg = ''
        if runTime < 60.:
            msg = "{}() took {} seconds to run.".format(func.__name__, runTime)
        elif runTime < 3600.:
            m, s = divmod(runTime, 60)
            msg = "{}() took {} mins {} s to run.".format(func.__name__, m, s)
        else:
            m, s = divmod(runTime, 60)
            h, m = divmod(m, 60)
            msg = "{}() took {} hrs {} mins {} s to run.".format(
                func.__name__, h, m, s)
        log("info", msg)
        print(msg)
        return ret

    return func_wrapper
