from ...bases.component cimport Component11

cdef class ClrBasic(Component11):

    cpdef public double Q
    cpdef public double effThermal

    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _effFactorWf(self)
    cpdef public double _effFactorSf(self)
    cpdef public double _Q(self)
    
