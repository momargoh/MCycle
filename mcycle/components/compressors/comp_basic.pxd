from ...bases.component cimport Component11

cdef class CompBasic(Component11):

    cpdef public double pRatio
    cpdef public double effIsentropic

    cpdef public double PIn(self)
    
