from ..DEFAULTS import RSTHEADINGS
from .mcabstractbase import MCAbstractBase as MCAB
from .config import Config


class SolidMaterial(MCAB):
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
                 rho,
                 k,
                 name="SolidMaterial instance",
                 notes="no notes",
                 config=Config(),
                 **kwargs):
        self.rho = rho
        self.k = k
        self.name = name
        self.notes = notes
        self.config = config
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("rho", "density"), ("k", "conductivity"), ("name", "none"),
                ("notes", "none"), ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return []

    def summary(self,
                printSummary=True,
                propertyKeys="all",
                name=None,
                rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Names of component properties to be included. The following strings are also accepted as inputs:

  - "all": all properties in _properties are included,
  - "none": no properties are included.

    Defaults to "all".
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        if name is None:
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
Notes: {}
""".format(RSTHEADINGS[rstHeading] * len(output), self.notes)

        hasSummaryList = []
        for i in self._inputs:
            if i[0] in [
                    "flowsIn", "flowsOut", "flowIn", "flowOut", "flowInWf",
                    "flowOutWf", "flowInSf", "flowOutSf"
            ]:
                pass
            elif i[0] in ["solveAttr", "solveBracket", "solveBracketUnits"]:
                pass
            elif i[0] in ["name", "notes", "config"]:
                pass
            else:
                output += self.formatAttrUnitsForSummary(i, hasSummaryList)
        #
        for i in hasSummaryList:
            output += i.summary(printSummary=False, rstHeading=rstHeading + 1)
        #
        if propertyKeys == "all":
            propertyKeys = self._propertyKeys
        if propertyKeys == "none":
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """#
"""
            for i in propertyKeys:
                if i in self._propertyKeys:
                    j = self._propertyKeys.index(i)
                    output += self.formatAttrUnitsForSummary(
                        self._properties[j])
                else:
                    output += i + """: property not found,
"""
        if printSummary:
            print(output)
        return output
