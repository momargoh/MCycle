from .hx_basicplanar cimport HxBasicPlanar
from .hxunit_basic cimport HxUnitBasic
from .hxunit_plate cimport HxUnitPlate
from ...bases.geom cimport Geom

cdef class HxPlateFin(HxBasicPlanar):

    cpdef public void update(self, dict kwargs)
    cpdef public Geom geomPlateWf
    cpdef public Geom geomPlateSf
    cpdef public double DPortWf
    cpdef public double DPortSf
    cpdef public double LVertPortWf
    cpdef public double LVertPortSf
    cpdef public list coeffs_LPlate
    cpdef public list coeffs_WPlate
    cpdef public list coeffs_weight
    cdef double _LVertPortWf(self)
    cdef double _LVertPortSf(self)
    cpdef public double LPlate(self)
    cpdef public double WPlate(self)
    cpdef public double dpFWf(self)
    cpdef public double dpFSf(self)
    cpdef public double dpAccWf(self)
    cpdef public double dpAccSf(self)
    cpdef public double dpPortWf(self)
    cpdef public double dpPortSf(self)
    cpdef public double dpHeadWf(self)
    cpdef public double dpHeadSf(self)
    cpdef public int size_NPlate(self) except *
