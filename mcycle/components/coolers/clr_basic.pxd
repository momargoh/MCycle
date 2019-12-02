from ...bases.component cimport Component11

cdef class ClrBasic(Component11):

    cpdef public double QCool
    cpdef public double efficiencyThermal

    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _efficiencyFactorWf(self)
    cpdef public double _efficiencyFactorSf(self)
    cpdef public double Q(self)
    
