cdef class MCAttr:
    cdef public cls
    cdef public str dimension
    
cdef class MCAB:
    cpdef public dict _inputs
    cpdef public dict _properties
    cpdef public str name
    cpdef public list _inputKeys(self)
    cpdef public list _inputValues(self)
    cpdef public list _propertyKeys(self)
    cpdef public list _propertyValues(self)

    cpdef public MCAB _copy(self, dict kwargs)
    #cpdef MCAB copy(self, dict kwargs)
    cpdef public void update(self, dict kwargs)
    cdef public str formatAttrForSummary(self, dict attr, list hasSummaryList)
    cdef tuple itup
    cdef list ilist
