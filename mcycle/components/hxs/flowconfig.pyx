from ...logger import log
from ...bases.mcabstractbase cimport MCAB, MCAttr


cdef dict _inputs = {"sense": MCAttr(str, "none"), "passes": MCAttr(str, "none"), "verticalWf": MCAttr(bool, "none"), "verticalSf": MCAttr(bool, "none")}
cdef dict _properties = {}

cdef class HxFlowConfig(MCAB):
    """Small class to store information about the heat exchanger flow configuration/arrangement which can become much more complex than just specifying counter-flow v parallel-flow v cross-flow.

Parameters
----------
sense : str
    General sense of the flows: 'counter', 'parallel' or 'cross'. Defaults to 'counter'.
passes : str
    Number/arrangement of flow passes. Currently only a single-pass arrangement is supported. Defaults to '1'.
verticalWf : bint
    Working fluid flow is vertical. Defaults to True.
verticalSf : bint
    Secondary fluid flow is vertical. Defaults to True.
    """

    def __cinit__(self,
                  str sense="counter",
                  str passes="1",
                  bint verticalWf=True,
                  bint verticalSf=True):
        # TODO implement more error checking
        if sense != "counter" and sense != "parallel":
            msg = "{} is not a valid value for sense; must be 'counter' or 'parallel'.".format(sense)
            log("error", msg)
            raise ValueError(msg)
        self.sense = sense
        self.passes = passes
        self.verticalWf = verticalWf
        self.verticalSf = verticalSf
        self._inputs = _inputs
        self._properties = _properties
        self.name = "HxFlowConfig instance"
