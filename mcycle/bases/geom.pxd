from .mcabstractbase cimport MCAB

cdef class Geom(MCAB):
    cdef public tuple validClasses
    cdef str cls
    cpdef bint validClass(self, str cls)   

