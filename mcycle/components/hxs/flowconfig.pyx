from ...logger import log
from ...bases.abc cimport ABC
from ..._constants cimport *
from ... import defaults


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

    def summary(self,
                printSummary=True,
                propertyKeys='all',
                str title="",
                int rstHeading=0):
        """Returns (and prints) a summary of the geometry attributes/properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list or str, optional
    Names of component properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to 'all'.
title : str, optional
    Title used in summary heading. If '', the :meth:`name <mcycle.abc.ABC.name>` property of the instance is used. Defaults to ''.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from :meth:`RST_HEADINGS <mcycle.defaults.RST_HEADINGS>`. Defaults to 0.
        """
        cdef str output, prop
        cdef tuple i
        cdef int j
        if title == '':
            title = self.name
        output = r"{} summary".format(title)
        output += """
{}
""".format(defaults.RST_HEADINGS[rstHeading] * len(output))

        hasSummaryList = []
        for k in self._inputs:
            if k in ["name", "notes", "config"]:
                pass
            else:
                output += self.formatAttrForSummary(k, hasSummaryList)
        #
        for i in hasSummaryList:
            output += i.summary(printSummary=False, rstHeading=rstHeading + 1)
        #
        if propertyKeys == 'all':
            propertyKeys = self._properties
        if propertyKeys == 'none':
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """#
"""
            for k in propertyKeys:
                if k in self._properties:
                    output += self.formatAttrForSummary(k, [])
                else:
                    output += k + """: property not found,
"""
        if printSummary:
            print(output)
        return output
