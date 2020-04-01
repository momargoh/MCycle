cdef class MCAttr:
    cdef public cls
    cdef public str dimension
    
cdef class ABC:
    cdef public dict _inputs
    cdef public dict _properties
    cdef public str name
    cpdef public list _inputKeys(self)
    cpdef public list _inputValues(self)
    cpdef public list _propertyKeys(self)
    cpdef public list _propertyValues(self)

    cpdef public ABC copy(self)
    cpdef public ABC copyUpdate(self, dict kwargs)
    cpdef public void update(self, dict kwargs)
    
    cdef public str formatAttrForSummary(self, str attr, list hasSummaryList)
    cdef tuple itup
    cdef list ilist
