from .mcabstractbase cimport MCAB, MCAttr
from .. import DEFAULTS

cdef dict _inputs = {"validClasses": MCAttr(tuple, "none")}
cdef dict _properties = {}
        
cdef class Geom(MCAB):
    """Abstract class for geometries."""

    def __init__(self, tuple validClasses, str name="Geom instance"):
        self.validClasses = validClasses
        self.name = name
        self._inputs =_inputs
        self._properties = _properties
        
    cpdef bint validClass(self, str cls):
        """bool: Returns True if geometry is valid for the given class."""
        if cls in self.validClasses:
            return True
        else:
            return False

    def summary(self,
                printSummary=True,
                propertyKeys='all',
                str name="",
                int rstHeading=0):
        """Returns (and prints) a summary of the geometry attributes/properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Names of component properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to 'all'.
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        cdef str output, prop
        cdef tuple i
        cdef int j
        if name is None:
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
""".format(DEFAULTS.RST_HEADINGS[rstHeading] * len(output))

        hasSummaryList = []
        for k, v in self._inputs.items():
            if k in [
                    "flowsIn", "flowsOut", "flowIn", "flowOut", "flowInWf",
                    "flowOutWf", "flowInSf", "flowOutSf"
            ]:
                pass
            elif k in ["sizeAttr", "sizeBounds", "sizeUnitsBounds"]:
                pass
            elif k in ["name", "notes", "config"]:
                pass
            else:
                output += self.formatAttrForSummary({k: v}, hasSummaryList)
        #
        for i in hasSummaryList:
            output += i.summary(printSummary=False, rstHeading=rstHeading + 1)
        #
        if propertyKeys == 'all':
            propertyKeys = self._propertyKeys()
        if propertyKeys == 'none':
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """#
"""
            for k in propertyKeys:
                if k in self._propertyKeys():
                    output += self.formatAttrForSummary({k: 
                        self._properties[k]}, [])
                else:
                    output += k + """: property not found,
"""
        if printSummary:
            print(output)
        return output

