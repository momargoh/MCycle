from ...bases.component cimport Component11

cdef class HtrBasic(Component11):
    cpdef public unsigned char constraint
    cpdef public double QHeat
    cpdef public double efficiencyThermal

    cpdef public double dpWf(self)
    cpdef public double dpSf(self)
    cpdef public double _efficiencyFactorWf(self)
    cpdef public double _efficiencyFactorSf(self)
    cpdef public double Q(self)
    
    cpdef public void _run_constantP(self) except *
    cpdef public void _size_constantP(self) except *
    cpdef public void _run_constantV(self) except *
    cpdef public void _size_constantV(self) except *
    
