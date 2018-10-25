from .mcabstractbase cimport MCAB, MCAttr
from .. import DEFAULTS
import numpy as np

cdef dict _inputs = {"rho": MCAttr(float, "density"), "data": MCAttr(dict, "none"), "deg": MCAttr(int, "none"), "T": MCAttr(float, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none")}
cdef dict _properties = {"k()": MCAttr(float, "conductivity") }
cdef list propertiesList = ['k']

cdef class SolidMaterial(MCAB):
    """Essential properties for solid component materials.

Attributes
----------
rho : float
    Mass density [Kg/m^3]
k : float
    Thermal conductivity [W/m.K]
name : string, optional
    Material name. Defaults to "SolidMaterial instance".
notes : string, optional
    Additional notes on the material. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
"""

    def __init__(self,
                 double rho,
                 dict data,
                 int deg=-1,
                 double T=298.15,
                 str name="SolidMaterial instance",
                 str notes="No material notes."):
        self.rho = rho
        self.data = {'T': data['T'], 'k': []} 
        self.deg = deg
        self._c = {}    
        cdef str prop
        cdef size_t lenDataT = len(data['T'])
        if data.keys() == self.data.keys():
            if not all(len(data[prop]) == lenDataT for prop in propertiesList):
                raise ValueError(
                    "Not all data lists have same length as data['T']: len={}".format(lenDataT))
            else:
                self.data = data
                self.populate_c()
        else:
            raise KeyError("Must provide data for k.")
        self.T = T
        self.name = name
        self.notes = notes
        #self.config = config
        self._inputs = _inputs
        self._properties = _properties

    cpdef public void populate_c(self):
        self._c = {}
        cdef str key
        if self.deg < 0:
            pass
        else:
            for key in propertiesList:
                self._c[key] = list(
                    np.polyfit(self.data['T'], self.data[key], self.deg))

    
    cpdef public void update(self, dict kwargs):
        """Update (multiple) class variables from a dictionary of keyword arguments.

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value; kwargs={'key': value}."""
        super(SolidMaterial, self).update(kwargs)
        self.populate_c()
        
    cpdef public double k(self):
        """float: Thermal conductivity [W/m.K]."""
        if self.deg == -1:
            return np.interp(self.T, self.data['T'], self.data['k'])
        else:
            return np.polyval(self._c['k'], self.T)

    def summary(self,
                bint printSummary=True,
                propertyKeys='all',
                str name="",
                int rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Names of component properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to "all".
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        cdef str output, prop
        cdef tuple i
        cdef int j
        if name == "":
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
