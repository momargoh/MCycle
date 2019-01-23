from .mcabstractbase cimport MCAB
from CoolProp import AbstractState

cdef class FlowState(MCAB):
    cpdef public str fluid
    cdef public short phaseCP
    cpdef public double m
    cdef public unsigned short _inputPairCP
    cdef public double _input1
    cdef public double _input2
    #cpdef AbstractState _state
    cpdef public _state
    cdef bint _canBuildPhaseEnvelope
    cdef public bint isMixture(self)
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
    cpdef public double pCrit(self)
    cpdef public double pMin(self)
    cpdef public double TCrit(self)
    cpdef public double TMin(self)

    cpdef public str phase(self)

cdef dict validInputPairs
cdef dict _validInputPairs

cdef class FlowStatePoly(FlowState):
    cpdef public RefData refData
    cdef dict _c
    cdef str _inputProperty
    cdef double _inputValue
    cdef void _findAndSetInputProperty(self)
    cdef bint _validateInputs(self) except? False
    cpdef public void populate_c(self)
    
cdef class RefData:
    cpdef public str fluid
    cpdef public unsigned short deg
    cpdef public double p
    cpdef public dict data
    cpdef public short phaseCP
    cpdef public void populateData(self) except *
    
