from .hx_basic cimport HxBasic
from .hxunit_basic cimport HxUnitBasic

cdef class HxBasicPlanar(HxBasic):
    cpdef public double L
    cpdef public double W
    cpdef public double _A(self)
    cpdef public double size_L(self, list unitsBounds)
    cpdef double _f_sizeHxBasicPlanar(self, double value, double L, str attr, list unitsBounds)
    cpdef double _f_runHxBasicPlanar(self, double value, double saveL)
