from ..DEFAULTS import DEFAULT_PLOT_FOLDER, DEFAULT_PLOT_FORMAT, DEFAULT_PLOT_DPI, MAXITERATIONSCYCLE
from ..bases import Config, Cycle
from ..components import HxBasic
import numpy as np
import CoolProp as CP


class RankineBasic(Cycle):
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
                 wf,
                 evap,
                 exp,
                 cond,
                 comp,
                 pEvap=None,
                 superheat=None,
                 pCond=None,
                 subcool=None,
                 config=Config(),
                 **kwargs):
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
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("wf", "none"), ("evap", "none"), ("exp", "none"),
                ("cond", "none"), ("comp", "none"), ("pEvap", "pressure"),
                ("superheat", "temperature"), ("pCond", "pressure"),
                ("subcool", "temperature"), ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("QIn", "power"), ("QOut", "power"),
                ("PIn", "power"), ("POut", "power"), ("effThermal", "none"),
                ("effExergy", "none"), ("IComp", "power"), ("IEvap", "power"),
                ("IExp", "power"), ("ICond", "power")]

    def update(self, **kwargs):
        """Update (multiple) Cycle variables using keyword arguments."""
        for key, value in kwargs.items():
            if key == "evap" and self.sourceIn is not None:
                if issubclass(type(value), HxBasic):
                    value.update(flowInSf=self.sourceIn)
                setattr(self, key, value)
            elif key == "cond" and self.sinkIn is not None:
                if issubclass(type(value), HxBasic):
                    value.update(flowInSf=self.sinkIn)
                setattr(self, key, value)
            else:
                if "__" in key:
                    key_split = key.split("__", 1)
                    key_attr = getattr(self, key_split[0])
                    key_attr.update(**{key_split[1]: value})
                else:
                    setattr(self, key, value)

    @property
    def workingFluid(self):
        """FlowState: Alias of wf"""
        return self.wf

    @workingFluid.setter
    def workingFluid(self, obj):
        self.wf = obj

    @property
    def mWf(self):
        """float: Alias of wf.m; mass flow rate of the working fluid [Kg/s]."""
        return self.wf.m

    @mWf.setter
    def mWf(self, value):
        self.wf.m = value

    @property
    def state1(self):
        """FlowState: Working fluid flow at compressor outlet/ evaporator inlet."""
        return self.evap.flowInWf

    @state1.setter
    def state1(self, obj):
        self.evap.flowInWf = obj
        self.comp.flowOutWf = obj

    @property
    def state20(self):
        """FlowState: Working fluid saturated liquid FlowState in evaporator."""
        return self.evap.flowInWf.copy(CP.PQ_INPUTS, self.state1.p, 0)

    @property
    def state21(self):
        """FlowState: Working fluid saturated vapour FlowState in evaporator."""
        return self.evap.flowInWf.copy(CP.PQ_INPUTS, self.state1.p, 1)

    @property
    def state3(self):
        """FlowState: Working fluid FlowState at evaporator outlet/expander inlet."""
        return self.exp.flowInWf

    @state3.setter
    def state3(self, obj):
        self.exp.flowInWf = obj
        self.evap.flowOutWf = obj

    @property
    def state4(self):
        """FlowState: Working fluid FlowState at expander outlet/condenser inlet."""
        return self.cond.flowInWf

    @state4.setter
    def state4(self, obj):
        self.cond.flowInWf = obj
        self.exp.flowOutWf = obj

    @property
    def state50(self):
        """FlowState: Working fluid saturated liquid FlowState in condenser."""
        return self.state4.copy(CP.PQ_INPUTS, self.state4.p, 0)

    @property
    def state51(self):
        """FlowState: Working fluid saturated vapour FlowState in condenser."""
        return self.state4.copy(CP.PQ_INPUTS, self.state4.p, 1)

    @property
    def state6(self):
        """FlowState: Working fluid FlowState at condenser outlet/ compressor inlet."""
        return self.comp.flowInWf

    @state6.setter
    def state6(self, obj):
        self.comp.flowInWf = obj
        self.cond.flowOutWf = obj

    @property
    def sourceIn(self):
        """FlowState: Alias of evap.flowInSf. Only valid with a secondary flow as the heat source."""
        return self.evap.flowInSf

    @sourceIn.setter
    def sourceIn(self, obj):
        self.evap.flowInSf = obj

    @property
    def sourceOut(self):
        """FlowState: Alias of evap.flowOutSf. Only valid with a secondary flow as the heat source."""
        return self.evap.flowOutSf

    @property
    def source1(self):
        """FlowState: Heat source when working fluid is at state1. Only valid with a secondary flow as the heat source."""
        if "counter" in self.evap.flowSense.lower():
            return self.sourceOut
        elif "parallel" in self.evap.flowSense.lower():
            return self.sourceIn
        else:
            return None

    @property
    def source20(self):
        """FlowState: Heat source when working fluid is at state20. Only valid with a secondary flow as the heat source."""
        if "counter" in self.evap.flowSense.lower():
            h = self.source1.h + self.mWf * self.evap._effFactorWf * (
                self.state20.h - self.state1.h
            ) / self.source1.m / self.evap._effFactorSf
        elif "parallel" in self.evap.flowSense.lower():
            h = self.source1.h - self.mWf * self.evap._effFactorWf * (
                self.state20.h - self.state1.h
            ) / self.source1.m / self.evap._effFactorSf
        else:
            return None
        return self.sourceIn.copy(CP.HmassP_INPUTS, h, self.sourceIn.p)

    @property
    def source21(self):
        """FlowState: Heat source when working fluid is at state21. Only valid with a secondary flow as the heat source."""
        if "counter" in self.evap.flowSense.lower():
            h = self.source1.h + self.mWf * self.evap._effFactorSf * (
                self.state21.h - self.state1.h
            ) / self.sourceIn.m / self.evap._effFactorSf
        elif "parallel" in self.evap.flowSense.lower():
            h = self.source1.h - self.mWf * self.evap._effFactorWf * (
                self.state21.h - self.state1.h
            ) / self.sourceIn.m / self.evap._effFactorSf
        else:
            return None
        return self.sourceIn.copy(CP.HmassP_INPUTS, h, self.sourceIn.p)

    @property
    def source3(self):
        """FlowState: Heat source when working fluid is at state3. Only valid with a secondary flow as the heat source."""
        if "counter" in self.evap.flowSense.lower():
            return self.sourceIn
        elif "parallel" in self.evap.flowSense.lower():
            return self.sourceOut
        else:
            return None

    @property
    def sourceDead(self):
        """FlowState: Alias of evap.flowDeadSf. Only valid with a secondary flow as the heat source."""
        return self.evap.flowDeadSf

    @sourceDead.setter
    def sourceDead(self, obj):
        self.evap.flowDeadSf = obj

    @property
    def sinkIn(self):
        """FlowState: Alias of cond.flowInSf. Only valid with a secondary flow as the heat sink."""
        return self.cond.flowInSf

    @sinkIn.setter
    def sinkIn(self, obj):
        self.cond.flowInSf = obj

    @property
    def sinkOut(self):
        """FlowState: Alias of cond.flowOutSf. Only valid with a secondary flow as the heat sink."""
        return self.cond.flowOutSf

    @property
    def sink4(self):
        """FlowState: Heat sink when working fluid is at state4. Only valid with a secondary flow as the heat sink."""
        if self.cond.flowSense == "counterflow":
            return self.sinkOut
        elif self.cond.flowSense == "parallel":
            return self.sinkIn
        else:
            return None

    @property
    def sink50(self):
        """FlowState: Heat sink when working fluid is at state50. Only valid with a secondary flow as the heat sink."""
        if "counter" in self.cond.flowSense.lower():
            h = self.sink4.h - self.mWf * self.cond._effFactorWf * (
                self.state4.h - self.state50.h
            ) / self.sink4.m / self.cond._effFactorSf
        elif "parallel" in self.cond.flowSense.lower():
            h = self.sink4.h + self.mWf * self.cond._effFactorWf * (
                self.state4.h - self.state50.h
            ) / self.sink4.m / self.cond._effFactorSf
        else:
            return None
        return self.sinkIn.copy(CP.HmassP_INPUTS, h, self.sinkIn.p)

    @property
    def sink51(self):
        """FlowState: Heat sink when working fluid is at state51. Only valid with a secondary flow as the heat sink."""
        if "counter" in self.cond.flowSense.lower():
            h = self.sink4.h - self.mWf * self.cond._effFactorWf * (
                self.state4.h - self.state51.h
            ) / self.sink4.m / self.cond._effFactorSf
        elif "parallel" in self.cond.flowSense.lower():
            h = self.sink4.h + self.mWf * self.cond._effFactorWf * (
                self.state4.h - self.state51.h
            ) / self.sink4.m / self.cond._effFactorSf
        else:
            return None
        return self.sinkIn.copy(CP.HmassP_INPUTS, h, self.sinkIn.p)

    @property
    def sink6(self):
        """FlowState: Heat sink when working fluid is at state6. Only valid with a secondary flow as the heat sink."""
        if "counter" in self.cond.flowSense.lower():
            return self.sinkIn
        elif "parallel" in self.cond.flowSense.lower():
            return self.sinkOut
        else:
            return None

    @property
    def sinkDead(self):
        """FlowState: Alias of cond.flowDeadSf. Only valid with a secondary flow as the heat sink."""
        return self.cond.flowDeadSf

    @sinkDead.setter
    def sinkDead(self, obj):
        self.cond.flowDeadSf = obj

    @property
    def TCond(self):
        """float: Evaporation temperature of the working fluid in the compressor [K]."""
        return CP.CoolProp.PropsSI('T', 'P', self.pCond, 'Q', 0,
                                   self.wf.libCP + "::" + self.wf.fluid)

    @TCond.setter
    def TCond(self, value):
        self.pCond = CP.CoolProp.PropsSI('P', 'T', value, 'Q', 0,
                                         self.wf.libCP + "::" + self.wf.fluid)

    @property
    def dpComp(self):
        """float: Pressure increase across the compressor [Pa]."""
        return self.pEvap - self.pCond

    @dpComp.setter
    def dpComp(self, value):
        self.pEvap = self.pCond + value

    @property
    def pRatioComp(self):
        """float: Pressure ratio of the compressor."""
        return self.pEvap / self.pComp

    @pRatioComp.setter
    def pRatioComp(self, value):
        self.pEvap = self.pCond * value

    @property
    def TEvap(self):
        """float: Evaporation temperature of the working fluid in the evaporator [K]."""
        return CP.CoolProp.PropsSI('T', 'P', self.pEvap, 'Q', 0,
                                   self.wf.libCP + "::" + self.wf.fluid)

    @TEvap.setter
    def TEvap(self, value):
        self.pEvap = CP.CoolProp.PropsSI('P', 'T', value, 'Q', 0,
                                         self.wf.libCP + "::" + self.wf.fluid)

    @property
    def dpExp(self):
        """float: Pressure drop across the expander [Pa]."""
        return self.pEvap - self.pCond

    @dpExp.setter
    def dpExp(self, value):
        self.pCond = self.pEvap - value

    @property
    def pRatioExp(self):
        """float: Pressure ratio of the expander."""
        return self.pEvap / self.pComp

    @pRatioExp.setter
    def pRatioExp(self, value):
        self.pCond = self.pEvap / value

    @property
    def QIn(self):
        """float: Heat input (from evaporator) [W]."""
        return self.mWf * (self.state3.h - self.state1.h)

    @property
    def QOut(self):
        """float: Heat output (from condenser) [W]."""
        return self.mWf * (self.state4.h - self.state6.h)

    @property
    def PIn(self):
        """float: Power input (from compressor) [W]."""
        return self.mWf * (self.state1.h - self.state6.h)

    @property
    def POut(self):
        """float: Power output (from expander) [W]."""
        return self.mWf * (self.state3.h - self.state4.h)

    @property
    def PNet(self):
        """float: Net power output [W].
        PNet = POut - PIn"""
        return self.POut - self.PIn

    @property
    def effThermal(self):
        """float: Cycle thermal efficiency [-]
        effThermal = PNet/QIn"""
        return self.PNet / self.QIn

    @property
    def pptdEvap(self):
        """float: Pinch-point temperature difference of evaporator"""
        if issubclass(type(self.evap), HxBasic):
            if "counter" in self.evap.flowSense.lower():

                if self.state1 and self.state20 and self.source1 and self.source20:
                    return min(self.source20.T - self.state20.T,
                               self.source1.T - self.state1.T)

                else:
                    print("run() or solve() has not been executed")
            else:
                print("pptdEvap is not a valid for flowSense = {0}".format(
                    type(self.evap.flowSense)))
        else:
            print("pptdEvap is not a valid attribute for a {0} evaporator".
                  format(type(self.evap)))

    @pptdEvap.setter
    def pptdEvap(self, value):
        if issubclass(type(self.evap), HxBasic):
            state20 = self.wf.copy(CP.PQ_INPUTS, self.pEvap, 0)
            if self.superheat == 0 or self.superheat is None:
                state3 = self.wf.copy(CP.PQ_INPUTS, self.pEvap, 1)
            else:
                state3 = self.wf.copy(CP.PT_INPUTS, self.pEvap,
                                      self.TEvap + self.superheat)
            source20 = self.sourceIn.copy(CP.PT_INPUTS, self.sourceIn.p,
                                          state20.T + value)

            m20 = self.evap.effThermal * self.sourceIn.m * (
                self.sourceIn.h - source20.h) / (state3.h - state20.h)
            # check if pptd should be at state1
            if (source20.m / m20) < (state20.cp / source20.cp):
                if self.subcool == 0 or self.subcool is None:
                    state6 = self.wf.copy(CP.PQ_INPUTS, self.pCond, 0)
                else:
                    state6 = self.wf.copy(CP.PT_INPUTS, self.pCond,
                                          self.TCond - self.subcool)
                state1s = self.wf.copy(CP.PSmass_INPUTS, self.pEvap, state6.s)
                h1 = state6.h + (state1s.h - state6.h
                                 ) / self.comp.effIsentropic
                state1 = self.wf.copy(CP.HmassP_INPUTS, h1, self.pEvap)
                source1 = self.sourceIn.copy(CP.PT_INPUTS, self.sourceIn.p,
                                             state1.T + value)
                m1 = self.evap.effThermal * self.sourceIn.m * (
                    self.sourceIn.h - source1.h) / (state3.h - state1.h)
                # check
                h20 = source1.h + m1 * (
                    state20.h - state1.h
                ) / self.sourceIn.m / self.evap.effThermal
                source20.update(CP.HmassP_INPUTS, h20, self.sourceIn.p)
                if source20.T < state20.T:  # assumption was wrong or error
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
                    return min(self.state51.T - self.sink51.T,
                               self.state4.T - self.sink4.T)

                else:
                    print("run() or solve() has not been executed")
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

    def run(self, flowState=None, component=None):
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
            self.state1 = self.comp.run(self.state6)
            [
                self.sourceOut, self.state3, self.source20, self.state20,
                self.source21, self.state21
            ] = self.evap.run(self.sourceIn, self.state1)
            self.evap.unitise()
            if self.config.dpEvap is True:
                try:
                    self.evap.solve()
                    dp = self.evap.dpCold()
                    if dp < self.state3.p:
                        self.state3.update(CP.HmassP_INPUTS, self.state3.h,
                                           self.state3.p - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state3.p))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across evaporator ignored"
                    )
            self.state4 = self.exp.run(self.state3)
            [
                state6new, self.sinkOut, self.state51, self.sink51,
                self.state50, self.sink50
            ] = self.cond.run(self.state4, self.sinkIn)
            self.cond._unitise()
            if self.config.dpCond is True:
                try:
                    self.cond.solve()
                    dp = self.cond.dpHot()
                    if dp < state6new.p:
                        state6new.update(CP.HmassP_INPUTS, state6new.h,
                                         state6new.p - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, state6new.p))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across condenser ignored"
                    )
            diff = abs(
                getattr(self.state6, self.config.tolAttr) - getattr(
                    state6new, self.config.tolAttr))
            self.state6 = state6new
            count += 1
            if count > self.config.maxIterationsCycle:
                raise StopIteration(
                    """{0} iterations without {1} converging: diff={2}>tol={3}""".
                    format(self.config.maxIterationsCycle, self.config.tolAttr,
                           diff, self.config.tolAbs))

    def solveSetup(self, unitiseEvap=True, unitiseCond=True):
        """Impose the design parameters on the cycle (without executing .solve() for each component).

Parameters
-----------
unitiseEvap : bool, optional
    If True, the evap.unitise() is called if possible. Defaults to True.
unitiseCond : bool, optional
    If True, cond.unitise() is called if possible. Defaults to True.
"""
        if self.subcool == 0 or self.subcool is None:
            self.state6 = self.wf.copy(CP.PQ_INPUTS, self.pCond, 0)
        else:
            self.state6 = self.wf.copy(CP.PT_INPUTS, self.pCond,
                                       self.TCond - self.subcool)
        #
        state1_s = self.wf.copy(CP.PSmass_INPUTS, self.pEvap, self.state6.s)
        hOut = self.state6.h + (state1_s.h - self.state6.h
                                ) / self.comp.effIsentropic

        self.state1 = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pEvap)
        #
        if self.superheat == 0 or self.superheat is None:
            self.state3 = self.wf.copy(CP.PQ_INPUTS, self.pEvap, 1)
        else:
            self.state3 = self.wf.copy(CP.PT_INPUTS, self.pEvap,
                                       self.TEvap + self.superheat)
        #
        state4_s = self.wf.copy(CP.PSmass_INPUTS, self.pCond, self.state3.s)
        hOut = self.state3.h + (state4_s.h - self.state3.h
                                ) * self.exp.effIsentropic
        self.state4 = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pCond)
        #
        if issubclass(type(self.evap), HxBasic):
            hOut = self.evap.flowInSf.h - self.mWf * self.evap._effFactorWf * (
                self.evap.flowOutWf.h - self.evap.flowInWf.h
            ) / self.evap.mSf / self.evap._effFactorSf
            self.evap.flowOutSf = self.evap.flowInSf.copy(
                CP.HmassP_INPUTS, hOut, self.evap.flowInSf.p)
            if unitiseEvap:
                self.evap.unitise()
        if issubclass(type(self.cond), HxBasic):
            hOut = self.cond.flowInSf.h - self.mWf * self.cond._effFactorWf * (
                self.cond.flowOutWf.h - self.cond.flowInWf.h
            ) / self.cond.mSf / self.cond._effFactorSf
            self.cond.flowOutSf = self.cond.flowInSf.copy(
                CP.HmassP_INPUTS, hOut, self.cond.flowInSf.p)
            if unitiseCond:
                self.cond.unitise()

    def solve(self):
        """Impose the design parameters on the cycle and execute .solve() for each component."""
        if self.subcool == 0 or self.subcool is None:
            self.state6 = self.wf.copy(CP.PQ_INPUTS, self.pCond, 0)
        else:
            self.state6 = self.wf.copy(CP.PT_INPUTS, self.pCond,
                                       self.TCond - self.subcool)
        #
        cycle_diff = self.config.tolAbs * 5
        cycle_count = 0
        state6_old = self.state6.copy()
        while cycle_diff > self.config.tolAbs:
            diff = self.config.tolAbs * 5
            count = 0
            state1_s = self.wf.copy(CP.PSmass_INPUTS, self.pEvap,
                                    self.state6.s)
            hOut = self.state6.h + (state1_s.h - self.state6.h
                                    ) / self.comp.effIsentropic
            state1_old = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pEvap)
            while diff > self.config.tolAbs:
                self.comp.flowOutWf = state1_old
                self.comp.solve()
                """
                hOut = self.state6.h + (
                    state1_s.h - self.state6.h) / self.comp.effIsentropic
                self.state1 = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pEvap)
                """
                self.comp.run()
                diff = abs(
                    getattr(self.comp.flowOutWf, self.config.tolAttr) -
                    getattr(state1_old,
                            self.config.tolAttr))  # TODO proper tolerancing
                state1_old = self.comp.flowOutWf
                count += 1
                if count > MAXITERATIONSCYCLE:
                    raise StopIteration(
                        """{0} iterations without {1} compressor converging: diff={2}>tol={3}""".
                        format(MAXITERATIONSCYCLE, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.comp.solve()
            self.state1 = self.comp.flowOutWf
            #
            if self.superheat == 0 or self.superheat is None:
                self.state3 = self.wf.copy(CP.PQ_INPUTS, self.pEvap, 1)
            else:
                self.state3 = self.wf.copy(CP.PT_INPUTS, self.pEvap,
                                           self.TEvap + self.superheat)
            if issubclass(type(self.evap), HxBasic):
                deltaHEvap = (self.state3.h - self.state1.h
                              ) * self.evap.mWf * self.evap._effFactorWf
                self.evap.flowOutSf = self.evap.flowInSf.copy(
                    CP.HmassP_INPUTS, self.evap.flowInSf.h - deltaHEvap /
                    self.evap.mSf / self.evap._effFactorSf,
                    self.evap.flowInSf.p)
            self.evap.solve()
            if self.config.dpEvap is True:
                try:
                    # self.evap.solve()
                    dp = self.evap.dpWf
                    if dp < self.state3.p:
                        self.state3.update(CP.HmassP_INPUTS, self.state3.h,
                                           self.state3.p - dp)
                    else:
                        raise ValueError(
                            """pressure drop in working fluid is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state3.p))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across evaporator ignored"
                    )
            self.state3 = self.evap.flowOutWf
            #
            diff = self.config.tolAbs * 5
            count = 0
            state4_s = self.wf.copy(CP.PSmass_INPUTS, self.pCond,
                                    self.state3.s)
            hOut = self.state3.h + (state4_s.h - self.state3.h
                                    ) * self.exp.effIsentropic
            state4_old = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pCond)
            while diff > self.config.tolAbs:
                self.exp.flowOutWf = state4_old
                self.exp.solve()
                """
                hOut = self.state3.h + (
                    state4_s.h - self.state3.h) / self.exp.effIsentropic
                self.state4 = self.wf.copy(CP.HmassP_INPUTS, hOut, self.pCond)
                """
                self.exp.run()
                diff = abs(
                    getattr(self.exp.flowOutWf, self.config.tolAttr) - getattr(
                        state4_old, self.config.tolAttr))
                state4_old = self.exp.flowOutWf
                count += 1
                if count > MAXITERATIONSCYCLE:
                    raise StopIteration(
                        """{0} iterations without {1} expander converging: diff={2}>tol={3}""".
                        format(MAXITERATIONSCYCLE, self.config.tolAttr, diff,
                               self.config.tolAbs))
            self.exp.solve()
            self.state4 = self.exp.flowOutWf
            #
            if issubclass(type(self.cond), HxBasic):
                deltaHCond = (self.state4.h - self.state6.h
                              ) * self.cond.mWf * self.cond._effFactorWf
                self.cond.flowOutSf = self.cond.flowInSf.copy(
                    CP.HmassP_INPUTS, self.cond.flowInSf.h + deltaHCond /
                    self.cond.mSf / self.cond._effFactorSf,
                    self.cond.flowInSf.p)
            self.cond.solve()
            if self.config.dpCond is True:
                try:
                    dp = self.cond.dpWf
                    if dp < self.state6.p:
                        self.state6.update(CP.HmassP_INPUTS, self.state6.h,
                                           self.state6.p - dp)
                    else:
                        raise ValueError(
                            """pressure drop of working fluid in condenser is greater than actual pressure: {0}>{1}""".
                            format(dp, self.state6.p))
                except Exception as inst:
                    print(inst.__class__.__name__, ": ", inst)
                    print(
                        "pressure drop in working fluid across condenser ignored"
                    )
            self.state6 = self.cond.flowOutWf
            cycle_diff = getattr(self.state6, self.config.tolAttr) - getattr(
                state6_old, self.config.tolAttr)
            state6_old = self.state6.copy()
            cycle_count += 1
            if count > MAXITERATIONSCYCLE:
                raise StopIteration(
                    """{0} iterations without {1} cycle converging: diff={2}>tol={3}""".
                    format(MAXITERATIONSCYCLE, self.config.tolAttr, diff,
                           self.config.tolAbs))

    @property
    def effExergy(self):
        """float: Exhaust heat recovery efficiency"""
        return (self.sourceIn.h - self.source1.h) / (
            self.sourceIn.h - self.sourceDead.h)

    @property
    def effGlobal(self):
        """float: Global recovery efficiency"""
        return self.effThermal * self.effExergy

    @property
    def effExergy(self):
        """float: Exergy efficiency"""
        return self.PNet / self.sourceIn.m / (
            self.sourceIn.h - self.sourceDead.h)

    @property
    def IComp(self):
        """float: Exergy destruction of compressor [W]"""
        return self.sinkDead.T * self.mWf * (self.state1.s - self.state50.s)

    @property
    def IEvap(self):
        """float: Exergy destruction of evaporator [W]"""
        I_13 = self.sourceDead.T * (
            self.mWf * (self.state3.s - self.state1.s) + self.sourceIn.m *
            (self.source1.s - self.sourceIn.s))
        I_C0 = self.sourceDead.T * self.sourceIn.m * (
            (self.sourceDead.s - self.source1.s) +
            (self.source1.h - self.sourceDead.h) / self.sourceDead.T)
        return I_13 + I_C0

    @property
    def IExp(self):
        """float: Exergy destruction of expander [W]"""
        return self.sinkDead.T * self.mWf * (self.state4.s - self.state3.s)

    @property
    def ICond(self):
        """float: Exergy destruction of condenser [W]"""
        return self.sinkDead.T * self.mWf * (
            (self.state50.s - self.state4.s) +
            (self.state4.h - self.state50.h) / self.sinkDead.T)

    @property
    def ITotal(self):
        """float: Total exergy destruction of cycle [W]"""
        return self.I_comp + self.I_evap + self.I_exp + self.I_cond

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
             savefig_folder=DEFAULT_PLOT_FOLDER,
             savefig_format=DEFAULT_PLOT_FORMAT,
             savefig_dpi=DEFAULT_PLOT_DPI):
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
            Tcrit = CP.CoolProp.PropsSI(self.wf.libCP + "::" + self.wf.fluid,
                                        "Tcrit")
            Tmin = CP.CoolProp.PropsSI(self.wf.libCP + "::" + self.wf.fluid,
                                       "Tmin")
            xvalsSat2, yvalsSat2 = [], []
            for T in np.linspace(Tmin, Tcrit, 100, False):
                xvalsSat.append(
                    CP.CoolProp.PropsSI("S", "Q", 0, "T", T, self.wf.libCP +
                                        "::" + self.wf.fluid))
                yvalsSat.append(T)
                xvalsSat2.append(
                    CP.CoolProp.PropsSI("S", "Q", 1, "T", T, self.wf.libCP +
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
            pcrit = CP.CoolProp.PropsSI(self.wf.libCP + "::" + self.wf.fluid,
                                        "pcrit")
            pmin = CP.CoolProp.PropsSI(self.wf.libCP + "::" + self.wf.fluid,
                                       "pmin")
            xvalsSat2, yvalsSat2 = [], []
            for p in np.linspace(pmin, pcrit, 100, False):
                xvalsSat.append(
                    CP.CoolProp.PropsSI("H", "Q", 0, "P", p, self.wf.libCP +
                                        "::" + self.wf.fluid))
                yvalsSat.append(p)
                xvalsSat2.append(
                    CP.CoolProp.PropsSI("H", "Q", 1, "P", p, self.wf.libCP +
                                        "::" + self.wf.fluid))
                yvalsSat2.append(p)
            xvalsSat = xvalsSat + list(reversed(xvalsSat2))
            yvalsSat = yvalsSat + list(reversed(yvalsSat2))
        #
        plotStates = []
        for key in self._cyclestateKeys:
            if not key.startswith("state"):
                key = "state" + key
            plotStates.append(getattr(self, key))
        if self.state20.h < self.state1.h:
            plotStates.remove(self.state20)
        if self.state21.h > self.state3.h:
            plotStates.remove(self.state21)
        if self.state51.h > self.state4.h:
            plotStates.remove(self.state51)
        if self.state50.h < self.state6.h:
            plotStates.remove(self.state50)
        #
        plotSource = []
        if issubclass(type(self.evap), HxBasic):
            plotSource = [[self.state1,
                           self.source1], [self.state20, self.source20],
                          [self.state21,
                           self.source21], [self.state3, self.source3]]
            if "counter" in self.evap.flowSense.lower():
                if self.source20.h < self.source1.h:
                    plotSource.remove([self.state20, self.source20])
                if self.source21.h > self.source3.h:
                    plotSource.remove([self.state21, self.source21])
            else:
                if self.source20.h > self.source1.h:
                    plotSource.remove([self.state20, self.source20])
                if self.source21.h < self.source3.h:
                    plotSource.remove([self.state21, self.source21])
        else:
            pass
        #
        plotSink = []
        if issubclass(type(self.cond), HxBasic):
            plotSink = [[self.state6, self.sink6], [self.state50, self.sink50],
                        [self.state51, self.sink51], [self.state4, self.sink4]]
            if "counter" in self.cond.flowSense.lower():
                if self.sink51.h > self.sink4.h:
                    plotSink.remove([self.state51, self.sink51])
                if self.sink50.h < self.sink6.h:
                    plotSink.remove([self.state50, self.sink50])
            else:
                if self.sink51.h < self.sink4.h:
                    plotSink.remove([self.state51, self.sink51])
                if self.sink50.h > self.sink6.h:
                    plotSink.remove([self.state50, self.sink50])
        else:
            pass
        #
        for flowstate in plotStates:
            xvalsState.append(getattr(flowstate, x))
            yvalsState.append(getattr(flowstate, y))
        for flowstate in plotSource:
            xvalsSource.append(getattr(flowstate[0], x))
            yvalsSource.append(getattr(flowstate[1], y))
        for flowstate in plotSink:
            xvalsSink.append(getattr(flowstate[0], x))
            yvalsSink.append(getattr(flowstate[1], y))
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
