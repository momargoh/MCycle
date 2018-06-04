from .mcabstractbase cimport MCAB
from CoolProp import AbstractState

cdef class FlowState(MCAB):
    cpdef public str fluid
    cdef public int phaseCP
    cpdef public double m
    cdef public int _inputPairCP
    cdef public double _input1
    cdef public double _input2
    #cpdef AbstractState _state
    cpdef public _state
    cpdef public void updateState(self, int inputPairCP, double input1, double input2)
    cpdef public FlowState copyState(self, int inputPairCP, double input1, double input2)
    cpdef public double T(self)
    cpdef public double p(self)
    cpdef public double rho(self)
    cpdef public double v(self)
    cpdef public double h(self)
    cpdef public double s(self)
    cpdef public double x(self)
    cpdef public double visc(self)
    cpdef public double k(self)
    cpdef public double cp(self)
    cpdef public double Pr(self)
    cpdef public double V(self)
    cpdef public str phase(self)
    

    
    

