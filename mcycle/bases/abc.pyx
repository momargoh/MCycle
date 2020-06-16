from .. import defaults
from ..defaults import getUnitsFormatted, getDimensions
from ..logger import log

cdef class ABC:
    """Abstract Base Class.

Attributes
-----------
_inputs : tuple of str
    Tuple of constructor argument names. Eg: ('arg1', 'arg2', 'arg3').
_properties : tuple of str
    Tuple of class property/method names (used by ``mcycle.bases.abc.summary``). Include '()' if the property is a Cython/Python class method, otherwise exclude if it is a Python property (uses the ``@property`` decorator). Eg: ('prop1()', 'prop2()', 'prop3()').
name : str, optional
    Descriptive name for the class instance. Defaults to "".
    """

    def __init__(self, tuple _inputs=(), tuple _properties=(), str name='', **kwargs):
        self._inputs = _inputs
        self._properties = _properties
        self.name = name

    cpdef public tuple _inputValues(self):
        """tuple : A deep copy of the current values of the input parameters"""
        cdef list values = []
        cdef str i
        for i in self._inputs:
            v = getattr(self, i)
            try:
                values.append(v.copy())
            except:
                values.append(v)
        return tuple(values)

    cpdef public tuple _propertyValues(self):
        """tuple : Values of the class attributes listed in ``_properties``"""
        cdef list values = []
        cdef str p
        for p in self._properties:
            if p.endswith("()"):
                values.append(getattr(self, p.strip("()"))())
            else:
                values.append(getattr(self, p))
        return tuple(values)

    cpdef public ABC copy(self):
        """Return a new copy of a class instance."""
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
    Dictionary of attributes and their updated value."""
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
        """str: Formats attribute to be used in summary(): gets value and looks up units.

Parameters
------------
attr : str
    String of attribute name as found in _inputs and _properties.
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
                return """{} = see summary below
""".format(attr)
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
            msg = """{} dimensions not defined in defaults.DIMENSIONS. Consider raising an issue on Github""".format(attr)
            log("INFO", msg, exc)
            return msg
        except Exception as inst:
            return """Attribute "{}" not found: {}
""".format(attr, inst)
