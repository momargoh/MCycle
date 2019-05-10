from .hx_basicplanar cimport HxBasicPlanar
from ...bases.geom cimport Geom

cdef class HxPlate(HxBasicPlanar):

    cpdef public Geom geomWf
    cpdef public Geom geomSf
    cpdef public double mass(self)
    cpdef public double dpFWf(self)
    cpdef public double dpFSf(self)
    cpdef public double dpAccWf(self)
    cpdef public double dpAccSf(self)
    cpdef public double dpHeadWf(self)
    cpdef public double dpHeadSf(self)
    cpdef public int size_NPlate(self) except *
