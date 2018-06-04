from ...bases.component cimport Component22
from ...bases.config cimport Config
from .hxunit_basic cimport HxUnitBasic

cdef class HxUnitBasicPlanar(HxUnitBasic):
    cpdef public double L
    cpdef public double W
    cpdef public double _A(self)
    
