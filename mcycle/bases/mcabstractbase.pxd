cdef class MCAttr:
    cdef public cls
    cdef public str dimension
    
cdef class MCAB:
    cdef public dict _inputs
    cdef public dict _properties
    cdef public str name
    cpdef public list _inputKeys(self)
    cpdef public list _inputValues(self)
    cpdef public list _propertyKeys(self)
    cpdef public list _propertyValues(self)

    cpdef public MCAB copy(self)
    cpdef public MCAB copyUpdate(self, dict kwargs)
    cpdef public void update(self, dict kwargs)
    
    cdef public str formatAttrForSummary(self, dict attr, list hasSummaryList)
    cdef tuple itup
    cdef list ilist
