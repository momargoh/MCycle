from .mcabstractbase cimport MCAB
from .config cimport Config
from .flowstate cimport FlowState

cdef class Cycle(MCAB):
    cdef public tuple _componentKeys
    cdef public tuple _cycleStateKeys
    cdef public Config config

    cdef public list _cycleStateObjs(self)
    cdef public list _componentObjs(self)
    cpdef public void run(self)
    cpdef public void size(self)
    cpdef public void update(self, dict kwargs)
    cpdef public void clearWf_flows(self)
    cpdef public void clearAll_flows(self)
    cpdef public void setAll_config(self, Config obj)
    cpdef public void updateAll_config(self, dict kwargs)
