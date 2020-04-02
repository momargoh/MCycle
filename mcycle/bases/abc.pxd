cdef class ABC:
    cdef public tuple _inputs
    cdef public tuple _properties
    cdef public str name
    cpdef public tuple _inputValues(self)
    cpdef public tuple _propertyValues(self)

    cpdef public ABC copy(self)
    cpdef public ABC copyUpdate(self, dict kwargs)
    cpdef public void update(self, dict kwargs)
    
    cdef public str formatAttrForSummary(self, str attr, list hasSummaryList)
    cdef tuple itup
    cdef list ilist
