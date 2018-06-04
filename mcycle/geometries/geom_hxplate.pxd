from ..bases.geom cimport Geom

cdef class GeomHxPlateCorrChevron(Geom):
    cpdef public double b
    cpdef public double beta
    cpdef public double pitchCorr
    cpdef public double phi
    
cdef class GeomHxPlateFinOffset(Geom):
    cpdef public double s
    cpdef public double h
    cpdef public double t
    cpdef public double l
    cpdef public double b(self)
    cpdef public void set_b(self, value)

cdef class GeomHxPlateRough(Geom):
    cpdef public double b
    cpdef public double roughness

cdef class GeomHxPlateSmooth(GeomHxPlateRough):
    pass

