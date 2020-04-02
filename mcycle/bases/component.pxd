from .abc cimport ABC
from .config cimport Config
from .flowstate cimport FlowState

cdef class Component(ABC):

    cpdef public list flowsIn
    cpdef public list flowsOut
    cpdef public FlowState ambient
    cpdef public str sizeAttr
    cpdef public list sizeBounds
    cpdef public str sizeUnitsAttr
    cpdef public list sizeUnitsBounds
    cpdef public list runBounds
    cpdef public list runUnitsBounds
    cpdef public str notes
    cpdef public Config config
    cdef public bint hasInAndOut(self, int flowIndex)

    cpdef public double _mWf(self)
    #cpdef _update(self, list kwargs)
    cpdef public void clearWfFlows(self)
    cpdef public void clearAllFlows(self)
    cpdef public void run(self) except *
    cpdef double _f_sizeComponent(self, double value, FlowState flowOutTarget, str attr)
    cpdef public void size(self) except *
    cpdef public void sizeUnits(self) except *
    

cdef class Component11(Component):
    cpdef public double _m(self)


cdef class Component22(Component):
    cpdef public double _mSf(self)
