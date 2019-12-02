from ...bases.component cimport Component11

cdef class ExpBasic(Component11):
    cpdef public double pRatio
    cpdef public double efficiencyIsentropic

    cpdef public double POut(self)
    
