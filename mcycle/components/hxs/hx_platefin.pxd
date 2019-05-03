from .hx_plate cimport HxPlate

cdef class HxPlateFin(HxPlate):
    cpdef public double LPlate(self)
    cpdef public double WPlate(self)
    cpdef public double mass(self)

    cdef public tuple _unitArgsLiq(self)
    cpdef public double LPlate(self)
    cpdef public double WPlate(self)
    cpdef public double mass(self)
