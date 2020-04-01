from .. import defaults
from ..defaults import getUnitsFormatted, getDimensions

cdef class MCAttr:
    """Class for storing information about MCycle attributes, currently for use with summary() methods, but could have more future use. Only accessible by Cython code.

Attributes
-----------
cls : Python class
    Python class of attribute.
dimension : str, optional
    Dimensions of the attribute, eg. 'length/time'. Defaults to 'none'.
"""
    def __cinit__(self, cls, str dimension='none'):
        self.cls = cls #: definition of cls
        self.dimension = dimension
        
cdef class ABC:
    """Abstract Base Class for all MCycle classes.

Attributes
-----------
name : str, optional
    Descriptive name for the class instance. Defaults to "".
_inputs : dict
    Dictionary of input parameter data in the form {key: MCAttr(...)}.
_properties : dict
    Dictionary of class properties data in the form {key: MCAttr(...)}, primarily used in summary().
    """

    def __init__(self, dict _inputs={}, dict _properties={}, str name='', **kwargs):
        self.name = name
        self._inputs = _inputs
        self._properties = _properties

    cpdef public list _inputKeys(self):
        return list(self._inputs.keys())    

    cpdef public list _inputValues(self):
        cdef list ilist = []
        cdef str k
        for k, v in self._inputs.items():
            ilist.append(getattr(self, k))
        return ilist

    cpdef public list _propertyKeys(self):
        return list(self._properties.keys())

    cpdef public list _propertyValues(self):
        cdef list ilist = []
        cdef str k
        for k, v in self._properties.items():
            if k.endswith("()"):
                ilist.append(getattr(self, k.strip("()"))())
            else:
                ilistVal = getattr(self, k)
                ilist.append(ilistVal)
        return ilist

    cpdef public ABC copy(self):
        """Return a new copy of an object."""
        cdef ABC copy = self.__class__(*self._inputValues())
        return copy

    cpdef public ABC copyUpdate(self, dict kwargs):
        """Create a new copy of an object then update it using kwargs (as dict).

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value."""
        cdef ABC copy = self.__class__(*self._inputValues())
        copy.update(kwargs)
        return copy
    
    cpdef public void update(self, dict kwargs):
        """Update (multiple) class variables from a dictionary of keyword arguments.

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value; kwargs={'key': value}."""
        cdef str key
        cdef list key_split
        for key, value in kwargs.items():
            if "." in key:
                key_split = key.split(".", 1)
                key_attr = getattr(self, key_split[0])
                key_attr.update({key_split[1]: value})
            elif '[' in key and ']' in key:
                key = key.replace('[',']')
                key_split = key.split(']')
                key_split.remove('')
                if len(key_split) > 2:
                    key_attr = getattr(self, key_split[0])[int(key_split[1])]
                    key_attr.update({key_split[2]: value})
                else:
                    key_attr = getattr(self, key_split[0])
                    key_attr[int(key_split[1])] = value
            else:
                setattr(self, key, value)
              
    cdef public str formatAttrForSummary(self, str attr, list hasSummaryList):
        """str: Formats dictionary of attribute name and MCAttr object (as found in _inputs) to be used in summary().

Parameters
------------
attr : dict
    Dictionary in the form ('attr name': MCAttr object), as found in _inputs and _properties.
hasSummaryList : list
    List to append attributes that themselves have the method 'summary'. Defaults to [] (which is not accessible outside function).
        """
        cdef str dimensions, units
        try:
            if attr.endswith("()"):
                attr = attr.strip("()")
                attrVal = getattr(self, attr)()
            else:
                attrVal = getattr(self, attr)
            if hasattr(attrVal, "summary"):
                hasSummaryList.append(attr)
                return ""
            else:
                dimensions = getDimensions(attr, self.__class__.__name__)
                units = getUnitsFormatted(dimensions)
                if type(attrVal) is float:
                    fcnOutput = """{} = {}{}
""".format(attr, defaults.PRINT_FORMAT_FLOAT, units).format(attrVal)

                else:
                    fcnOutput = """{} = {}{}
""".format(attr, attrVal, units)
                return fcnOutput
        except AttributeError:
            return """{} not yet defined
""".format(attr)
        except KeyError as exc:
            return """{} dimensions not defined in defaults.DIMENSIONS. Consider raising an issue on Github""".format(attr)
        except Exception as inst:
            return """Attribute "{}" not found: {}
""".format(attr, inst)
