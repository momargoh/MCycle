from .mcabstractbase cimport MCAB
from .config cimport Config

cdef class SolidMaterial(MCAB):
    cpdef public double rho
    cpdef public dict data
    cdef dict _c
    cpdef public int deg
    cpdef public double T
    cpdef public str notes
    cpdef public Config config

    cpdef public void populate_c(self)
    cpdef public double k(self)
    
    

