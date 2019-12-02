from ..bases.component cimport Component11

cdef class FixedOut(Component11):
    cpdef public unsigned short inputPair
    cpdef public double input1
    cpdef public double input2
    
    cpdef public double Q(self)
    cpdef public double dp(self)
    cpdef public double dpWf(self)
