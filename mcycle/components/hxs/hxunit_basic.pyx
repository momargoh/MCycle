from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from ..._constants cimport *
from ...methods.heat_transfer cimport lmtd
from ...logger import log
from .flowconfig cimport HxFlowConfig
from warnings import warn
from math import nan
import numpy as np
import scipy.optimize as opt

cdef dict _inputs = {"flowConfig": MCAttr(HxFlowConfig, "none"), "NWf": MCAttr(int, "none"), "NSf": MCAttr(int, "none"),
                        "NWall": MCAttr(int, "none"), "hWf": MCAttr(float, "htc"), "hSf": MCAttr(float, "htc"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "wall": MCAttr(SolidMaterial, "none"), "tWall": MCAttr(float, "length"),
                        "RfWf": MCAttr(float, "fouling"), "RfSf": MCAttr(float, "fouling"), "A": MCAttr(float, "area"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioWall": MCAttr(float, "none"),
                        "efficiencyThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  
                        "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"),
                        "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}
        
cdef class HxUnitBasic(Component22):
    r"""Characterises a basic heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf : float, optional
    Heat transfer coefficient of the working fluid.. Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid. Defaults to nan.
RfWf : float, optional
    Thermal resistance factor due to fouling on the working fluid side [m^2K/W]. Defaults to 0.
RfSf : float, optional
    Thermal resistance factor due to fouling on the secondary fluid side [m^2K/W]. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
A : float, optional
    Heat transfer surface area [m^2]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioWall : float, optional
    Multiplier for the heat transfer surface area of the wall [-]. Defaults to 1.
efficiencyThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "N".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [3, 100].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "HxBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 unsigned int NWf=0,
                 unsigned int NSf=0,
                 unsigned int NWall=0,
                 double hWf=nan,
                 double hSf=nan,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=nan,
                 double A=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="A",
                 list sizeBounds=[0.01, 10.0],
                 str name="HxUnitBasic instance",
                 str  notes="No notes/model info.",
                 Config config=None):
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, None, sizeAttr,
                         sizeBounds, [], [0, 0], [0, 0], name, notes, config)
        self.flowConfig = flowConfig
        self.NWf = NWf
        self.NSf = NSf
        self.NWall = NWall
        self.hWf = hWf
        self.hSf = hSf
        self.RfWf = RfWf
        self.RfSf = RfSf
        self.wall = wall
        self.tWall = tWall
        self.A = A
        self.ARatioWf = ARatioWf
        self.ARatioSf = ARatioSf
        self.ARatioWall = ARatioWall
        self.efficiencyThermal = efficiencyThermal
        self._inputs = _inputs
        self._properties = _properties

    
    cpdef public double _A(self):
        return self.A
    cpdef public double _hWf(self):
        return self.hWf
    cpdef public double _hSf(self):
        return self.hSf
    
    cpdef public bint isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowsIn[1].T() > self.flowsIn[0].T():
            return True
        else:
            return False

    cpdef public double _efficiencyFactorWf(self):
        if self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double _efficiencyFactorSf(self):
        if not self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double dpWf(self):
        return 0
    
    cpdef public double dpSf(self):
        return 0
    
    cpdef public unsigned char phaseWf(self):
        """str: Identifier of working fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'tpEvap' or 'tpCond': evaporating or condensing in two-phase liq/vapour region."""
        cdef unsigned char flowInPhase, flowOutPhase
        try:
            flowInPhase = self.flowsIn[0].phase()
            if self.hasInAndOut(0):
                flowOutPhase = self.flowsOut[0].phase()
                if flowInPhase == PHASE_SATURATED_LIQUID:
                    if flowOutPhase == PHASE_TWOPHASE:
                        return UNITPHASE_TWOPHASE_EVAPORATING
                    elif flowOutPhase == PHASE_LIQUID:
                        return UNITPHASE_LIQUID
                    else:
                        msg = "phaseWf(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                        log('error', msg)
                        raise ValueError(msg)
                elif flowInPhase == PHASE_SATURATED_VAPOUR:
                    if flowOutPhase == PHASE_TWOPHASE:
                        return UNITPHASE_TWOPHASE_CONDENSING
                    elif flowOutPhase == PHASE_VAPOUR:
                        return UNITPHASE_GAS
                    else:
                        msg = "phaseWf(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                        log('error', msg)
                        raise ValueError(msg)
                elif flowInPhase == PHASE_TWOPHASE:
                    if flowOutPhase == PHASE_SATURATED_LIQUID:
                        return UNITPHASE_TWOPHASE_CONDENSING
                    elif flowOutPhase == PHASE_SATURATED_VAPOUR:
                        return UNITPHASE_TWOPHASE_EVAPORATING
                    elif flowOutPhase == PHASE_TWOPHASE:
                        if self.flowsIn[0].h() < self.flowsOut[0].h():
                            return UNITPHASE_TWOPHASE_EVAPORATING
                        else:
                            return UNITPHASE_TWOPHASE_CONDENSING
                    else:
                        msg = "Unit spanning twophase and single states currently unsupported"
                        log('error', msg)
                        raise NotImplementedError(msg)
                elif flowInPhase == PHASE_LIQUID or flowOutPhase == PHASE_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_VAPOUR or flowOutPhase == PHASE_VAPOUR:
                    return UNITPHASE_GAS
                elif flowInPhase == PHASE_SUPERCRITICAL_LIQUID or flowOutPhase == PHASE_SUPERCRITICAL_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_SUPERCRITICAL_GAS or flowOutPhase == PHASE_SUPERCRITICAL_GAS:
                    return UNITPHASE_GAS
                else:
                    msg = "phaseWf(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                    log('error', msg)
                    raise ValueError(msg)
            else:
                if flowInPhase == PHASE_TWOPHASE:
                    if self.flowsIn[0].T() < self.flowsIn[1].T():
                        return UNITPHASE_TWOPHASE_EVAPORATING
                    else:
                        return UNITPHASE_TWOPHASE_CONDENSING

                elif flowInPhase == PHASE_SATURATED_LIQUID:
                    if self.flowsIn[0].T() < self.flowsIn[1].T():
                        return UNITPHASE_TWOPHASE_EVAPORATING
                    else:
                        return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_SATURATED_VAPOUR:
                    if self.flowsIn[0].T() < self.flowsIn[1].T():
                        return UNITPHASE_GAS
                    else:
                        return UNITPHASE_TWOPHASE_CONDENSING

                elif flowInPhase == PHASE_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_VAPOUR:
                    return UNITPHASE_GAS
                elif flowInPhase == PHASE_SUPERCRITICAL_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_SUPERCRITICAL_GAS:
                    return UNITPHASE_GAS
                else:
                    msg = "phaseWf(): Could not determine unit phase given phases: flowIn={}, flowOut=None".format(flowInPhase)
                    log('error', msg)
                    raise ValueError(msg)
        except Exception as exc:
            msg = "phaseWf(): Could not determine unit phase."
            log("error", msg, exc)
            raise exc

    cpdef public unsigned char phaseSf(self):
        """str: Identifier of secondary fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'sp': unknown single-phase."""
        cdef unsigned char flowInPhase, flowOutPhase
        try:
            flowInPhase = self.flowsIn[1].phase()
            if self.hasInAndOut(1):
                flowOutPhase = self.flowsOut[1].phase()
                if flowInPhase == PHASE_LIQUID or flowOutPhase == PHASE_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_VAPOUR or flowOutPhase == PHASE_VAPOUR:
                    return UNITPHASE_GAS
                elif flowInPhase == PHASE_SUPERCRITICAL_LIQUID or flowOutPhase == PHASE_SUPERCRITICAL_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_SUPERCRITICAL_GAS or flowOutPhase == PHASE_SUPERCRITICAL_GAS:
                    return UNITPHASE_GAS
                else:
                    msg = "phaseSf(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                    log('error', msg)
                    raise ValueError(msg)
            else:
                if flowInPhase == PHASE_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_VAPOUR:
                    return UNITPHASE_GAS
                elif flowInPhase == PHASE_SUPERCRITICAL_LIQUID:
                    return UNITPHASE_LIQUID
                elif flowInPhase == PHASE_SUPERCRITICAL_GAS:
                    return UNITPHASE_GAS
                else:
                    msg = "phaseSf(): Could not determine unit phase given phases: flowIn={}, flowOut=None".format(flowInPhase)
                    log('error', msg)
                    raise ValueError(msg)
        except Exception as exc:
            msg = "phaseSf(): Could not determine unit phase."
            log("error", msg, exc)
            raise exc

    cpdef public double QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowsOut[0].h() - self.flowsIn[0].h()) > self.config.tolAbs:
            return (self.flowsOut[0].h() - self.flowsIn[0].h()
                    ) * self._mWf() * self._efficiencyFactorWf()
        else:
            return 0

    cpdef public double QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowsOut[1].h() - self.flowsIn[1].h()) > self.config.tolAbs:
            return (self.flowsOut[1].h() - self.flowsIn[1].h()
                    ) * self._mSf() * self._efficiencyFactorSf()
        else:
            return 0

    cpdef public double Q(self):
        """float: Heat transfer from the secondary fluid to the working fluid [W]."""
        cdef str err_msg
        cdef double QWf = self.QWf()
        cdef double QSf = self.QSf()
        cdef double tolAbs = self.config.tolAbs
        if abs(QWf) < tolAbs and abs(QSf) < tolAbs:
            return 0
        elif abs((QWf + QSf) / QWf) < self.config.tolRel:
            return QWf
        else:
            err_msg = """QWf*{}={},QSf*{}={}. Check efficiencyThermal={} is correct.""".format(
            self._efficiencyFactorWf(), QWf, self._efficiencyFactorSf(), QSf,
            self.efficiencyThermal)
            warn(err_msg)
            return QWf

    cpdef public unsigned int _NWf(self):
        return self.NWf

    cpdef public unsigned  int _NSf(self):
        return self.NSf

    cpdef public double U(self):
        """float: Overall heat transfer coefficient [W/m^2.K]; heat transfer coefficients of each flow channel and wall, summed in series."""
        cdef double RWf = 1 / self._hWf() / self.ARatioWf / self._NWf() + self.RfWf / self.ARatioWf / self._NWf()
        cdef double RSf = 1 / self._hSf() / self.ARatioSf / self._NSf() + self.RfSf / self.ARatioSf / self._NSf()
        cdef double RWall = self.tWall / self.wall.k() / self.ARatioWall / self.NWall
        return (RWf + RSf + RWall)**-1

    cpdef public double lmtd(self):
        """float: Log-mean temperature difference [K]."""
        return lmtd(self.flowsIn[0].T(), self.flowsOut[0].T(), self.flowsIn[1].T(), self.flowsOut[1].T(), self.flowConfig.sense)

    cdef public double Q_lmtd(self):
        """float: Absolute value of heat transfer rate to the working fluid [W] as calculated using the log-mean temperature difference method."""
        return self.U() * self._A() * self.lmtd()

    cpdef public double mass(self):
        """float: Estimate of mass [Kg], based purely on wall properties."""
        return self._A() * self.ARatioWall * self.tWall * self.wall.rho * self.NWall

    cpdef public void run(self):
        """Run the HX from the incoming FlowState, using the epsilon-NTU method to produce an initial solution estimate."""
        # initial guess from e-NTU method
        cdef double eps = 0.8
        cdef double Cmin = min(self.flowsIn[0].cp() * self._mWf(), self.flowsIn[1].cp() * self._mSf())
        cdef double q = eps * Cmin * (self.flowsIn[1].T() - self.flowsIn[0].T()) * self.efficiencyThermal
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
            HmassP_INPUTS, self.flowsIn[0].h() + q / self._mWf(), self.flowsIn[0].p())
        self.flowsOut[1] = self.flowsIn[1].copyUpdateState(
            HmassP_INPUTS, self.flowsIn[1].h() - self._mWf() * self._efficiencyFactorWf() *
            (self.flowsOut[0].h() - self.flowsIn[0].h()
             ) / self._mSf() / self._efficiencyFactorSf(), self.flowsIn[1].p())
        cdef double diff = abs(self.Q() - self.Q_lmtd()) / self.Q()
        cdef int count = 0
        while diff > self.config._tolRel_h:
            q = self.Q_lmtd()
            self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
                HmassP_INPUTS,
                self.flowsIn[0].h() + q / self._efficiencyFactorWf() / self._mWf(),
                self.flowsIn[0].p())
            self.flowsOut[1] = self.flowsIn[1].copyUpdateState(
                HmassP_INPUTS,
                self.flowsIn[1].h() - q / self._efficiencyFactorSf() / self._mSf(),
                self.flowsIn[1].p())
            diff = abs(self.Q() - q) / self.Q()

            count += 1
            if count > self.config.maxIterComponent:
                raise StopIteration(
                    """{} iterations without {} converging: diff={}>tol={}""".
                    format(self.config.maxIterComponent, "h", diff,
                           self.config._tolRel_h))
        #return self.flowsOut[0]

    cdef double _f_sizeHxUnitBasic(self, double value, str attr):
        self.update({attr: value})
        return abs(self.Q()) - self.Q_lmtd()
                
    cpdef public void sizeUnits(self) except *:
        """Size for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
attr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol, sizedValue
        cdef str attr = self.sizeAttr
        cdef double[2] bounds = self.sizeBounds
        try:
            if attr == "A":
                self.A = 1.
                self.A = abs(self.Q() / self.Q_lmtd())
                #return self.A
            else:
                tol = self.config.tolAbs + self.config.tolRel * self.Q()
                if len(bounds) == 2:
                    sizedValue = opt.brentq(
                        self._f_sizeHxUnitBasic,
                        bounds[0],
                        bounds[1],
                        args=(attr),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(bounds) == 1:
                    sizedValue = opt.newton(self._f_sizeHxUnitBasic, bounds[0], args=(attr), tol=tol)
                else:
                    raise ValueError("bounds is not valid (given: {})".format(bounds))
                self.update({attr:sizedValue})
                #return sizedValue
        except AssertionError as err:
            raise (err)
        except:
            raise Exception(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, attr, bounds))
        
    @property
    def N(self):
        """int: Number of flow channels, returns average of NWf & NSf.
        Setter makes both equal to desired value."""
        return (self._NWf() + self._NSf()) / 2.

    @N.setter
    def N(self, value):
        self.NWf = value
        self.NSf = value

