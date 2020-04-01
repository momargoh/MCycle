from .abc cimport ABC
#from CoolProp import AbstractState

cdef class FlowState(ABC):
    cpdef public str fluid
    cpdef public double m
    cdef public unsigned char _inputPair
    cdef public double _input1
    cdef public double _input2
    cdef public short _iphase
    cdef public str eos
    #cpdef AbstractState _state
    cpdef public _state
    cdef bint _canBuildPhaseEnvelope
    cdef public bint isMixture(self)
    cpdef public void updateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=*) except *
    cpdef public FlowState copyUpdateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=*)
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
    cpdef public double pMax(self)
    cpdef public double TCrit(self)
    cpdef public double TMin(self)
    cpdef public double TMax(self)

    cpdef public unsigned char phase(self)

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
    cpdef public short _iphase
    cpdef public str eos
    cpdef public void populateData(self) except *
    
