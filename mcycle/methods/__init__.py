from . import heat_transfer
from .heat_transfer import *


def add_method(method, submodule):
    """Add a custom method to a mcycle.methods submodule.

Parameters
-----------
method
    Function returning dictionary.
submodule : str
    Name of mcycle.methods submodule to add the method to. Eg, 'heat_transfer'.
    """
    import types
    from warnings import warn
    from ..logger import log
    from .. import methods

    if not isinstance(method, types.FunctionType):
        raise TypeError(
            "Cannot add method: is not a Python function (given: type={})".
            format(type(method)))
    if type(submodule) is not str:
        raise TypeError(
            "submodule parameter must be string (given: {})".format(
                type(submodule)))
    if submodule not in ["heat_transfer"]:
        raise ValueError(
            "Submodule not valid (given: {}). Must be 'heat_transfer'.")
    try:
        sub_module = getattr(methods, submodule)
        setattr(sub_module, method.__name__, method)
    except Exception as exc:
        msg = "Could not add method={} to mcycle.methods.{}".format(
            method, submodule)
        log("warning", msg, exc_info=exc)
        msg += " Excption: {}".format(exc)
        warn(msg)
