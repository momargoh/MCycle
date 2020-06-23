from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from .flowconfig cimport HxFlowConfig

cdef class HxUnitBasic(Component22):
    cpdef public HxFlowConfig flowConfig
    cpdef public unsigned int NWf
    cpdef public unsigned int NSf
    cpdef public unsigned int NWall
    cpdef public double hWf
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
    cpdef public unsigned char _unitPhaseWf
    cpdef public unsigned char _unitPhaseSf
    cpdef public str _methodHeatWf
    cpdef public str _methodHeatSf
    cpdef public str _methodFrictionWf
    cpdef public str _methodFrictionSf

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
    cpdef public unsigned char phaseWf(self)
    cpdef public unsigned char phaseSf(self)
    cpdef public double QWf(self)
    cpdef public double QSf(self)
    cpdef public double Q(self)
    cdef public double Q_lmtd(self)
    cpdef public double U(self)
    cpdef public double lmtd(self)
    cpdef public double mass(self)

    cdef double _f_sizeHxUnitBasic(self, double value, str attr)
    
