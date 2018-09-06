from ...bases.component cimport Component11

cdef class HtrBasic(Component11):

    cpdef public double QHeat
    cpdef public double effThermal

    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _effFactorWf(self)
    cpdef public double _effFactorSf(self)
    cpdef public double Q(self)
    
