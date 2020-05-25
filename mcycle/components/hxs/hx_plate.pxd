from .hx_basicplanar cimport HxBasicPlanar
from ...bases.geom cimport Geom

cdef class HxPlate(HxBasicPlanar):

    cpdef public Geom geomWf
    cpdef public Geom geomSf
    cpdef public Geom portWf
    cpdef public Geom portSf
    cpdef public double LVertPortWf
    cpdef public double LVertPortSf
    cpdef public list coeffs_LPlate
    cpdef public list coeffs_WPlate
    cpdef public list coeffs_mass
    cdef double _LVertPortWf(self)
    cdef double _LVertPortSf(self)
    cpdef public double LPlate(self)
    cpdef public double WPlate(self)
    cpdef public double mass(self)
    cpdef public double depth(self)
    cpdef public double dpFWf(self)
    cpdef public double dpFSf(self)
    cpdef public double dpAccWf(self)
    cpdef public double dpAccSf(self)
    cpdef public double dpHeadWf(self)
    cpdef public double dpHeadSf(self)
    cpdef public double dpPortWf(self)
    cpdef public double dpPortSf(self)
    cpdef public unsigned int size_NPlate(self) except 0

    cdef public void _unitiseExtra(self)
