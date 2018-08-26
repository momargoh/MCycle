from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial

cdef class HxUnitBasic(Component22):
    cpdef public str flowSense
    cpdef public int NWf
    cpdef public int NSf
    cpdef public int NWall
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
    cpdef public double effThermal

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
    cpdef public str phaseWf(self)
    cpdef public str phaseSf(self)
    cdef public double QWf(self)
    cdef public double QSf(self)
    cpdef public double Q(self)
    cdef public double Q_lmtd(self)
    cpdef public double U(self)
    cpdef public double lmtd(self)
    cpdef public double weight(self)

    cdef double _f_sizeHxUnitBasic(self, double value, str attr)
    
