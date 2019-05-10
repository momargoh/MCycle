from ..bases.geom cimport Geom

cdef class GeomHxPlateCorrugatedChevron(Geom):
    cpdef public double b
    cpdef public double beta
    cpdef public double pitchCorr
    cpdef public double phi
    
cdef class GeomHxPlateFinStraight(Geom):
    cpdef public double s
    cpdef public double t
    cpdef public double b
    #    
    cpdef public double h(self)
    cpdef public void set_h(self, value)
    cpdef public double areaPerWidth(self)
    
cdef class GeomHxPlateFinOffset(GeomHxPlateFinStraight):
    cpdef public double l

cdef class GeomHxPlateRough(Geom):
    cpdef public double b
    cpdef public double roughness
    #
    cpdef public double areaPerWidth(self)

cdef class GeomHxPlateSmooth(GeomHxPlateRough):
    pass

