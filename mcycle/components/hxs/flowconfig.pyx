from ...logger import log
from ...bases.abc cimport ABC
from ..._constants cimport *


cdef tuple _inputs = ('sense', 'passes', 'arrangement', 'verticalWf', 'verticalSf', 'name')
cdef tuple _properties = ()

cdef class HxFlowConfig(ABC):
    """Small class to store information about the heat exchanger flow configuration/arrangement which can become much more complex than just specifying counter-flow v parallel-flow v cross-flow.

Parameters
----------
sense : unsigned char
    General sense of the flows: COUNTERFLOW, PARALLELFLOW or CROSSFLOW. Defaults to COUNTERFLOW.
passes : unsigned int
    Number of flow passes. Currently only a single-pass arrangement is supported. Defaults to 1.
arrangement : str
    Flow arrangement, currently an unused variable. Defaults to ''.
verticalWf : bint
    Working fluid flow is vertical. Defaults to True.
verticalSf : bint
    Secondary fluid flow is vertical. Defaults to True.
    """

    def __init__(self,
                  unsigned char sense=COUNTERFLOW,
                  unsigned int passes=1,
                  str arrangement='',
                  bint verticalWf=True,
                  bint verticalSf=True,
                  str name="HxFlowConfig instance"):
        super().__init__(_inputs=_inputs, _properties=_properties, name=name)
        # TODO implement more error checking
        self.sense = sense
        self.passes = passes
        self.arrangement = arrangement
        self.verticalWf = verticalWf
        self.verticalSf = verticalSf
