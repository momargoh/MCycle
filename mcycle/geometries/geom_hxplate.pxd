from ..bases.geom cimport Geom

cdef class GeomHxPlateChevron(Geom):
    cpdef public double b
    cpdef public double beta
    cpdef public double pitch
    cpdef public double phi
    cpdef public double areaPerWidth(self)
    cpdef public double spacing(self)
    
cdef class GeomHxPlateFinStraight(Geom):
    cpdef public double s
    cpdef public double t
    cpdef public double b
    #    
    cpdef public double h(self)
    cpdef public void set_h(self, value)
    cpdef public double alpha(self)
    cpdef public double gamma(self)
    cpdef public double areaPerWidth(self)
    cpdef public double spacing(self)
    
cdef class GeomHxPlateFinOffset(GeomHxPlateFinStraight):
    cpdef public double l
    cpdef public double delta(self)

cdef class GeomHxPlateRough(Geom):
    cpdef public double b
    cpdef public double roughness
    #
    cpdef public double areaPerWidth(self)
    cpdef public double spacing(self)

cdef class GeomHxPlateSmooth(GeomHxPlateRough):
    pass

