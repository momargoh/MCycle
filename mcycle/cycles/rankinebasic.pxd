from ..bases.config cimport Config
from ..bases.cycle cimport Cycle
from ..bases.component cimport Component
from ..bases.flowstate cimport FlowState

cdef class RankineBasic(Cycle):

    cpdef public FlowState wf
    cpdef public Component evap
    cpdef public Component exp
    cpdef public Component cond
    cpdef public Component comp
    cpdef public double pEvap
    cpdef public double superheat
    cpdef public double pCond
    cpdef public double subcool

    cpdef public void update(self, dict kwargs)
    
    cpdef public double _TEvap(self)
    cpdef public double _TCond(self)
    cpdef public void set_TEvap(self, double TEvap)
    cpdef public void set_TCond(self, double TCond)
    cpdef public double _mWf(self)
    cpdef public double _dpExp(self)
    cpdef public void set_dpExp(self, double value)
    cpdef public double _pRatioExp(self)
    cpdef public void set_pRatioExp(self, double value)
    cpdef public double _dpComp(self)
    cpdef public void set_dpComp(self, double value)
    cpdef public double _pRatioComp(self)
    cpdef public void set_pRatioComp(self, double value)

    
    cpdef public FlowState _state1(self)
    cpdef public void set_state1(self, FlowState obj)
    cpdef public FlowState _state20(self)
    cpdef public FlowState _state21(self)
    cpdef public FlowState _state3(self)
    cpdef public void set_state3(self, FlowState obj)
    cpdef public FlowState _state4(self)
    cpdef public void set_state4(self, FlowState obj)
    cpdef public FlowState _state50(self)
    cpdef public FlowState _state51(self)
    cpdef public FlowState _state6(self)
    cpdef public void set_state6(self, FlowState obj)
    cpdef public FlowState _sourceIn(self)
    cpdef public void set_sourceIn(self, FlowState obj)
    cpdef public FlowState _sourceOut(self)
    cpdef public void set_sourceOut(self, FlowState obj)
    cpdef public FlowState _sourceAmbient(self)
    cpdef public void set_sourceAmbient(self, FlowState obj)
    cpdef public FlowState _source1(self)
    #cpdef public void set_source1(self, FlowState obj)
    cpdef public FlowState _source20(self)
    cpdef public FlowState _source21(self)
    cpdef public FlowState _source3(self)
    #cpdef public void set_source3(self, FlowState obj)
    cpdef public FlowState _sinkIn(self)
    cpdef public void set_sinkIn(self, FlowState obj)
    cpdef public FlowState _sinkOut(self)
    cpdef public void set_sinkOut(self, FlowState obj)
    cpdef public FlowState _sinkAmbient(self)
    cpdef public void set_sinkAmbient(self, FlowState obj)
    cpdef public FlowState _sink4(self)
    #cpdef public void set_sink4(self, FlowState obj)
    cpdef public FlowState _sink50(self)
    cpdef public FlowState _sink51(self)
    cpdef public FlowState _sink6(self)
    #cpdef public void set_sink6(self, FlowState obj)
    cpdef public double PIn(self)
    cpdef public double POut(self)
    cpdef public double PNet(self)
    cpdef public double QIn(self)
    cpdef public double QOut(self)
    cpdef public double efficiencyThermal(self) except *
    cpdef public double efficiencyExergy(self) except *
    cpdef public double efficiencyRecovery(self) except *
    cpdef public double efficiencyGlobal(self) except *
    cpdef public double IEvap(self) except *
    cpdef public double IExp(self) except *
    cpdef public double IComp(self) except *
    cpdef public double ICond(self) except *
    cpdef public double ITotal(self) except *
    cpdef public double _pptdEvap(self)

    cpdef public void sizeSetup(self, bint unitiseEvap, bint unitiseCond)
