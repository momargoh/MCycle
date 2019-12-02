from ...bases.mcabstractbase cimport MCAB

cdef class HxFlowConfig(MCAB):
    cdef public unsigned char sense
    cdef public unsigned int passes
    cdef public str arrangement
    cdef public bint verticalWf
    cdef public bint verticalSf
