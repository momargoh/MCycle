from ..DEFAULTS cimport COOLPROP_EOS, PLOT_DIR, PLOT_FORMAT, PLOT_DPI, MAXITER_CYCLE
from ..bases.config cimport Config
from ..bases.cycle cimport Cycle
from ..bases.component cimport Component
from ..bases.flowstate cimport FlowState
from ..bases.mcabstractbase cimport MCAttr
from ..components.hxs.hx_basic cimport HxBasic
from math import nan, isnan
import numpy as np
import CoolProp as CP
from warnings import warn


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
    Cycle configuration parameters.
kwargs : optional
    Arbitrary keyword arguments.
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
                 Config config=Config()):
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
                         ("1", "20", "21", "3", "4", "51", "50", "6"), config)
        self.config = config  # use setter to set for all components
        self._inputs =  {"wf": MCAttr(FlowState, "none"), "evap": MCAttr(Component, "none"), "exp": MCAttr(Component, "none"),
                "cond": MCAttr(Component, "none"), "comp": MCAttr(Component, "none"), "pEvap": MCAttr(float, "pressure"),
                "superheat": MCAttr(float, "temperature"), "pCond": MCAttr(float, "pressure"),
                "subcool": MCAttr(float, "temperature"), "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time"), "QIn()": MCAttr(float, "power"), "QOut()": MCAttr(float, "power"),
                "PIn()": MCAttr(float, "power"), "POut()": MCAttr(float, "power"),
                "effThermal()": MCAttr(float, "none"), "effExergy()": MCAttr(float, "none"),
                "IComp()": MCAttr(float, "power"), "IEvap()": MCAttr(float, "power"),
                "IExp()": MCAttr(float, "power"), "ICond()": MCAttr(float, "power")}

    cpdef public void update(self, dict kwargs):
        """Update (multiple) Cycle variables using keyword arguments."""
        cdef str key
        cdef list keySplit
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
                if "__" in key:
                    key_split = key.split("__", 1)
                    key_attr = getattr(self, key_split[0])
                    key_attr.update({key_split[1]: value})
                else:
                    try:
                        setter = getattr(self, 'set_{}'.format(key))
                        setter(value)
                    except:
                        setattr(self, key, value)

    cpdef public double _mWf(self):
        return self.wf.m
    
    @property
    def mWf(self):
        """float: Alias of wf.m; mass flow rate of the working fluid [Kg/s]."""
        return self.wf.m

    @mWf.setter
    def mWf(self, value):
        self.wf.m = value

    cpdef public double _TCond(self):
        cdef FlowState sat = self.wf.copyState(CP.PQ_INPUTS, self.pCond, 0)
        return sat.T()
    
    cpdef public void set_TCond(self, double TCond):
        cdef FlowState sat = self.wf.copyState(CP.QT_INPUTS, 0, TCond)
        self.pCond = sat.p()
    
    @property
    def TCond(self):
        """float: Evaporation temperature of the working fluid in the compressor [K]."""
        return self._TCond()

    @TCond.setter
    def TCond(self, value):
        self.pCond = CP.CoolProp.PropsSI('P', 'T', value, 'Q', 0,
                                         COOLPROP_EOS + "::" + self.wf.fluid)

    cpdef public double _TEvap(self):
        return self.wf.copyState(CP.PQ_INPUTS, self.pEvap, 0).T()
    
    cpdef public void set_TEvap(self, double TEvap):
        cdef FlowState sat = self.wf.copyState(CP.QT_INPUTS, 0, TEvap)
        self.pEvap = sat.p()

    @property
    def TEvap(self):
        """float: Evaporation temperature of the working fluid in the evaporator [K]."""
        return CP.CoolProp.PropsSI('T', 'P', self.pEvap, 'Q', 0,
                                   COOLPROP_EOS + "::" + self.wf.fluid)

    @TEvap.setter
    def TEvap(self, value):
        self.pEvap = CP.CoolProp.PropsSI('P', 'T', value, 'Q', 0,
                                         COOLPROP_EOS + "::" + self.wf.fluid)
        
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
        self.pEvap = self.pComp * value
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
        return self.wf.copyState(CP.PQ_INPUTS, self.evap.flowsIn[0].p(), 0)
    
    cpdef public FlowState _state21(self):
        return self.wf.copyState(CP.PQ_INPUTS, self.evap.flowsIn[0].p(), 1)

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
        return self.wf.copyState(CP.PQ_INPUTS, self.cond.flowsIn[0].p(), 0)
    
    cpdef public FlowState _state51(self):
        return self.wf.copyState(CP.PQ_INPUTS, self.cond.flowsIn[0].p(), 1)

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
        return self.evap.flowsIn[1]
    
    cpdef public void set_sourceIn(self, FlowState obj):
        self.evap.flowsIn[1] = obj

    cpdef public FlowState _sourceOut(self):
        return self.evap.flowsOut[1]
    
    cpdef public void set_sourceOut(self, FlowState obj):
        self.evap.flowsOut[1] = obj

    cpdef public FlowState _source1(self):
        if "counter" in self.evap.flowSense.lower():
            return self._sourceOut()
        elif "parallel" in self.evap.flowSense.lower():
            return self._sourceIn()
        else:
            return None

    cpdef public FlowState _source20(self):
        cdef double h
        if "counter" in self.evap.flowSense.lower():
            h = self._source1().h() + self._mWf() * self.evap._effFactorWf() * (
                self._state20().h() - self._state1().h()
            ) / self._source1().m / self.evap._effFactorSf()
        elif "parallel" in self.evap.flowSense.lower():
            h = self._source1().h() - self._mWf() * self.evap._effFactorWf() * (
                self._state20().h() - self._state1().h()
            ) / self._source1().m / self.evap._effFactorSf()
        else:
            return None
        return self._sourceIn().copyState(CP.HmassP_INPUTS, h, self._sourceIn().p())

    cpdef public FlowState _source21(self):
        cdef double h
        if "counter" in self.evap.flowSense.lower():
            h = self._source1().h() + self._mWf() * self.evap._effFactorSf() * (
                self._state21().h() - self._state1().h()
            ) / self._sourceIn().m / self.evap._effFactorSf()
        elif "parallel" in self.evap.flowSense.lower():
            h = self._source1().h() - self._mWf() * self.evap._effFactorWf() * (
                self._state21().h() - self._state1().h()
            ) / self._sourceIn().m / self.evap._effFactorSf()
        else:
            return None
        return self._sourceIn().copyState(CP.HmassP_INPUTS, h, self._sourceIn().p())

    cpdef public FlowState _source3(self):
        if "counter" in self.evap.flowSense.lower():
            return self._sourceIn()
        elif "parallel" in self.evap.flowSense.lower():
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
        return self.cond.flowsIn[1]

    cpdef public void set_sinkIn(self, FlowState obj):
        self.cond.flowInSf = obj

    cpdef public FlowState _sinkOut(self):
        return self.cond.flowsOut[1]

    cpdef public void set_sinkOut(self, FlowState obj):
        self.cond.flowsOut[1] = obj

    cpdef public FlowState _sink4(self):
        if self.cond.flowSense == "counterflow":
            return self._sinkOut()
        elif self.cond.flowSense == "parallel":
            return self._sinkIn()
        else:
            return None
        
    cpdef public FlowState _sink6(self):
        if "counter" in self.cond.flowSense.lower():
            return self._sinkIn()
        elif "parallel" in self.cond.flowSense.lower():
            return self._sinkOut()
        else:
            return None
    
    cpdef public FlowState _sink50(self):
        cdef double h
        if "counter" in self.cond.flowSense.lower():
            h = self._sink4().h() - self._mWf() * self.cond._effFactorWf() * (
                self._state4().h() - self._state50().h()
            ) / self._sink4().m / self.cond._effFactorSf()
        elif "parallel" in self.cond.flowSense.lower():
            h = self._sink4().h() + self._mWf() * self.cond._effFactorWf() * (
                self._state4().h() - self._state50().h()
            ) / self._sink4().m / self.cond._effFactorSf()
        else:
            return None
        return self._sinkIn().copyState(CP.HmassP_INPUTS, h, self._sinkIn().p())

    cpdef public FlowState _sink51(self):
        cdef double h
        if "counter" in self.cond.flowSense.lower():
            h = self._sink4().h() - self._mWf() * self.cond._effFactorWf() * (
                self._state4().h() - self._state51().h()
            ) / self._sink4().m / self.cond._effFactorSf()
        elif "parallel" in self.cond.flowSense.lower():
            h = self._sink4().h() + self._mWf() * self.cond._effFactorWf() * (
                self._state4().h() - self._state51().h()
            ) / self._sink4().m / self.cond._effFactorSf()
        else:
            return None
        return self._sinkIn().copyState(CP.HmassP_INPUTS, h, self()._sinkIn.p())

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
        self._sink51()

    @property
    def sink6(self):
        """FlowState: Heat sink when working fluid is at state6. Only valid with a secondary flow as the heat sink."""
        self._sink6()

    @property
    def sinkAmbient(self):
        """FlowState: Alias of cond.ambient. Only valid with a secondary flow as the heat sink."""
        return self._sinkAmbient()

    @sinkAmbient.setter
    def sinkAmbient(self, obj):
        self.set_sinkAmbient(obj)


    cpdef public double QIn(self):
        """float: Heat input (from evaporator) [W]."""
        return self.evap._Q() #self._mWf() * (self.state3.h() - self.state1.h())

    cpdef public double QOut(self):
        """float: Heat output (from condenser) [W]."""
        return self.cond._Q() #self._mWf() * (self.state4.h() - self.state6.h())

    cpdef public double PIn(self):
        """float: Power input (from compressor) [W]."""
        return self.comp._PIn()  #self._mWf() * (self.state1.h() - self.state6.h())

    cpdef public double POut(self):
        """float: Power output (from expander) [W]."""
        return self.exp._POut()  # self._mWf() * (self.state3.h() - self.state4.h())

    cpdef public double PNet(self):
        """float: Net power output [W].
        PNet = POut() - PIn()"""
        return self.POut() - self.PIn()

    cpdef public double effThermal(self):
        """float: Cycle thermal efficiency [-]
        effThermal = PNet/QIn"""
        return self.PNet() / self.QIn()

    cpdef public double effRecovery(self):
        """float: Exhaust heat recovery efficiency"""
        return (self._sourceIn().h() - self._sourceOut().h()) / (
            self._sourceIn().h() - self._sourceAmbient().h())

    cpdef public double effExergy(self):
        """float: Exergy efficiency"""
        return self.PNet() / self._sourceIn().m / (
            self._sourceIn().h() - self._sourceAmbient().h())

    cpdef public double effGlobal(self):
        """float: Global recovery efficiency"""
        return self.effThermal() * self.effExergy()

    cpdef public double IComp(self):
        """float: Exergy destruction of compressor [W]"""
        return self._sinkAmbient().T() * self._mWf() * (
            self._state1().s() - self._state50().s())

    cpdef public double IEvap(self):
        """float: Exergy destruction of evaporator [W]"""
        cdef FlowState ambientSource
        try:
            ambientSource = self._sourceIn().copyState(CP.PT_INPUTS, self._sourceAmbient.p(), self._sourceAmbient().T())
        except Exception as exc:
            warn("Could not create evaporator source flow at ambient conditions. Returned 0. "+exc)
            return 0
        cdef double I_13 = ambientSource.T() * (
            self._mWf() * (self._state3().s() - self._state1().s()) + self._sourceIn().m *
            (self._source1().s() - self._sourceIn().s()))
        cdef double I_C0 = ambientSource.T() * self._sourceIn().m * (
            (ambientSource.s() - self._source1().s()) +
            (self._source1().h() - ambientSource.h()) / ambientSource.T())
        return I_13 + I_C0

    cpdef public double IExp(self):
        """float: Exergy destruction of expander [W]"""
        return self._sinkAmbient().T() * self._mWf() * (
            self._state4().s() - self._state3().s())

    cpdef public double ICond(self):
        """float: Exergy destruction of condenser [W]"""
        return self._sinkAmbient().T() * self._mWf() * (
            (self._state50().s() - self._state4().s()) +
            (self._state4().h() - self._state50().h()) / self._sinkAmbient().T())

    cpdef public double ITotal(self):
        """float: Total exergy destruction of cycle [W]"""
        return self.IComp() + self.IEvap() + self.IExp() + self.ICond()
    
    cpdef public double _pptdEvap(self):
        """float: Pinch-point temperature difference of evaporator"""
        if issubclass(type(self.evap), HxBasic):
            if "counter" in self.evap.flowSense.lower():
                if self._state1() and self._state20() and self._source1() and self._source20():
                    return min(self._source20().T() - self._state20().T(),
                               self._source1().T() - self._state1().T())

                else:
                    warn("run() or size() has not been executed")
            else:
                warn("pptdEvap is not a valid for flowSense = {}".format(
                    type(self.evap.flowSense)))
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
            state20 = self.wf.copyState(CP.PQ_INPUTS, self.pEvap, 0)
            if self.superheat == 0 or self.superheat is None:
                state3 = self.wf.copyState(CP.PQ_INPUTS, self.pEvap, 1)
            else:
                state3 = self.wf.copyState(CP.PT_INPUTS, self.pEvap,
                                      self._TEvap() + self.superheat)
            source20 = self._sourceIn().copyState(CP.PT_INPUTS,
                                          self._sourceIn().p(),
                                          state20.T() + value)

            m20 = self.evap.effThermal * self._sourceIn().m * (
                self._sourceIn().h() - source20.h()) / (state3.h() - state20.h())
            # check if pptd should be at state1
            if (source20.m / m20) < (state20.cp() / source20.cp()):
                if self.subcool == 0 or self.subcool is None:
                    state6 = self.wf.copyState(CP.PQ_INPUTS, self.pCond, 0)
                else:
                    state6 = self.wf.copyState(CP.PT_INPUTS, self.pCond,
                                          self.TCond - self.subcool)
                state1s = self.wf.copyState(CP.PSmass_INPUTS, self.pEvap,
                                       state6.s())
                h1 = state6.h() + (state1s.h() - state6.h()
                                   ) / self.comp.effIsentropic
                state1 = self.wf.copyState(CP.HmassP_INPUTS, h1, self.pEvap)
                source1 = self.sourceIn.copyState(CP.PT_INPUTS,
                                             self.sourceIn.p(),
                                             state1.T() + value)
                m1 = self.evap.effThermal * self.sourceIn.m * (
                    self.sourceIn.h() - source1.h()) / (
                        state3.h() - state1.h())
                # check
                h20 = source1.h() + m1 * (
                    state20.h() - state1.h()
                ) / self.sourceIn.m / self.evap.effThermal
                source20.updateState(CP.HmassP_INPUTS, h20, self.sourceIn.p())
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
            if "counter" in self.cond.flowSense.lower():

                if self.state4 and self.state51 and self.sink4 and self.sink51:
                    return min(self.state51.T() - self.sink51.T(),
                               self.state4.T() - self.sink4.T())

                else:
                    print("run() or size() has not been executed")
            else:
                print("pptdEvap is not a valid for flowSense = {0}".format(
                    type(self.evap.flowSense)))
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

    def run(self, component='', flowState=None):
        """Compute all state FlowStates from initial FlowState and given component definitions

Parameters
----------
flowState : FlowState, optional
        An initial working fluid FlowState. Defaults to None. If None, will search components (beginning with comp) for a non None flowIn.
component: str, optional
        Component for which flowState is set as flowInWf. Defaults to None.
        """
        # TODO sort out tolerancing
        state6new = None
        diff = self.config.tolAbs * 5
        count = 0
        while diff > self.config.tolAbs:
            self.comp.run()
            self.state1 = self.comp.flowsOut[0]
            self.evap.run()
            self.set_sourceOut(self.evap.flowsOut[1])
            self.set_state3(self.evap.flowsOut[0])
            self.evap.unitise()
            if self.config.dpEvap is True:
                try:
                    self.evap.solve()
                    dp = self.evap.dpWf()
                    if dp < self.state3.p():
                        self.state3.updateState(CP.HmassP_INPUTS,
                                           self.state3.h(),
                                           self.state3.p() - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state3.p()))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across evaporator ignored"
                    )
            self.exp.run()
            self.set_state4(self.exp.flowsOut[0])
            self.cond.run()
            state6new = self.cond.flowsOut[0]
            self.set_sinkOut(self.cond.flowsOut[1])
            self.cond._unitise()
            if self.config.dpCond is True:
                try:
                    self.cond.solve()
                    dp = self.cond.dpWf()
                    if dp < state6new.p():
                        state6new.updateState(CP.HmassP_INPUTS,
                                         state6new.h(), state6new.p() - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, state6new.p()))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across condenser ignored"
                    )
            diff = abs(
                getattr(self.state6, self.config.tolAttr) - getattr(
                    state6new, self.config.tolAttr))
            self.set_state6(state6new)
            count += 1
            if count > self.config.maxIterationsCycle:
                raise StopIteration(
                    """{0} iterations without {1} converging: diff={2}>tol={3}""".
                    format(self.config.maxIterationsCycle, self.config.tolAttr,
                           diff, self.config.tolAbs))
    
    cpdef public void sizeSetup(self, bint unitiseEvap, bint unitiseCond):
        """Impose the design parameters on the cycle (without executing .size() for each component).

Parameters
-----------
unitiseEvap : bool, optional
    If True, the evap.unitise() is called if possible. Defaults to True.
unitiseCond : bool, optional
    If True, cond.unitise() is called if possible. Defaults to True.
"""
        if self.subcool == 0:
            self.set_state6(self.wf.copyState(CP.PQ_INPUTS, self.pCond, 0))
        else:
            self.set_state6(self.wf.copyState(CP.PT_INPUTS, self.pCond,self._TCond() - self.subcool))
        #
        cdef FlowState state1_s = self.wf.copyState(CP.PSmass_INPUTS, self.pEvap, self._state6().s())
        cdef double hOut = self._state6().h() + (state1_s.h() - self._state6().h()
                                  ) / self.comp.effIsentropic

        self.set_state1(self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pEvap))
        #
        if self.superheat == 0:
            self.set_state3(self.wf.copyState(CP.PQ_INPUTS, self.pEvap, 1))
        else:
            self.set_state3(self.wf.copyState(CP.PT_INPUTS, self.pEvap,
                                       self._TEvap() + self.superheat))
        #
        cdef FlowState state4_s = self.wf.copyState(CP.PSmass_INPUTS, self.pCond, self._state3().s())
        hOut = self.state3.h() + (state4_s.h() - self._state3().h()
                                  ) * self.exp.effIsentropic
        self.set_state4(self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pCond))
        #
        if issubclass(type(self.evap), HxBasic):
            hOut = self.evap.flowsIn[1].h() - self._mWf() * self.evap._effFactorWf(
            ) * (self.evap.flowsOut[0].h() - self.evap.flowsIn[0].h()
                 ) / self.evap._mSf() / self.evap._effFactorSf()
            self.evap.flowsOut[1] = self.evap.flowsIn[1].copyState(
                CP.HmassP_INPUTS, hOut, self.evap.flowsIn[1].p())
            if unitiseEvap:
                self.evap.unitise()
        if issubclass(type(self.cond), HxBasic):
            hOut = self.cond.flowsIn[1].h() - self._mWf() * self.cond._effFactorWf(
            ) * (self.cond.flowsOut[0].h() - self.cond.flowIn[0].h()
                 ) / self.cond._mSf() / self.cond._effFactor[1]()
            self.cond.flowsOut[1] = self.cond.flowsIn[1].copyState(
                CP.HmassP_INPUTS, hOut, self.cond.flowsIn[1].p())
            if unitiseCond:
                self.cond.unitise()

    cpdef public void size(self):
        """Impose the design parameters on the cycle and execute .size() for each component."""
        if self.subcool == 0:
            self.set_state6(self.wf.copyState(CP.PQ_INPUTS, self.pCond, 0))
        else:
            self.set_state6(self.wf.copyState(CP.PT_INPUTS, self.pCond,
                                       self._TCond() - self.subcool))
        #
        cdef double diff, cycle_diff = self.config.tolAbs * 5
        cdef double deltaHCond, deltaHEvap
        cdef int count, cycle_count = 0
        cdef FlowState state1_old, state4_old, state4_s
        cdef FlowState state6_old = self._state6().copy({})
        while cycle_diff > self.config.tolAbs:
            diff = self.config.tolAbs * 5
            count = 0
            state1_s = self.wf.copyState(CP.PSmass_INPUTS, self.pEvap,
                                    self.state6.s())
            hOut = self._state6().h() + (state1_s.h() - self._state6().h()
                                      ) / self.comp.effIsentropic
            state1_old = self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pEvap)
            while diff > self.config.tolAbs:
                self.comp.flowsOut[0] = state1_old
                self.comp.size()
                """
                hOut = self.state6.h() + (
                    state1_s.h() - self.state6.h()) / self.comp.effIsentropic
                self.state1 = self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pEvap)
                """
                self.comp.run()
                diff = abs(
                    getattr(self.comp.flowsOut[0], self.config.tolAttr)() -
                    getattr(state1_old,
                            self.config.tolAttr)())  # TODO proper tolerancing
                state1_old = self.comp.flowsOut[0]
                count += 1
                if count > MAXITER_CYCLE:
                    raise StopIteration(
                        """{0} iterations without {1} compressor converging: diff={2}>tol={3}""".
                        format(MAXITER_CYCLE, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.comp.size()
            self.set_state1(self.comp.flowsOut[0])
            #
            if self.superheat == 0:
                self.set_state3(self.wf.copyState(CP.PQ_INPUTS, self.pEvap, 1))
            else:
                self.set_state3(self.wf.copyState(CP.PT_INPUTS, self.pEvap,
                                           self._TEvap() + self.superheat))
            if issubclass(type(self.evap), HxBasic):
                deltaHEvap = (self._state3().h() - self._state1().h()
                              ) * self.evap._mWf() * self.evap._effFactorWf()
                self.evap.flowsOut[1] = self.evap.flowsIn[1].copyState(
                    CP.HmassP_INPUTS,
                    self.evap.flowsIn[1].h() - deltaHEvap / self.evap._mSf() /
                    self.evap._effFactorSf(), self.evap.flowsIn[1].p())
            self.evap.size()
            if self.config.dpEvap is True:
                try:
                    # self.evap.size()
                    dp = self.evap.dpWf()
                    if dp < self._state3().p():
                        self._state3().updateState(CP.HmassP_INPUTS,
                                           self._state3().h(),
                                           self._state3().p() - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, self._state3().p()))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across evaporator ignored"
                    )
            self.set_state3(self.evap.flowsOut[0])
            #
            diff = self.config.tolAbs * 5
            count = 0
            state4_s = self.wf.copyState(CP.PSmass_INPUTS, self.pCond,
                                    self.state3.s())
            hOut = self.state3.h() + (state4_s.h() - self.state3.h()
                                      ) * self.exp.effIsentropic
            state4_old = self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pCond)
            while diff > self.config.tolAbs:
                self.exp.flowsOut[0] = state4_old
                self.exp.size()
                """
                hOut = self.state3.h() + (
                    state4_s.h() - self.state3.h()) / self.exp.effIsentropic
                self.state4 = self.wf.copyState(CP.HmassP_INPUTS, hOut, self.pCond)
                """
                self.exp.run()
                diff = abs(
                    getattr(self.exp.flowsOut[0], self.config.tolAttr)() -
                    getattr(state4_old, self.config.tolAttr)())
                state4_old = self.exp.flowsOut[0]
                count += 1
                if count > MAXITER_CYCLE:
                    raise StopIteration(
                        """{0} iterations without {1} expander converging: diff={2}>tol={3}""".
                        format(MAXITER_CYCLE, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.exp.size()
            self.set_state4(self.exp.flowsOut[0])
            #
            if issubclass(type(self.cond), HxBasic):
                deltaHCond = (self._state4().h() - self._state6().h()
                              ) * self.cond._mWf() * self.cond._effFactorWf()
                self.cond.flowsOut[1] = self.cond.flowsIn[1].copyState(
                    CP.HmassP_INPUTS,
                    self.cond.flowsIn[1].h() + deltaHCond / self.cond._mSf() /
                    self.cond._effFactorSf(), self.cond.flowsIn[1].p())
            self.cond.size()
            if self.config.dpCond is True:
                try:
                    dp = self.cond.dpWf()
                    if dp < self._state6().p():
                        self._state6().updateState(CP.HmassP_INPUTS,
                                           self._state6().h(),
                                           self._state6().p() - dp)
                    else:
                        raise ValueError(
                            """pressure drop of working fluid in condenser is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state6.p()))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across condenser ignored"
                    )
            self.set_state6(self.cond.flowsOut[0])
            cycle_diff = getattr(self.state6, self.config.tolAttr)() - getattr(
                state6_old, self.config.tolAttr)()
            state6_old = self._state6().copy({})
            cycle_count += 1
            if count > MAXITER_CYCLE:
                raise StopIteration(
                    """{0} iterations without {1} cycle converging: diff={2}>tol={3}""".
                    format(MAXITER_CYCLE, self.config.tolAttr, diff,
                           self.config.tolAbs))


    def plot(self,
             graph='Ts',
             title='RankineBasic plot',
             linestyle='-',
             marker='.',
             satCurve=True,
             newFig=True,
             show=True,
             savefig=False,
             savefig_name='plot_RankineBasic',
             savefig_folder=PLOT_DIR,
             savefig_format=PLOT_FORMAT,
             savefig_dpi=PLOT_DPI):
        """Plots the key cycle FlowStates on a T-s or p-h diagram.

Parameters
-----------
graph : str, optional
    Type of graph to plot. Must be 'Ts' or 'ph'. Defaults to 'Ts'.
title : str, optional
    Title to display on graph. Defaults to 'RankineBasic plot'.
linestyle : str, optional
    Style of line used for working fluid plot points. Passed as a matplotlib.plot argument. Defaults to '-'.
marker : str, optional
    Marker style used for working fluid plot poitns. Passed as a matplotlib.plot argument. Defaults to '.'.
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
    Folder in the current working directory to save figure into. Folder is created if it does not already exist. Figure is saved as "./savefig_folder/savefig_name.savefig_format". If None or '', figure is saved directly into the current working directory. Defaults to None.
savefig_format : str, optional
    Format of saved plot file. Must be 'png' or 'jpg'. Defaults to 'png'.
savefig_dpi : int, optional
    Dots per inch / pixels per inch of the saved image. Passed as a matplotlib.plot argument. Defaults to 600.
        """
        import matplotlib
        import matplotlib.pyplot as plt
        assert savefig_format in [
            'png', 'PNG', 'jpg', 'JPG'
        ], "savefig format must be 'png' or 'jpg', '{0}' is invalid.".format(
            savefig_format)
        xlabel = ''
        ylabel = ''
        title = ''
        xvalsState = []
        yvalsState = []
        xvalsSource = []
        yvalsSource = []
        xvalsSink = []
        yvalsSink = []
        xvalsSat = []
        yvalsSat = []

        if graph == 'Ts':
            x = "s"
            y = "T"
            xlabel = 's [J/Kg.K]'
            ylabel = 'T [K]'
            title = title
            Tcrit = CP.CoolProp.PropsSI(COOLPROP_EOS + "::" + self.wf.fluid,
                                        "Tcrit")
            Tmin = CP.CoolProp.PropsSI(COOLPROP_EOS + "::" + self.wf.fluid,
                                       "Tmin")
            xvalsSat2, yvalsSat2 = [], []
            for T in np.linspace(Tmin, Tcrit, 100, False):
                xvalsSat.append(
                    CP.CoolProp.PropsSI("S", "Q", 0, "T", T, COOLPROP_EOS +
                                        "::" + self.wf.fluid))
                yvalsSat.append(T)
                xvalsSat2.append(
                    CP.CoolProp.PropsSI("S", "Q", 1, "T", T, COOLPROP_EOS +
                                        "::" + self.wf.fluid))
                yvalsSat2.append(T)
            xvalsSat = xvalsSat + list(reversed(xvalsSat2))
            yvalsSat = yvalsSat + list(reversed(yvalsSat2))
        elif graph == 'ph':
            x = "h"
            y = "p"
            xlabel = 'h [J/Kg]'
            ylabel = 'p [Pa]'
            title = title
            pcrit = CP.CoolProp.PropsSI(COOLPROP_EOS + "::" + self.wf.fluid,
                                        "pcrit")
            pmin = CP.CoolProp.PropsSI(COOLPROP_EOS + "::" + self.wf.fluid,
                                       "pmin")
            xvalsSat2, yvalsSat2 = [], []
            for p in np.linspace(pmin, pcrit, 100, False):
                xvalsSat.append(
                    CP.CoolProp.PropsSI("H", "Q", 0, "P", p, COOLPROP_EOS +
                                        "::" + self.wf.fluid))
                yvalsSat.append(p)
                xvalsSat2.append(
                    CP.CoolProp.PropsSI("H", "Q", 1, "P", p, COOLPROP_EOS +
                                        "::" + self.wf.fluid))
                yvalsSat2.append(p)
            xvalsSat = xvalsSat + list(reversed(xvalsSat2))
            yvalsSat = yvalsSat + list(reversed(yvalsSat2))
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
            if "counter" in self.evap.flowSense.lower():
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
            if "counter" in self.cond.flowSense.lower():
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
            plt.plot(xvalsSat, yvalsSat, 'g--')
        #
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.title(title)
        plt.grid(True)
        if savefig is True:
            import os
            cwd = os.getcwd()
            if savefig_folder is None or savefig_folder == "":
                folder = cwd
            else:
                if not os.path.exists(savefig_folder):
                    os.makedirs(savefig_folder)
                folder = "{}/{}".format(cwd, savefig_folder)
            plt.savefig(
                "{}/{}.{}".format(folder, savefig_name, savefig_format),
                dpi=savefig_dpi,
                bbox_inches='tight')
        if show is True:
            plt.show()
