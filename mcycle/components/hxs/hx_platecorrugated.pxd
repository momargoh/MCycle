from .hx_plate cimport HxPlate

cdef class HxPlateCorrugated(HxPlate):

    cpdef public void update(self, dict kwargs)
    cpdef public double DPortWf
    cpdef public double DPortSf
    cpdef public double LVertPortWf
    cpdef public double LVertPortSf
    cpdef public list coeffs_LPlate
    cpdef public list coeffs_WPlate
    cpdef public list coeffs_mass
    #
    cdef double _LVertPortWf(self)
    cdef double _LVertPortSf(self)
    cpdef public double LPlate(self)
    cpdef public double WPlate(self)
    cpdef public double mass(self)
    cpdef public double dpPortWf(self)
    cpdef public double dpPortSf(self)
    cpdef public double dpHeadWf(self)
    cpdef public double dpHeadSf(self)
    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
