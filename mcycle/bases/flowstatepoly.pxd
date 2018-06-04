from .flowstate cimport FlowState

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
    cpdef public int deg
    cpdef public double p
    cpdef public dict data
    cpdef public int phaseCP
    cpdef public void populateData(self) except *
    

    
    

