from .abc cimport ABC

cdef class Geom(ABC):
    cdef public tuple validClasses
    cdef str cls
    cpdef bint validClass(self, str cls)   

