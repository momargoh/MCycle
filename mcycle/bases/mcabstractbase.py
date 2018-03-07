from abc import ABCMeta, abstractmethod
from ..DEFAULTS import getUnits, PRINTFORMATFLOAT


class MCAbstractBase(metaclass=ABCMeta):
    """Abstract base class for all MCycle classes."""

    @abstractmethod
    def __init__(self):
        pass

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameter names, in order taken by constructor, along with any additional information. Formatted as ("parameter", "additional info", ...)."""
        pass

    @property
    @abstractmethod
    def _properties(self):
        """List of property names, along with any additional information. Formatted as ("property", "additional info", ...)."""
        pass

    @property
    def _inputKeys(self):
        return tuple(i[0] for i in self._inputs)

    @property
    def _inputValues(self):
        return tuple(getattr(self, i[0]) for i in self._inputs)

    @property
    def _propertyKeys(self):
        return tuple(i[0] for i in self._properties)

    @property
    def _propertyValues(self):
        return tuple(getattr(self, i[0]) for i in self._properties)

    def copy(self, **kwargs):
        """Return a new copy of a class object. Kwargs are passed to update() as a shortcut of simultaneously copying and updating."""
        copy = self.__class__(*self._inputValues)
        copy.update(**kwargs)
        return copy

    def update(self, **kwargs):
        """Update (multiple) class variables using keyword arguments."""
        for key, value in kwargs.items():
            if "__" in key:
                key_split = key.split("__", 1)
                key_attr = getattr(self, key_split[0])
                key_attr.update(**{key_split[1]: value})
            else:
                setattr(self, key, value)

    @abstractmethod
    def summary(self, printSummary=True):
        """str: Returns (and prints) summary of the class object."""
        pass

    def formatAttrUnitsForSummary(self, attr, hasSummaryList=[]):
        """str: Formats tuple of attribute name and units to be used in summary().

Parameters
------------
attr : tuple
    Tuple in the form ("attr", "units"), as found in _inputs and _properties.
hasSummaryList : list
    List to append attributes that themselves have the attribute "summary". Defaults to [] (which is not accessible outside function).
        """
        try:
            attrVal = getattr(self, attr[0])
            if hasattr(attrVal, "summary"):
                hasSummaryList.append(attr[0])
                return ""
            else:
                units = getUnits(attr[1])
                if units == "":
                    units = ""
                else:
                    units = " [" + units + "]"
                if type(attrVal) is float:
                    fcnOutput = """{} = {}{},
""".format(attr[0], PRINTFORMATFLOAT, units).format(attrVal)

                else:
                    fcnOutput = """{} = {}{},
""".format(attr[0], attrVal, units)
                return fcnOutput
        except Exception as inst:
            return """Attribute "{}" not found: {}
""".format(attr[0], inst)
