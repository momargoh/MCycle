from ..DEFAULTS cimport getUnits, PRINT_FORMAT_FLOAT

cdef class MCAttr:
    """Class for storing information about MCycle attributes, currently for use with summary() methods, but could have more future use. Only accessible by Cython code.

Attributes
-----------
cls : 
    Python class of attribute.
dimension : str, optional
    Dimensions of the attribute, eg. 'length/time'. Defaults to 'none'.
"""
    def __cinit__(self, cls, str dimension='none'):
        self.cls = cls #: definition of cls
        self.dimension = dimension
        
cdef class MCAB:
    """Abstract base class for all MCycle classes.

Attributes
-----------
_inputs : dict
    Dictionary of input parameter data in the form {key: MCAttr(...)}.
_properties : dict
    Dictionary of class properties data in the form {key: MCAttr(...)}, primarily used in summary().
name : str
    User selected name for the object.
    """
    
    def __init__(self):
        self._inputs = {}
        self._properties = {}
        #self.name = "" 

    cpdef public list _inputKeys(self):
        cdef list ilist = []
        cdef str k
        for k, v in self._inputs.items():
            ilist.append(k)
        return ilist

    cpdef public list _inputValues(self):
        cdef list ilist = []
        cdef str k
        for k, v in self._inputs.items():
            ilist.append(getattr(self, k))
        return ilist

    cpdef public list _propertyKeys(self):
        cdef list ilist = []
        cdef str k
        for k, v in self._properties.items():
            ilist.append(k)
        return ilist

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

    cpdef public MCAB _copy(self, dict kwargs):
        """Return a new copy of a class object. Kwargs (as dict) are passed to update() as a shortcut of simultaneously copying and updating.

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value."""
        copy = self.__class__(*self._inputValues())
        if kwargs != {}:
            copy.update(kwargs)
        return copy

    def copy(self, dict kwargs={}):
        """Return a new copy of a class object. Kwargs (as dict) are passed to update() as a shortcut of simultaneously copying and updating.

Parameters
-----------
kwargs : dict, optional
    Dictionary of attributes and their updated value."""
        return self._copy(kwargs)
    
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
       
    cdef public str formatAttrForSummary(self, dict attr, list hasSummaryList):
        """str: Formats dictionary of attribute name and MCAttr object (as found in _inputs) to be used in summary().

Parameters
------------
attr : dict
    Dictionary in the form ('attr name': MCAttr object), as found in _inputs and _properties.
hasSummaryList : list
    List to append attributes that themselves have the method 'summary'. Defaults to [] (which is not accessible outside function).
        """
        cdef str key, units
        [(key)] = attr.keys()
        try:
            if key.endswith("()"):
                attrVal = getattr(self,key.strip("()"))()
            else:
                attrVal = getattr(self, key)
            if hasattr(attrVal, "summary"):
                hasSummaryList.append(key)
                return ""
            else:
                units = getUnits(attr[key].dimension)
                if units == "":
                    units = ""
                else:
                    units = " [" + units + "]"
                if type(attrVal) is float:
                    fcnOutput = """{} = {}{},
""".format(key, PRINT_FORMAT_FLOAT, units).format(attrVal)

                else:
                    fcnOutput = """{} = {}{},
""".format(key, attrVal, units)
                return fcnOutput
        except Exception as inst:
            return """Attribute "{}" not found: {}
""".format(key, inst)
