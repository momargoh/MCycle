from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from .hxunit_basic cimport HxUnitBasic

cdef class HxBasic(Component22):
    cpdef public str flowSense
    cpdef public int NWf
    cpdef public int NSf
    cpdef public int NWall
    cpdef public double hWf_liq
    cpdef public double hWf_tp
    cpdef public double hWf_vap
    cpdef public double hSf
    cpdef public double RfWf
    cpdef public double RfSf
    cpdef public SolidMaterial wall
    cpdef public double tWall
    cpdef public double A
    cpdef public double ARatioWf
    cpdef public double ARatioSf
    cpdef public double ARatioWall
    cpdef public double effThermal
    cpdef public list _units
    cpdef public _unitClass

    cpdef public bint isEvap(self)
    cpdef public double _A(self)
    cpdef public double _hWf(self)
    cpdef public double _hSf(self)
    cpdef public int _NWf(self)
    cpdef public int _NSf(self)
    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _effFactorWf(self)
    cpdef public double _effFactorSf(self)
    cdef public double _QWf(self)
    cdef public double _QSf(self)
    cpdef public double Q(self)
    #cpdef public double Q(self)
    cpdef public double weight(self)

    cpdef public void unitise(self)
    cdef public tuple _unitArgsLiq(self)
    cdef public tuple _unitArgsTp(self)
    cdef public tuple _unitArgsVap(self)
    cdef bint _checkContinuous(self)

    cpdef double _f_sizeHxBasic(self, double value, str attr, list unitsBounds)
    
