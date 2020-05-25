from ..bases.geom cimport Geom

cdef class Port(Geom):
    cpdef public double d
    cpdef public double t
    cpdef public double l
    #    
    cpdef public double area(self)
