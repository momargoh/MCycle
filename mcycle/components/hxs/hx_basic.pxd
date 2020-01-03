from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from .hxunit_basic cimport HxUnitBasic
from .flowconfig cimport HxFlowConfig

cdef class HxBasic(Component22):
    cpdef public HxFlowConfig flowConfig
    cpdef public unsigned int NWf
    cpdef public unsigned int NSf
    cpdef public unsigned int NWall
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
    cpdef public double efficiencyThermal
    cpdef public list _units
    cdef public _unitClass

    cpdef public bint isEvap(self)
    cpdef public double _A(self)
    cpdef public double _hWf(self)
    cpdef public double _hSf(self)
    cpdef public unsigned int _NWf(self)
    cpdef public unsigned int _NSf(self)
    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _efficiencyFactorWf(self)
    cpdef public double _efficiencyFactorSf(self)
    cdef public double _QWf(self)
    cdef public double _QSf(self)
    cpdef public double Q(self)
    #cpdef public double Q(self)
    cpdef public double mass(self)

    cpdef public void unitise(self)
    cdef public void _unitiseExtra(self)
    cdef public tuple _unitArgsLiq(self)
    cdef public tuple _unitArgsTp(self)
    cdef public tuple _unitArgsVap(self)
    cdef bint _checkContinuous(self)

    cpdef double _f_sizeHxBasic(self, double value, str attr)
    
