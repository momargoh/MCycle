from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState

cdef class HxSimple(Component22):
    cpdef public double U
    cpdef public double A
    cpdef public double efficiencyThermal

    cpdef public bint isEvap(self)
    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _efficiencyFactorWf(self)
    cpdef public double _efficiencyFactorSf(self)
    cdef public double _QWf(self)
    cdef public double _QSf(self)
    cpdef public double Q(self)
    cpdef public double lmtd(self)
    cpdef public double Q_lmtd(self)

    cdef double _f_runHxSimple(self, double value)
    
