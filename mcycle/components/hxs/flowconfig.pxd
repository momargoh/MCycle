from ...bases.mcabstractbase cimport MCAB, MCAttr

cdef class HxFlowConfig(MCAB):
    cpdef public str sense
    cpdef public str passes
    cpdef public bint verticalWf
    cpdef public bint verticalSf
