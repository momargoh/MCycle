from ..bases.component cimport Component11
from ..bases.config cimport Config
from ..bases.flowstate cimport FlowState
from ..bases.mcabstractbase cimport MCAB, MCAttr

cdef class FixedOut(Component11):
    cpdef public refProps
    cpdef public double refProp1
    cpdef public double refProp2
    
    cpdef public double Q(self)
    cpdef public double dp(self)
    cpdef public double dpWf(self)
