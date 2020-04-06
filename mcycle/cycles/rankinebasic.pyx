from .. import defaults
from .._constants cimport *
from ..logger import log
from ..bases.config cimport Config
from ..bases.cycle cimport Cycle
from ..bases.component cimport Component
from ..bases.flowstate cimport FlowState
from ..components.hxs.hx_basic cimport HxBasic
from ..utils.saturation_curves import saturationCurve
from math import nan, isnan
import numpy as np

from warnings import warn

cdef tuple _inputs = ('wf', 'evap', 'exp', 'cond', 'comp', 'pEvap', 'superheat', 'pCond', 'subcool', 'config')
cdef tuple _properties = ('mWf', 'QIn()', 'QOut()', 'PIn()', 'POut()', 'efficiencyThermal()', 'efficiencyExergy()', 'IComp()', 'IEvap()', 'IExp()', 'ICond()')

cdef class RankineBasic(Cycle):
    """Defines all cycle components and design parameters for a basic four-stage (steam/organic) Rankine cycle.

Parameters
-----------
wf : FlowState
    Working fluid.
evap : Component
    Evaporator object. Must be subclass of HxBasic or HtrBasic. Any incoming flows of secondary fluids should be pre-defined.
exp : Component
    Expander object. Must be subclass of ExpBasic.
cond : Component
    Condenser object. Must be subclass of HxBasic or ClrBasic. Any incoming flows of secondary fluids should be pre-defined.
comp : Component
    Compressor object. Must be subclass of CompBasic.
pEvap : float, optional
    Evaporator vapourisation pressure [Pa].
superheat : float, optional
    Evaporator superheating [K].
pCond : float, optional
    Condenser vaporisation pressure [Pa].
subcool : float, optional
    Condenser subcooling [K].
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
name : str, optional
    Description of Cycle object. Defaults to "RankineBasic instance".
    """

    def __init__(self,
                 FlowState wf,
                 Component evap,
                 Component exp,
                 Component cond,
                 Component comp,
                 double pEvap=nan,
                 double superheat=nan,
                 double pCond=nan,
                 double subcool=nan,
                 Config config=None,
                 str name="RankineBasic instance"):
        self.wf = wf
        self.evap = evap
        self.exp = exp
        self.cond = cond
        self.comp = comp
        self.pEvap = pEvap
        self.superheat = superheat
        self.pCond = pCond
        self.subcool = subcool
        super().__init__(("evap", "exp", "cond", "comp"),
                         ("1", "20", "21", "3", "4", "51", "50", "6"), config, name)
        #self.setAll_config(config)  # use setter to set for all components
        self._inputs =  _inputs
        self._properties = _properties

    cpdef public void update(self, dict kwargs):
        """Update (multiple) Cycle variables using keyword arguments."""
        cdef str key
        cdef list keySplit
        cdef dict store = {}
        for key, value in kwargs.items():
            if key == "evap" and self.sourceIn is not None:
                if issubclass(type(value), HxBasic):
                    value.update({'flowInSf':self.sourceIn})
                setattr(self, key, value)
            elif key == "cond" and self.sinkIn is not None:
                if issubclass(type(value), HxBasic):
                    value.update({'flowInSf':self.sinkIn})
                setattr(self, key, value)
            else:
                if "." in key:
                    key_split = key.split(".", 1)
                    key_attr = getattr(self, key_split[0])
                    key_attr.update({key_split[1]: value})
                else:
                    try:
                        setter = getattr(self, 'set_{}'.format(key))
                        setter(value)
                    except AttributeError:
                        super(RankineBasic, self).update({key: value})

    cpdef public double _mWf(self):
        return self.wf.m
    
    @property
    def mWf(self):
        """float: Alias of wf.m; mass flow rate of the working fluid [kg/s]."""
        return self.wf.m

    @mWf.setter
    def mWf(self, value):
        self.wf.m = value

    cpdef public double _TCond(self):
        cdef FlowState sat = self.wf.copyUpdateState(PQ_INPUTS, self.pCond, 0)
        return sat.T()
    
    cpdef public void set_TCond(self, double TCond):
        cdef FlowState sat = self.wf.copyUpdateState(QT_INPUTS, 0, TCond)
        self.pCond = sat.p()
    
    @property
    def TCond(self):
        """float: Evaporation temperature of the working fluid in the compressor [K]."""
        return self._TCond()

    @TCond.setter
    def TCond(self, value):
        self.set_TCond(value)

    cpdef public double _TEvap(self):
        return self.wf.copyUpdateState(PQ_INPUTS, self.pEvap, 0).T()
    
    cpdef public void set_TEvap(self, double TEvap):
        cdef FlowState sat = self.wf.copyUpdateState(QT_INPUTS, 0, TEvap)
        self.pEvap = sat.p()

    @property
    def TEvap(self):
        """float: Evaporation temperature of the working fluid in the evaporator [K]."""
        return self._TEvap()

    @TEvap.setter
    def TEvap(self, value):
        self.set_TEvap(value)
        
    cpdef public double _dpComp(self):
        return self.pEvap - self.pCond
    
    cpdef public void set_dpComp(self, double value):
        self.pEvap = self.pCond + value

    @property
    def dpComp(self):
        """float: Pressure increase across the compressor [Pa]."""
        return self.pEvap - self.pCond

    @dpComp.setter
    def dpComp(self, value):
        self.pEvap = self.pCond + value

    cpdef public double _pRatioComp(self):
        return self.pEvap / self.pCond
    
    cpdef public void set_pRatioComp(self, double value):
        self.pEvap = self.pCond * value
        self.comp.pRatio = value

    @property
    def pRatioComp(self):
        """float: Pressure ratio of the compressor."""
        return self.pEvap / self.pCond

    @pRatioComp.setter
    def pRatioComp(self, value):
        self.pEvap = self.pCond * value
        
    cpdef public double _dpExp(self):
        return self.pEvap - self.pCond
    
    cpdef public void set_dpExp(self, double value):
        self.pCond = self.pEvap - value
        
    @property
    def dpExp(self):
        """float: Pressure drop across the expander [Pa]."""
        return self._dpExp()

    @dpExp.setter
    def dpExp(self, value):
        self.set_dpExp(value)

    cpdef public double _pRatioExp(self):
        return self.pEvap / self.pCond
    
    cpdef public void set_pRatioExp(self, double value):
        self.pCond = self.pEvap / value
        self.exp.pRatio = value
        
    @property
    def pRatioExp(self):
        """float: Pressure ratio of the expander."""
        return self._pRatioExp()
    
    @pRatioExp.setter
    def pRatioExp(self, value):
        self.set_pRatioExp(value)

    cpdef public FlowState _state1(self):
        return self.evap.flowsIn[0]
    
    cpdef public void set_state1(self, FlowState obj):
        self.evap.flowsIn[0] = obj
        self.comp.flowsOut[0] = obj

    cpdef public FlowState _state20(self):
        return self.wf.copyUpdateState(PQ_INPUTS, self.evap.flowsIn[0].p(), 0)
    
    cpdef public FlowState _state21(self):
        return self.wf.copyUpdateState(PQ_INPUTS, self.evap.flowsIn[0].p(), 1)

    cpdef public FlowState _state3(self):
        return self.exp.flowsIn[0]
    
    cpdef public void set_state3(self, FlowState obj):
        self.exp.flowsIn[0] = obj
        self.evap.flowsOut[0] = obj

    cpdef public FlowState _state4(self):
        return self.cond.flowsIn[0]
    
    cpdef public void set_state4(self, FlowState obj):
        self.cond.flowsIn[0] = obj
        self.exp.flowsOut[0] = obj

    cpdef public FlowState _state50(self):
        return self.wf.copyUpdateState(PQ_INPUTS, self.cond.flowsIn[0].p(), 0)
    
    cpdef public FlowState _state51(self):
        return self.wf.copyUpdateState(PQ_INPUTS, self.cond.flowsIn[0].p(), 1)

    cpdef public FlowState _state6(self):
        return self.comp.flowsIn[0]
    
    cpdef public void set_state6(self, FlowState obj):
        self.comp.flowsIn[0] = obj
        self.cond.flowsOut[0] = obj

    @property
    def state1(self):
        """FlowState: Working fluid flow at compressor outlet/ evaporator inlet."""
        return self._state1()

    @state1.setter
    def state1(self, obj):
        self.set_state1(obj)

    @property
    def state20(self):
        """FlowState: Working fluid saturated liquid FlowState in evaporator."""
        return self._state20()

    @property
    def state21(self):
        """FlowState: Working fluid saturated vapour FlowState in evaporator."""
        return self._state21()

    @property
    def state3(self):
        """FlowState: Working fluid FlowState at evaporator outlet/expander inlet."""
        return self._state3()

    @state3.setter
    def state3(self, obj):
        self.set_state3(obj)

    @property
    def state4(self):
        """FlowState: Working fluid FlowState at expander outlet/condenser inlet."""
        return self._state4()

    @state4.setter
    def state4(self, obj):
        self.set_state4(obj)

    @property
    def state50(self):
        """FlowState: Working fluid saturated liquid FlowState in condenser."""
        return self._state50()

    @property
    def state51(self):
        """FlowState: Working fluid saturated vapour FlowState in condenser."""
        return self._state51()

    @property
    def state6(self):
        """FlowState: Working fluid FlowState at condenser outlet/ compressor inlet."""
        return self._state6()

    @state6.setter
    def state6(self, obj):
        self.set_state6(obj)

    cpdef public FlowState _sourceIn(self):
        if len(self.evap.flowsIn) > 1:
            return self.evap.flowsIn[1]
        else:
            return None
    
    cpdef public void set_sourceIn(self, FlowState obj):
        if len(self.evap.flowsIn) > 1:
            self.evap.flowsIn[1] = obj
        else:
            log("info", "Could not set RankineBasic.sourceIn with {} evaporator".format(type(self.evap)))
            pass
        

    cpdef public FlowState _sourceOut(self):
        if len(self.evap.flowsOut) > 1:
            return self.evap.flowsOut[1]
        else:
            return None
    
    cpdef public void set_sourceOut(self, FlowState obj):
        if len(self.evap.flowsOut) > 1:
            self.evap.flowsOut[1] = obj
        else:
            log("info", "Could not set RankineBasic.sourceOut with {} evaporator".format(type(self.evap)))
            pass

    cpdef public FlowState _source1(self):
        if self.evap.flowConfig.sense == COUNTERFLOW:
            return self._sourceOut()
        elif self.evap.flowConfig.sense == PARALLELFLOW:
            return self._sourceIn()
        else:
            return None

    cpdef public FlowState _source20(self):
        cdef double h
        if self.evap.flowConfig.sense == COUNTERFLOW:
            h = self._source1().h() + self._mWf() * self.evap._efficiencyFactorWf() * (
                self._state20().h() - self._state1().h()
            ) / self._source1().m / self.evap._efficiencyFactorSf()
        elif self.evap.flowConfig.sense == PARALLELFLOW:
            h = self._source1().h() - self._mWf() * self.evap._efficiencyFactorWf() * (
                self._state20().h() - self._state1().h()
            ) / self._source1().m / self.evap._efficiencyFactorSf()
        else:
            return None
        return self._sourceIn().copyUpdateState(HmassP_INPUTS, h, self._sourceIn().p())

    cpdef public FlowState _source21(self):
        cdef double h
        if self.evap.flowConfig.sense == COUNTERFLOW:
            h = self._source1().h() + self._mWf() * self.evap._efficiencyFactorSf() * (
                self._state21().h() - self._state1().h()
            ) / self._sourceIn().m / self.evap._efficiencyFactorSf()
        elif self.evap.flowConfig.sense == PARALLELFLOW:
            h = self._source1().h() - self._mWf() * self.evap._efficiencyFactorWf() * (
                self._state21().h() - self._state1().h()
            ) / self._sourceIn().m / self.evap._efficiencyFactorSf()
        else:
            return None
        return self._sourceIn().copyUpdateState(HmassP_INPUTS, h, self._sourceIn().p())

    cpdef public FlowState _source3(self):
        if self.evap.flowConfig.sense == COUNTERFLOW:
            return self._sourceIn()
        elif self.evap.flowConfig.sense == PARALLELFLOW:
            return self._sourceOut()
        else:
            return None

    cpdef public FlowState _sourceAmbient(self):
        return self.evap.ambient

    cpdef public void set_sourceAmbient(self, FlowState obj):
        self.evap.ambient = obj

    @property
    def sourceIn(self):
        """FlowState: Alias of evap.flowInSf. Only valid with a secondary flow as the heat source."""
        return self._sourceIn()

    @sourceIn.setter
    def sourceIn(self, obj):
        self.set_sourceIn(obj)

    @property
    def sourceOut(self):
        """FlowState: Alias of evap.flowOutSf. Only valid with a secondary flow as the heat source."""
        return self._sourceOut()

    @property
    def source1(self):
        """FlowState: Heat source when working fluid is at state1. Only valid with a secondary flow as the heat source."""
        return self._source1()

    @property
    def source20(self):
        """FlowState: Heat source when working fluid is at state20. Only valid with a secondary flow as the heat source."""
        return self._source20()

    @property
    def source21(self):
        """FlowState: Heat source when working fluid is at state21. Only valid with a secondary flow as the heat source."""
        return self._source21()

    @property
    def source3(self):
        """FlowState: Heat source when working fluid is at state3. Only valid with a secondary flow as the heat source."""
        return self._source3()

    @property
    def sourceAmbient(self):
        """FlowState: Alias of evap.ambient. Only valid with a secondary flow as the heat source."""
        return self._sourceAmbient()

    @sourceAmbient.setter
    def sourceAmbient(self, obj):
        self.set_sourceAmbient(obj)
        
    cpdef public FlowState _sinkIn(self):
        if len(self.cond.flowsIn) > 1:
            return self.cond.flowsIn[1]
        else:
            return None

    cpdef public void set_sinkIn(self, FlowState obj):
        if len(self.cond.flowsIn) > 1:
            self.cond.flowsIn[1] = obj
        else:
            log("info", "Could not set RankineBasic.sinkIn with {} condenser".format(type(self.cond)))
            pass

    cpdef public FlowState _sinkOut(self):
        return self.cond.flowsOut[1]

    cpdef public void set_sinkOut(self, FlowState obj):
        self.cond.flowsOut[1] = obj

    cpdef public FlowState _sink4(self):
        if self.cond.flowConfig.sense == COUNTERFLOW:
            return self._sinkOut()
        elif self.cond.flowConfig.sense == PARALLELFLOW:
            return self._sinkIn()
        else:
            return None
        
    cpdef public FlowState _sink6(self):
        if self.cond.flowConfig.sense == COUNTERFLOW:
            return self._sinkIn()
        elif self.cond.flowConfig.sense == PARALLELFLOW:
            return self._sinkOut()
        else:
            return None
    
    cpdef public FlowState _sink50(self):
        cdef double h
        if self.cond.flowConfig.sense == COUNTERFLOW:
            h = self._sink4().h() - self._mWf() * self.cond._efficiencyFactorWf() * (
                self._state4().h() - self._state50().h()
            ) / self._sink4().m / self.cond._efficiencyFactorSf()
        elif self.cond.flowConfig.sense == PARALLELFLOW:
            h = self._sink4().h() + self._mWf() * self.cond._efficiencyFactorWf() * (
                self._state4().h() - self._state50().h()
            ) / self._sink4().m / self.cond._efficiencyFactorSf()
        else:
            return None
        return self._sinkIn().copyUpdateState(HmassP_INPUTS, h, self._sinkIn().p())

    cpdef public FlowState _sink51(self):
        cdef double h
        if self.cond.flowConfig.sense == COUNTERFLOW:
            h = self._sink4().h() - self._mWf() * self.cond._efficiencyFactorWf() * (
                self._state4().h() - self._state51().h()
            ) / self._sink4().m / self.cond._efficiencyFactorSf()
        elif self.cond.flowConfig.sense == PARALLELFLOW:
            h = self._sink4().h() + self._mWf() * self.cond._efficiencyFactorWf() * (
                self._state4().h() - self._state51().h()
            ) / self._sink4().m / self.cond._efficiencyFactorSf()
        else:
            return None
        return self._sinkIn().copyUpdateState(HmassP_INPUTS, h, self._sinkIn().p())

    cpdef public FlowState _sinkAmbient(self):
        return self.cond.ambient

    cpdef public void set_sinkAmbient(self, FlowState obj):
        self.cond.ambient = obj


    @property
    def sinkIn(self):
        """FlowState: Alias of cond.flowInSf. Only valid with a secondary flow as the heat sink."""
        return self._sinkIn()

    @sinkIn.setter
    def sinkIn(self, obj):
        self.set_sinkIn(obj)

    @property
    def sinkOut(self):
        """FlowState: Alias of cond.flowOutSf. Only valid with a secondary flow as the heat sink."""
        return self._sinkOut()

    @property
    def sink4(self):
        """FlowState: Heat sink when working fluid is at state4. Only valid with a secondary flow as the heat sink."""
        return self._sink4()

    @property
    def sink50(self):
        """FlowState: Heat sink when working fluid is at state50. Only valid with a secondary flow as the heat sink."""
        return self._sink50()

    @property
    def sink51(self):
        """FlowState: Heat sink when working fluid is at state51. Only valid with a secondary flow as the heat sink."""
        return self._sink51()

    @property
    def sink6(self):
        """FlowState: Heat sink when working fluid is at state6. Only valid with a secondary flow as the heat sink."""
        return self._sink6()

    @property
    def sinkAmbient(self):
        """FlowState: Alias of cond.ambient. Only valid with a secondary flow as the heat sink."""
        return self._sinkAmbient()

    @sinkAmbient.setter
    def sinkAmbient(self, obj):
        self.set_sinkAmbient(obj)


    cpdef public double QIn(self):
        """float: Heat input (from evaporator) [W]."""
        return self.evap.Q() #self._mWf() * (self.state3.h() - self.state1.h())

    cpdef public double QOut(self):
        """float: Heat output (from condenser) [W]."""
        return self.cond.Q() #self._mWf() * (self.state4.h() - self.state6.h())

    cpdef public double PIn(self):
        """float: Power input (from compressor) [W]."""
        return self.comp.PIn()  #self._mWf() * (self.state1.h() - self.state6.h())

    cpdef public double POut(self):
        """float: Power output (from expander) [W]."""
        return self.exp.POut()  # self._mWf() * (self.state3.h() - self.state4.h())

    cpdef public double PNet(self):
        """float: Net power output [W].
        PNet = POut() - PIn()"""
        return self.POut() - self.PIn()

    cpdef public double efficiencyThermal(self) except *:
        """float: Cycle thermal efficiency [-]
        efficiencyThermal = PNet/QIn"""
        return self.PNet() / self.QIn()

    cpdef public double efficiencyRecovery(self) except *:
        """float: Exhaust heat recovery efficiency"""
        if len(self.evap.flowsIn) == 1:
            log("warning", "efficiencyRecovery() is not valid with {} evaporator".format(type(self.evap)))
            return nan
        else:
            try:
                return (self._sourceIn().h() - self._sourceOut().h()) / (self._sourceIn().h() - self._sourceAmbient().h())
            except Exception as exc:
                log("error", "efficiencyRecovery() could not be calculated", exc_info=exc)
                return nan

    cpdef public double efficiencyExergy(self) except *:
        """float: Exergy efficiency"""
        if len(self.evap.flowsIn) == 1:
            log("warning", "efficiencyExergy() is not valid with {} evaporator".format(type(self.evap)))
            return nan
        else:
            try:
                return self.PNet() / self._sourceIn().m / (self._sourceIn().h() - self._sourceAmbient().h())
            except Exception as exc:
                log("error", "efficiencyExergy() could not be calculated", exc_info=exc)
                return nan

    cpdef public double efficiencyGlobal(self) except *:
        """float: Global recovery efficiency"""
        return self.efficiencyThermal() * self.efficiencyExergy()

    cpdef public double IComp(self) except *:
        """float: Exergy destruction of compressor [W]"""
        if len(self.cond.flowsIn) == 1:
            log("warning", "IComp() is not valid with {} condenser".format(type(self.cond)))
            return nan
        else:
            try:
                return self._sinkAmbient().T() * self._mWf() * (
                self._state1().s() - self._state6().s())
            except Exception as exc:
                log("error", "IComp() could not be calculated", exc_info=exc)
                return nan

    cpdef public double IEvap(self) except *:
        """float: Exergy destruction of evaporator [W]"""
        cdef FlowState ambientSource
        cdef double I_13, I_C0
        if len(self.evap.flowsIn) == 1:
            log("warning", "IEvap() is not valid with {} evaporator".format(type(self.evap)))
            return nan
        else:
            try:
                ambientSource = self._sourceIn().copyUpdateState(PT_INPUTS, self._sourceAmbient.p(), self._sourceAmbient().T())
            except Exception as exc:
                log("warning", "Could not create evaporator source flow at ambient conditions. Returned nan. ", exc_info=exc)
                return nan
            I_13 = ambientSource.T() * (
                self._mWf() * (self._state3().s() - self._state1().s()) + self._sourceIn().m *
                (self._source1().s() - self._sourceIn().s()))
            I_C0 = ambientSource.T() * self._sourceIn().m * (
                (ambientSource.s() - self._source1().s()) +
                (self._source1().h() - ambientSource.h()) / ambientSource.T())
            return I_13 + I_C0

    cpdef public double IExp(self) except *:
        """float: Exergy destruction of expander [W]"""
        if len(self.cond.flowsIn) == 1:
            log("warning", "IExp() is not valid with {} condenser".format(type(self.cond)))
            return nan
        else:
            try:
                return self._sinkAmbient().T() * self._mWf() * (
            self._state4().s() - self._state3().s())
            except Exception as exc:
                log("error", "IExp() could not be calculated", exc_info=exc)
                return nan

    cpdef public double ICond(self) except *:
        """float: Exergy destruction of condenser [W]"""
        if len(self.cond.flowsIn) == 1:
            log("warning", "ICond() is not valid with {} condenser".format(type(self.cond)))
            return nan
        else:
            try:
                return self._sinkAmbient().T() * self._mWf() * (
            (self._state50().s() - self._state4().s()) +
            (self._state4().h() - self._state50().h()) / self._sinkAmbient().T())
            except Exception as exc:
                log("error", "ICond() could not be calculated", exc_info=exc)
                return nan

    cpdef public double ITotal(self) except *:
        """float: Total exergy destruction of cycle [W]"""
        return self.IComp() + self.IEvap() + self.IExp() + self.ICond()
    
    cpdef public double _pptdEvap(self):
        """float: Pinch-point temperature difference of evaporator"""
        if issubclass(type(self.evap), HxBasic):
            if self.evap.flowConfig.sense == COUNTERFLOW:
                if self._state1() and self._state20() and self._source1() and self._source20():
                    return min(self._source20().T() - self._state20().T(),
                               self._source1().T() - self._state1().T())

                else:
                    warn("run() or size() has not been executed")
            else:
                warn("pptdEvap is not a valid for flowConfig.sense = {}".format(self.evap.flowConfig.sense))
        else:
            warn("pptdEvap is not a valid attribute for a {} evaporator".
                 format(type(self.evap)))
            return nan

    @property
    def pptdEvap(self):
        return self._pptdEvap()
    
    @pptdEvap.setter
    def pptdEvap(self, value):
        if issubclass(type(self.evap), HxBasic):
            state20 = self.wf.copyUpdateState(PQ_INPUTS, self.pEvap, 0)
            if self.superheat == 0:# or self.superheat is None:
                state3 = self.wf.copyUpdateState(PQ_INPUTS, self.pEvap, 1)
            else:
                state3 = self.wf.copyUpdateState(PT_INPUTS, self.pEvap,
                                      self._TEvap() + self.superheat)
            source20 = self._sourceIn().copyUpdateState(PT_INPUTS,
                                          self._sourceIn().p(),
                                          state20.T() + value)

            m20 = self.evap.efficiencyThermal * self._sourceIn().m * (
                self._sourceIn().h() - source20.h()) / (state3.h() - state20.h())
            # check if pptd should be at state1
            if (source20.m / m20) < (state20.cp() / source20.cp()):
                if self.subcool == 0:# or self.subcool is None:
                    state6 = self.wf.copyUpdateState(PQ_INPUTS, self.pCond, 0)
                else:
                    state6 = self.wf.copyUpdateState(PT_INPUTS, self.pCond,
                                          self.TCond - self.subcool)
                state1s = self.wf.copyUpdateState(PSmass_INPUTS, self.pEvap,
                                       state6.s())
                h1 = state6.h() + (state1s.h() - state6.h()
                                   ) / self.comp.efficiencyIsentropic
                state1 = self.wf.copyUpdateState(HmassP_INPUTS, h1, self.pEvap)
                source1 = self.sourceIn.copyUpdateState(PT_INPUTS,
                                             self.sourceIn.p(),
                                             state1.T() + value)
                m1 = self.evap.efficiencyThermal * self.sourceIn.m * (
                    self.sourceIn.h() - source1.h()) / (
                        state3.h() - state1.h())
                # check
                h20 = source1.h() + m1 * (
                    state20.h() - state1.h()
                ) / self.sourceIn.m / self.evap.efficiencyThermal
                source20.updateState(HmassP_INPUTS, h20, self.sourceIn.p())
                if source20.T() < state20.T():  # assumption was wrong or error
                    self.wf.m = m20
                else:
                    self.wf.m = m1
            else:
                self.wf.m = m20
        else:
            print("pptdEvap is not a valid attribute for a {0} evaporator".
                  format(type(self.evap)))

    @property
    def pptdCond(self):
        """float: Pinch-point temperature difference of condenser"""
        if issubclass(type(self.cond), HxBasic):
            if self.cond.flowConfig.sense == COUNTERFLOW:

                if self.state4 and self.state51 and self.sink4 and self.sink51:
                    return min(self.state51.T() - self.sink51.T(),
                               self.state4.T() - self.sink4.T())

                else:
                    print("run() or size() has not been executed")
            else:
                print("pptdEvap is not a valid for flowConfig.sense = {0}".format(self.evap.flowConfig.sense))
        else:
            print("pptdEvap is not a valid attribute for a {0} condenser".
                  format(type(self.cond)))

    @pptdCond.setter
    def pptdCond(self, value):
        if issubclass(type(self.cond), HxBasic):
            pass  # TODO
        else:
            print("pptdEvap is not a valid attribute for a {0} condenser".
                  format(type(self.cond)))

    cpdef public void run(self) except *:
        """Compute all state FlowStates from initial FlowState and given component definitions.
        """
        state6new = None
        cdef double diffAbs = self.config.tolAbs * 10 # set to large value
        cdef double diffRel = self.config.tolRel * 10 # set to large value
        cdef int count = 0
        if self.comp.flowsIn[0] is None and self.evap.flowsIn[0] is None and self.exp.flowsIn[0] is None and self.cond.flowsIn[0] is None:
            msg = "All incoming component working fluid flowstates are None: one must be initialised to execute run()"
            log("error", msg)
            raise ValueError(msg)
        while diffRel > self.config.tolRel and diffAbs > self.config.tolAbs:
            if count == 0 and self.comp.flowsIn[0] is None:
                pass
            else:
                self.comp.run()
                self.set_state1(self.comp.flowsOut[0])
            if count == 0 and self.evap.flowsIn[0] is None:
                pass
            else:
                self.evap.run()
                self.set_state3(self.evap.flowsOut[0])
                if len(self.evap.flowsIn) > 1:
                    self.set_sourceOut(self.evap.flowsOut[1])
                if hasattr(self.evap, "unitise"): #this should be in Hx.run() logic
                    self.evap.unitise()
                    self.evap.size_L()
                if self.config.dpEvap is True:
                    try:
                        dp = self.evap.dpWf()
                        if dp < self.state3.p():
                            self.state3.updateState(HmassP_INPUTS,
                                               self.state3.h(),
                                               self.state3.p() - dp)
                        else:
                            ValueError(
                                """Evaporator pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                                format(dp, self.state3.p()))
                    except Exception as exc:
                        log("warning", "RankineBasic.run(); pressure drop in working fluid across evaporator ignored", exc_info=exc)
            if count == 0 and self.exp.flowsIn[0] is None:
                pass
            else:
                self.exp.run()
                self.set_state4(self.exp.flowsOut[0])
            if count == 0 and self.cond.flowsIn[0] is None:
                pass
            else:
                self.cond.run()
                state6new = self.cond.flowsOut[0]
                if len(self.cond.flowsIn) > 1:
                    self.set_sinkOut(self.cond.flowsOut[1])
                if hasattr(self.cond, "unitise"):
                    self.cond.unitise()
                if self.config.dpCond is True:
                    try:
                        #self.cond.size()
                        dp = self.cond.dpWf()
                        if dp < state6new.p():
                            state6new.updateState(HmassP_INPUTS,
                                             state6new.h(), state6new.p() - dp)
                        else:
                            raise ValueError(
                                """Condenser pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                                format(dp, state6new.p()))
                    except Exception as exc:
                        log("warning", "RankineBasic.run(); pressure drop in working fluid across condenser ignored", exc_info=exc)
            if count == 0 and self.comp.flowsIn[0] is None:
                pass
            else:
                diffAbs = abs(
                getattr(self.state6, self.config.tolAttr)() - getattr(
                    state6new, self.config.tolAttr)())
                diffRel = diffAbs / getattr(self.state6, self.config.tolAttr)()
            self.set_state6(state6new)
            count += 1
            if count > self.config.maxIterCycle:
                msg = """{0} iterations without {1} converging: diffRel={2}>tol={3}""".format(self.config.maxIterCycle, self.config.tolAttr,
                                                                                              diffRel, self.config.tolRel)
                log("error", msg)
                raise StopIteration(msg)
    
    cpdef public void sizeSetup(self, bint unitiseEvap, bint unitiseCond):
        """Impose the design parameters on the cycle (without executing .size() for each component).

Parameters
-----------
unitiseEvap : bool
    If True, the evap.unitise() is called if possible.
unitiseCond : bool
    If True, cond.unitise() is called if possible.
"""
        if self.subcool == 0:
            self.set_state6(self.wf.copyUpdateState(PQ_INPUTS, self.pCond, 0))
        else:
            self.set_state6(self.wf.copyUpdateState(PT_INPUTS, self.pCond,self._TCond() - self.subcool))
        #
        cdef FlowState state1_s = self.wf.copyUpdateState(PSmass_INPUTS, self.pEvap, self._state6().s())
        cdef double hOut = self._state6().h() + (state1_s.h() - self._state6().h()
                                  ) / self.comp.efficiencyIsentropic

        self.set_state1(self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pEvap))
        #
        if self.superheat == 0:
            self.set_state3(self.wf.copyUpdateState(PQ_INPUTS, self.pEvap, 1))
        else:
            self.set_state3(self.wf.copyUpdateState(PT_INPUTS, self.pEvap,
                                       self._TEvap() + self.superheat))
        #
        cdef FlowState state4_s = self.wf.copyUpdateState(PSmass_INPUTS, self.pCond, self._state3().s())
        hOut = self.state3.h() + (state4_s.h() - self._state3().h()
                                  ) * self.exp.efficiencyIsentropic
        self.set_state4(self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pCond))
        #
        if issubclass(type(self.evap), HxBasic):
            hOut = self.evap.flowsIn[1].h() - self._mWf() * self.evap._efficiencyFactorWf(
            ) * (self.evap.flowsOut[0].h() - self.evap.flowsIn[0].h()
                 ) / self.evap._mSf() / self.evap._efficiencyFactorSf()
            self.evap.flowsOut[1] = self.evap.flowsIn[1].copyUpdateState(
                HmassP_INPUTS, hOut, self.evap.flowsIn[1].p())
            if unitiseEvap:
                self.evap.unitise()
        if issubclass(type(self.cond), HxBasic):
            hOut = self.cond.flowsIn[1].h() - self._mWf() * self.cond._efficiencyFactorWf(
            ) * (self.cond.flowsOut[0].h() - self.cond.flowsIn[0].h()
                 ) / self.cond._mSf() / self.cond._efficiencyFactorSf()
            self.cond.flowsOut[1] = self.cond.flowsIn[1].copyUpdateState(
                HmassP_INPUTS, hOut, self.cond.flowsIn[1].p())
            if unitiseCond:
                self.cond.unitise()

    cpdef public void size(self) except *:
        """Impose the design parameters on the cycle and execute .size() for each component."""
        if self.subcool == 0:
            self.set_state6(self.wf.copyUpdateState(PQ_INPUTS, self.pCond, 0))
        else:
            self.set_state6(self.wf.copyUpdateState(PT_INPUTS, self.pCond,
                                       self._TCond() - self.subcool))
        #
        cdef double diff, cycle_diff = self.config.tolAbs * 5
        cdef double deltaHCond, deltaHEvap
        cdef int count, cycle_count = 0
        cdef FlowState state1_old, state4_old, state4_s
        cdef FlowState state6_old = self._state6().copy()
        cdef str msg
        while cycle_diff > self.config.tolAbs:
            diff = self.config.tolAbs * 5
            count = 0
            state1_s = self.wf.copyUpdateState(PSmass_INPUTS, self.pEvap,
                                    self.state6.s())
            hOut = self._state6().h() + (state1_s.h() - self._state6().h()
                                      ) / self.comp.efficiencyIsentropic
            state1_old = self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pEvap)
            while diff > self.config.tolAbs:
                self.comp.flowsOut[0] = state1_old
                self.comp.size()
                """
                hOut = self.state6.h() + (
                    state1_s.h() - self.state6.h()) / self.comp.efficiencyIsentropic
                self.state1 = self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pEvap)
                """
                self.comp.run()
                diff = abs(
                    getattr(self.comp.flowsOut[0], self.config.tolAttr)() -
                    getattr(state1_old,
                            self.config.tolAttr)())  # TODO proper tolerancing
                state1_old = self.comp.flowsOut[0]
                count += 1
                if count > self.config.maxIterCycle:
                    raise StopIteration(
                        """{0} iterations without {1} compressor converging: diff={2}>tol={3}""".
                        format(self.config.maxIterCycle, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.comp.size()
            self.set_state1(self.comp.flowsOut[0])
            #
            if self.superheat == 0:
                self.set_state3(self.wf.copyUpdateState(PQ_INPUTS, self.pEvap, 1))
            else:
                self.set_state3(self.wf.copyUpdateState(PT_INPUTS, self.pEvap,
                                           self._TEvap() + self.superheat))
            if issubclass(type(self.evap), HxBasic):
                deltaHEvap = (self._state3().h() - self._state1().h()
                              ) * self.evap._mWf() * self.evap._efficiencyFactorWf()
                self.evap.flowsOut[1] = self.evap.flowsIn[1].copyUpdateState(
                    HmassP_INPUTS,
                    self.evap.flowsIn[1].h() - deltaHEvap / self.evap._mSf() /
                    self.evap._efficiencyFactorSf(), self.evap.flowsIn[1].p())
            self.evap.size()
            if self.config.dpEvap is True:
                try:
                    # self.evap.size()
                    dp = self.evap.dpWf()
                    if dp < self._state3().p():
                        self._state3().updateState(HmassP_INPUTS,
                                           self._state3().h(),
                                           self._state3().p() - dp)
                    else:
                        raise ValueError(
                            """Pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, self._state3().p()))
                except ValueError as exc:
                    msg = "RankineBasic.size(), pressure drop in working fluid across evaporator ignored"
                    log("warning", msg, exc_info=exc)
            self.set_state3(self.evap.flowsOut[0])
            #
            diff = self.config.tolAbs * 5
            count = 0
            state4_s = self.wf.copyUpdateState(PSmass_INPUTS, self.pCond,
                                    self.state3.s())
            hOut = self.state3.h() + (state4_s.h() - self.state3.h()
                                      ) * self.exp.efficiencyIsentropic
            state4_old = self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pCond)
            while diff > self.config.tolAbs:
                self.exp.flowsOut[0] = state4_old
                self.exp.size()
                """
                hOut = self.state3.h() + (
                    state4_s.h() - self.state3.h()) / self.exp.efficiencyIsentropic
                self.state4 = self.wf.copyUpdateState(HmassP_INPUTS, hOut, self.pCond)
                """
                self.exp.run()
                diff = abs(
                    getattr(self.exp.flowsOut[0], self.config.tolAttr)() -
                    getattr(state4_old, self.config.tolAttr)())
                state4_old = self.exp.flowsOut[0]
                count += 1
                if count > self.config.maxIterCycle:
                    raise StopIteration(
                        """{0} iterations without {1} expander converging: diff={2}>tol={3}""".
                        format(self.config.maxIterCycle, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.exp.size()
            self.set_state4(self.exp.flowsOut[0])
            #
            if issubclass(type(self.cond), HxBasic):
                deltaHCond = (self._state4().h() - self._state6().h()
                              ) * self.cond._mWf() * self.cond._efficiencyFactorWf()
                self.cond.flowsOut[1] = self.cond.flowsIn[1].copyUpdateState(
                    HmassP_INPUTS,
                    self.cond.flowsIn[1].h() + deltaHCond / self.cond._mSf() /
                    self.cond._efficiencyFactorSf(), self.cond.flowsIn[1].p())
            self.cond.size()
            if self.config.dpCond is True:
                try:
                    dp = self.cond.dpWf()
                    if dp < self._state6().p():
                        self._state6().updateState(HmassP_INPUTS,
                                           self._state6().h(),
                                           self._state6().p() - dp)
                    else:
                        raise ValueError(
                            """Pressure drop of working fluid in condenser is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state6.p()))
                except ValueError as exc:
                    msg = "RankineBasic.size(), pressure drop in working fluid across condenser ignored"
                    log("warning", msg, exc_info=exc)
            self.set_state6(self.cond.flowsOut[0])
            cycle_diff = getattr(self.state6, self.config.tolAttr)() - getattr(
                state6_old, self.config.tolAttr)()
            state6_old = self._state6().copy()
            cycle_count += 1
            if count > self.config.maxIterCycle:
                msg = """{0} iterations without {1} cycle converging: diff={2}>tol={3}""".format(self.config.maxIterCycle, self.config.tolAttr, diff,
                           self.config.tolAbs)
                log('warning', msg)
                raise StopIteration(msg)


    def plot(self,
             graph='Ts',
             title='RankineBasic plot',
             satCurve=True,
             newFig=True,
             show=True,
             savefig=False,
             savefig_name='plot_RankineBasic',
             savefig_folder='default',
             savefig_format='default',
             savefig_dpi='default',
             linestyle='-',
             marker='.'):
        """Plots the key cycle FlowStates on a T-s or p-h diagram.

Parameters
-----------
graph : str, optional
    Type of graph to plot. Must be 'Ts' or 'ph'. Defaults to 'Ts'.
title : str, optional
    Title to display on graph. Defaults to 'RankineBasic plot'.
satCurve : bool, optional
    Display saturation curve. Defaults to True.
newFig : bool, optional
    Create new figure (else plot on existing figure). Defaults to True.
show : str, optional
    Show figure in window. Defaults to True.
savefig : bool, optional
    Save figure as '.png' or '.jpg' file in desired folder. Defaults to False.
savefig_name : str, optional
    Name for saved plot file. Defaults to 'plot_RankineBasic'.
savefig_folder : str, optional
    Folder in the current working directory to save figure into. Folder is created if it does not already exist. Figure is saved as "./savefig_folder/savefig_name.savefig_format". If None or '', figure is saved directly into the current working directory. If ``'default'``, :meth:`mcycle.defaults.PLOT_DIR <mcycle.defaults.PLOT_DIR>` is used. Defaults to ``'default'``.
savefig_format : str, optional
    Format of saved plot file. Must be ``'png'`` or ``'jpg'``. If ``'default'``, :meth:`mcycle.defaults.PLOT_FORMAT <mcycle.defaults.PLOT_FORMAT>` is used. Defaults to ``'default'``.
savefig_dpi : int, optional
    Dots per inch / pixels per inch of the saved image. Passed as a matplotlib.plot argument. If ``'default'``, :meth:`mcycle.defaults.PLOT_DPI <mcycle.defaults.PLOT_DPI>` is used. Defaults to ``'default'``.
linestyle : str, optional
    Style of line used for working fluid plot points. Passed as a matplotlib.plot argument. Defaults to '-'.
marker : str, optional
    Marker style used for working fluid plot poitns. Passed as a matplotlib.plot argument. Defaults to '.'.
        """
        import matplotlib
        import matplotlib.pyplot as plt
        assert savefig_format in ['default',
            'png', 'PNG', 'jpg', 'JPG'
        ], "savefig format must be 'png' or 'jpg', '{0}' is invalid.".format(
            savefig_format)
        xlabel = ''
        ylabel = ''
        xvalsState = []
        yvalsState = []
        xvalsSource = []
        yvalsSource = []
        xvalsSink = []
        yvalsSink = []
        if graph == 'Ts':
            x = "s"
            y = "T"
            xlabel = 's [J/kg.K]'
            ylabel = 'T [K]'
            title = title
        elif graph == 'ph':
            x = "h"
            y = "p"
            xlabel = 'h [J/kg]'
            ylabel = 'p [Pa]'
            title = title
        #
        plotStates = []
        for key in self._cycleStateKeys:
            if not key.startswith("state"):
                key = "state" + key
            plotStates.append(getattr(self, key))
        if self.state20.h() < self.state1.h():
            plotStates.remove(self.state20)
        if self.state21.h() > self.state3.h():
            plotStates.remove(self.state21)
        if self.state51.h() > self.state4.h():
            plotStates.remove(self.state51)
        if self.state50.h() < self.state6.h():
            plotStates.remove(self.state50)
        #
        plotSource = []
        if issubclass(type(self.evap), HxBasic):
            plotSource = [[self.state1,
                           self.source1], [self.state20, self.source20],
                          [self.state21,
                           self.source21], [self.state3, self.source3]]
            if self.evap.flowConfig.sense == COUNTERFLOW:
                if self.source20.h() < self.source1.h():
                    plotSource.remove([self.state20, self.source20])
                if self.source21.h() > self.source3.h():
                    plotSource.remove([self.state21, self.source21])
            else:
                if self.source20.h() > self.source1.h():
                    plotSource.remove([self.state20, self.source20])
                if self.source21.h() < self.source3.h():
                    plotSource.remove([self.state21, self.source21])
        else:
            pass
        #
        plotSink = []
        if issubclass(type(self.cond), HxBasic):
            plotSink = [[self.state6, self.sink6], [self.state50, self.sink50],
                        [self.state51, self.sink51], [self.state4, self.sink4]]
            if self.cond.flowConfig.sense == COUNTERFLOW:
                if self.sink51.h() > self.sink4.h():
                    plotSink.remove([self.state51, self.sink51])
                if self.sink50.h() < self.sink6.h():
                    plotSink.remove([self.state50, self.sink50])
            else:
                if self.sink51.h() < self.sink4.h():
                    plotSink.remove([self.state51, self.sink51])
                if self.sink50.h() > self.sink6.h():
                    plotSink.remove([self.state50, self.sink50])
        else:
            pass
        #
        for flowstate in plotStates:
            xvalsState.append(getattr(flowstate, x)())
            yvalsState.append(getattr(flowstate, y)())
        for flowstate in plotSource:
            xvalsSource.append(getattr(flowstate[0], x)())
            yvalsSource.append(getattr(flowstate[1], y)())
        for flowstate in plotSink:
            xvalsSink.append(getattr(flowstate[0], x)())
            yvalsSink.append(getattr(flowstate[1], y)())
        if newFig is True:
            plt.figure()
        plt.plot(
            xvalsState,
            yvalsState,
            color='k',
            linestyle=linestyle,
            marker=marker)
        plt.plot(
            xvalsSource,
            yvalsSource,
            color='r',
            linestyle=linestyle,
            marker=marker)
        plt.plot(
            xvalsSink,
            yvalsSink,
            color='b',
            linestyle=linestyle,
            marker=marker)
        if satCurve is True:
            sc = saturationCurve(self.wf.fluid)
            plt.plot(sc[x], sc[y], 'g--')
        #
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.title(title)
        plt.grid(True)
        if savefig is True:
            if savefig_folder == 'default':
                savefig_folder = defaults.PLOT_DIR
            if savefig_format == 'default':
                savefig_format = defaults.PLOT_FORMAT
            if savefig_dpi == 'default':
                savefig_dpi = defaults.PLOT_DPI
            folder = defaults.makePlotDir(savefig_folder)
            plt.savefig(
                "{}/{}.{}".format(folder, savefig_name, savefig_format),
                dpi=savefig_dpi,
                bbox_inches='tight')
        if show is True:
            plt.show()
