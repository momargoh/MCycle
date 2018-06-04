#import pyximport
#pyximport.install()
from ...bases.component cimport Component11

cdef class ExpBasic(Component11):

    cpdef public double pRatio
    cpdef public double effIsentropic

    cpdef public double POut(self)
    
