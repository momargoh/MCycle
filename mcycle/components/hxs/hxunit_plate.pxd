from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.geom cimport Geom
from .hxunit_basic cimport HxUnitBasic
from .hxunit_basicplanar cimport HxUnitBasicPlanar

cdef class HxUnitPlate(HxUnitBasicPlanar):
    cpdef public int _NWf(self)
    cpdef public int _NSf(self)
    cpdef public double _hWf(self)
    cpdef public double _hSf(self)
    cpdef public double _fWf(self)
    cpdef public double _fSf(self)
    cpdef public double _dpFWf(self)
    cpdef public double _dpFSf(self)
    cpdef public double U(self)
    cpdef public Geom geomPlateWf
    cpdef public Geom geomPlateSf

    cpdef double _f_sizeUnitsHxUnitPlate(self, double value, str attr)
    
