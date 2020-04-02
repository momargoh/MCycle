from .abc cimport ABC

cdef class Config(ABC):

    cpdef public bint dpEvap
    cpdef public bint dpCond
    cpdef public bint evenPlatesWf
    cpdef public bint dpFWf
    cpdef public bint dpFSf
    cpdef public bint dpAccWf
    cpdef public bint dpAccSf
    cpdef public bint dpHeadWf
    cpdef public bint dpHeadSf
    cpdef public bint dpPortWf
    cpdef public bint dpPortSf
    cpdef public double dpPortInFactor
    cpdef public double dpPortOutFactor
    cpdef public unsigned short maxWalls
    cpdef public double gravity
    cpdef public str tolAttr
    cpdef public double tolAbs
    cpdef public double tolRel
    cpdef public double divT
    cpdef public double divX
    cpdef public unsigned short maxIterComponent
    cpdef public unsigned short maxIterCycle
    cpdef public dict methods
    cpdef public double _tolRel_p 
    cpdef public double _tolRel_T 
    cpdef public double _tolRel_h 
    cpdef public double _tolRel_rho
    
    cpdef public str lookupMethod(self, str cls, tuple args)# except *
    cpdef void set_method(self, str method, str geom, unsigned char transfer, unsigned char unitPhase, unsigned char flow) except *

