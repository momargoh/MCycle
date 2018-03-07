from abc import abstractmethod
from ..DEFAULTS import RSTHEADINGS
from .mcabstractbase import MCAbstractBase as MCAB


class Geom(MCAB):
    """Abstract class for geometries."""

    validClasses = ()  #strings of class names for which geometry is valid.

    @abstractmethod
    def __init__(self, name="Geom instance", notes="no notes", **kwargs):
        self.name = name
        self.notes = notes
        for key, value in kwargs.items():
            setattr(self, key, value)

    def validClass(self, cls):
        """bool: Returns True if geometry is valid for the given class."""
        if cls in self.validClasses:
            return True
        else:
            return False

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        pass

    @property
    @abstractmethod
    def _properties(self):
        """List of class properties, along with their units as ("property", "units")."""
        pass

    def summary(self,
                printSummary=True,
                propertyKeys="all",
                name=None,
                rstHeading=0):
        """Returns (and prints) a summary of the geometry attributes/properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Names of component properties to be included. The following strings are also accepted as inputs:

  - "all": all properties in _properties are included,
  - "none": no properties are included.

    Defaults to "all".
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
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
