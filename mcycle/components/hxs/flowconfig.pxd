from ...bases.abc cimport ABC

cdef class HxFlowConfig(ABC):
    cdef public unsigned char sense
    cdef public unsigned int passes
    cdef public str arrangement
    cdef public bint verticalWf
    cdef public bint verticalSf
