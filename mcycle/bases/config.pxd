from .mcabstractbase cimport MCAB

cdef class Config(MCAB):

    cpdef public bint dpEvap
    cpdef public bint dpCond
    cpdef public bint dpFWf
    cpdef public bint dpFSf
    cpdef public bint dpAccWf
    cpdef public  bint dpAccSf
    cpdef public bint dpHeadWf
    cpdef public bint dpHeadSf
    cpdef public bint dpPortWf
    cpdef public bint dpPortSf
    cpdef public double g
    cpdef public str tolAttr
    cpdef public double tolAbs
    cpdef public double tolRel
    cpdef public double divT
    cpdef public double divX
    cpdef public dict methods
    cpdef public bint evenPlatesWf
    cpdef public double _tolRel_p 
    cpdef public double _tolRel_T 
    cpdef public double _tolRel_h 
    cpdef public double _tolRel_rho
    
    cpdef public str lookupMethod(self, str cls, tuple args)
    cpdef void set_method(self, str method, list geoms, list transfers, list phases, list flows)
