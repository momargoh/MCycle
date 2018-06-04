from .mcabstractbase cimport MCAB, MCAttr
from .config cimport Config
from .flowstate cimport FlowState

cdef class Component(MCAB):

    cpdef public list flowsIn
    cpdef public list flowsOut
    cpdef public FlowState ambient
    cpdef public str sizeAttr
    cpdef public list sizeBracket
    cpdef public list sizeUnitsBracket
    cpdef public double[2] runBracket
    cpdef public str notes
    cpdef public Config config
    cdef public bint hasInAndOut(self, int flowIndex)

    cpdef public double _mWf(self)
    #cpdef _update(self, list kwargs)
    cpdef public void run(self)
    cpdef double _f_sizeComponent(self, double value, FlowState flowOutTarget, str sizeAttr, list sizeBracket, list sizeUnitsBracket)
    cpdef public void _size(self, str attr, list bracket, list bracketUnits) except *
    cpdef public void sizeUnits(self, str attr, list bracket) except *
    

cdef class Component11(Component):
    cpdef public double _m(self)


cdef class Component22(Component):

    cpdef public double _mSf(self)
