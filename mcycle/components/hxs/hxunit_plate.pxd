from ...bases.geom cimport Geom
from .hxunit_basicplanar cimport HxUnitBasicPlanar

cdef class HxUnitPlate(HxUnitBasicPlanar):
    cpdef public unsigned int _NWf(self)
    cpdef public unsigned int _NSf(self)
    cpdef public double _hWf(self)
    cpdef public double _hSf(self)
    cpdef public double _fWf(self)
    cpdef public double _fSf(self)
    cpdef public double _dpFWf(self)
    cpdef public double _dpFSf(self)
    cpdef public double U(self)
    cpdef public Geom geomWf
    cpdef public Geom geomSf
    
    cdef double Re(self, unsigned int flowId=*)
    cpdef public double ReSf(self)
    cpdef public double ReWf(self)

    cpdef double _f_sizeUnitsHxUnitPlate(self, double value, str attr)
    
