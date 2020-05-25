from ..bases.geom cimport Geom
from math import pi

cdef tuple _inputsPort = ('d', 't', 'l', 'name')
cdef tuple _propertiesPort = ('area()',)

cdef class Port(Geom):
    r"""Geometry of a port with circular cross-section.

Parameters
----------
diameter : float
    Inner diameter [m].
t : float
    Thickness [m].
length : float
    Extruded length [m].
    """

    def __init__(self,
                 double d,
                 double t=0,
                 double l=0,
                 str name="Port instance"):
        self.d = d
        self.t = t
        self.l = l
        self.name = name
        self.validClasses = ('HxPlate', 'HxUnitPlate')
        self._inputs = _inputsPort
        self._properties = _propertiesPort

    cpdef public double area(self):
        """double: cross-sectional area of port [m^2]."""
        return pi*self.d**2/4
