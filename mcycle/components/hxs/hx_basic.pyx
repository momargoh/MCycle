from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from ...DEFAULTS cimport TOLABS_X
from ...logger import log
from .hxunit_basic cimport HxUnitBasic
import CoolProp as CP
from warnings import warn
from math import nan
import numpy as np
cimport numpy as np
import scipy.optimize as opt

cdef dict _inputs = {"flowSense": MCAttr(str, "none"), "NWf": MCAttr(int, "none"), "NSf": MCAttr(int, "none"),
                        "NWall": MCAttr(int, "none"), "hWf_liq": MCAttr(float, "htc"), "hWf_tp": MCAttr(float, "htc"),
                        "hWf_vap": MCAttr(float, "htc"), "hSf": MCAttr(float, "htc"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "wall": MCAttr(SolidMaterial, "none"), "tWall": MCAttr(float, "length"),
                        "A": MCAttr(float, "area"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioWall": MCAttr(float, "none"),
                        "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  "ambient": MCAttr(FlowState, "none"),
                        "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"),
                        "sizeUnitsBounds": MCAttr(list, "none"), 'runBounds': MCAttr(list, 'none'), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}
        
cdef class HxBasic(Component22):
    r"""Characterises a basic heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counter" or "parallel". Defaults to "counter".
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
hWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
hWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid in a single-phase region. Defaults to nan.
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
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "N".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1, 100].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
sizeUnitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. Typically this bounds is used to size for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 str flowSense="counter",
                 int NWf=1,
                 int NSf=1,
                 int NWall=1,
                 double hWf_liq=nan,
                 double hWf_tp=nan,
                 double hWf_vap=nan,
                 double hSf=nan,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=nan,
                 double A=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[1, 100],
                 list sizeUnitsBounds=[1e-5, 1.],
                 runBounds=[nan, nan],
                 str name="HxBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config(),
                 _unitClass=HxUnitBasic):
        assert flowSense != "counter" or flowSense != "parallel", "{} is not a valid value for flowSense; must be 'counter' or 'parallel'.".format(flowSense)
        self.flowSense = flowSense
        self.NWf = NWf
        self.NSf = NSf
        self.NWall = NWall
        self.hWf_liq = hWf_liq
        self.hWf_tp = hWf_tp
        self.hWf_vap = hWf_vap
        self.hSf = hSf
        self.RfWf = RfWf
        self.RfSf = RfSf
        self.wall = wall
        self.tWall = tWall
        self.A = A
        self.ARatioWf = ARatioWf
        self.ARatioSf = ARatioSf
        self.ARatioWall = ARatioWall
        self.effThermal = effThermal
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, name, notes, config)
        self._units = []
        self._unitClass = _unitClass
        if self.hasInAndOut(0) and self.hasInAndOut(1):
            pass  # self._unitise()
        self._inputs = _inputs
        self._properties = _properties
        
    cpdef public void update(self, dict kwargs):
        """Update (multiple) variables using keyword arguments."""
        cdef HxUnitBasic unit
        for key, value in kwargs.items():
            if key not in [
                    "L", "flowInWf", "flowInSf", "flowOutWf", "flowOutSf"] and "sizeBounds" not in key and "sizeUnitsBounds" not in key:
                super(Component22, self).update({key: value})
                for unit in self._units:
                    unit.update({key: value})
            elif "sizeUnitsBounds" in key:
                super(Component22, self).update({key: value})
                for unit in self._units:
                    unit.update({key[:4] + key[9:]
: value})
            else:
                super(Component22, self).update({key: value})
                        
    cpdef public double _A(self):
        return self.A

    cpdef public bint isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowsIn[1].T() > self.flowsIn[0].T():
            return True
        else:
            return False

    cpdef public int _NWf(self):
        return self.NWf

    cpdef public int _NSf(self):
        return self.NSf


    cpdef public double _hWf(self):
        return self.hWf

    cpdef public double _hSf(self):
        return self.hSf
    
    cpdef public double _effFactorWf(self):
        if self.isEvap():
            return 1
        else:
            return self.effThermal

    cpdef public double _effFactorSf(self):
        if not self.isEvap():
            return 1
        else:
            return self.effThermal

    cpdef public double dpWf(self):
        return 0
    
    cpdef public double dpSf(self):
        return 0

    cdef public double _QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowsOut[0].h() - self.flowsIn[0].h()) > self.config.tolAbs:
            return (self.flowsOut[0].h() - self.flowsIn[0].h()
                    ) * self._mWf() * self._effFactorWf()
        else:
            return 0

    cdef public double _QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowsOut[1].h() - self.flowsIn[1].h()) > self.config.tolAbs:
            return (self.flowsOut[1].h() - self.flowsIn[1].h()
                    ) * self._mSf() * self._effFactorSf()
        else:
            return 0

    cpdef public double Q(self):
        """float: Heat transfer to the working fluid from the secondary fluid [W]."""
        cdef str err_msg
        cdef double qWf = self._QWf()
        cdef double qSf = self._QSf()
        cdef double tolAbs = self.config.tolAbs
        if abs(qWf) < tolAbs and abs(qSf) < tolAbs:
            return 0
        elif abs((qWf + qSf) / (qWf)) < self.config.tolRel:
            return qWf
        else:
            msg = """{}.Q(), QWf*{}={},QSf*{}={}. Check effThermal={} is correct.""".format(self.__class__.__name__,
            self._effFactorWf(), qWf, self._effFactorSf(), qSf,
            self.effThermal)
            log("error", msg)
            warn(msg)
            return qWf

    cpdef public double weight(self):
        """float: Estimate of weight [Kg], based purely on wall properties."""
        cdef HxUnitBasic unit
        cdef double w8 = 0
        for unit in self._units:
            w8 += unit.weight()
        return w8


    cdef bint _checkContinuous(self):
        """Check unitise() worked properly."""
        cdef int i
        cdef bint ifbool = True
        for i in range(1, len(self._units)):
            if self._units[i].flowsIn[0] != self._units[i - 1].flowsOut[0]:
                ifbool = False
        #if all(self._units[i].flowsIn[0] == self._units[i - 1].flowsOut[0] for i in range(1, len(self._units))):
        if ifbool:
            if "counter" in self.flowSense.lower() and all(
                    self._units[i].flowsOut[1] == self._units[i - 1].flowsIn[1]
                    for i in range(1, len(self._units))):
                return True
            elif "parallel" in self.flowSense.lower() and all(
                    self._units[i].flowsIn[1] == self._units[i - 1].flowsOut[1]
                    for i in range(1, len(self._units))):
                return True
            else:
                return False
        else:
            return False

    cpdef public void run(self):
        """Abstract method: must be defined by subclasses."""
        pass


    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to single-phase liquid HxUnits in unitise()."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall,
                self.hWf_liq, self.hSf, self.RfWf, self.RfSf, self.wall,
                self.tWall, nan, self.ARatioWf, self.ARatioSf,
                self.ARatioWall, self.effThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to two-phase HxUnits in unitise()."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, nan,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.effThermal)

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to single-phase vapour HxUnits in unitise()."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, nan,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.effThermal)

    cpdef public void unitise(self):
        """Divides the Hx into HxUnits according to divT and divX defined in the configuration parameters, for calculating accurate heat transfer properties."""
        self._units = []
        cdef list _units = []
        cdef _unitClass = self._unitClass
        cdef FlowState inWf = self.flowsIn[0]._copy({})
        cdef double inWf_h = inWf.h()
        cdef FlowState liqWf = self.flowsIn[0].copyState(CP.PQ_INPUTS, self.flowsIn[0].p(), 0)
        cdef double liqWf_h = liqWf.h()
        cdef FlowState vapWf = self.flowsIn[0].copyState(CP.PQ_INPUTS, self.flowsIn[0].p(), 1)
        cdef double vapWf_h = vapWf.h()
        cdef FlowState outWf = self.flowsOut[0]._copy({})
        cdef double outWf_h = outWf.h()
        cdef FlowState inSf = self.flowsIn[1]._copy({})
        cdef double inSf_h = inSf.h()
        cdef FlowState outSf = self.flowsOut[1]._copy({})
        cdef double outSf_h = outSf.h()
        cdef FlowState wfX0_obj = None
        cdef FlowState sfX0_obj = None
        cdef FlowState wfX1_obj = None
        cdef FlowState sfX1_obj = None
        cdef str wfX0_key = ""
        cdef str sfX0_key = ""
        cdef str wfX1_key = ""
        cdef str sfX1_key = ""
        cdef bint endFound, isEvap = self.isEvap()
        cdef double hLiqSf = nan
        cdef double hVapSf = nan
        cdef size_t i, N_units, flowSense
        cdef FlowState wf_i, wf_i1, sf_i, sf_i1
        cdef HxUnitBasic unit
        cdef double[:] hWf_unit, hSf_unit
        if self.flowSense == "counter":
            flowSense = 0
        elif self.flowSense == "parallel":
            flowSense = 1
        if isEvap:
            wfX0_obj = inWf
            wfX0_key = "flowInWf"
            wfX1_key = "flowOutWf"
            if flowSense == 0:
                sfX0_obj = outSf
                sfX0_key = "flowOutSf"
                sfX1_key = "flowInSf"
            elif flowSense == 1:
                sfX0_obj = inSf
                sfX0_key = "flowInSf"
                sfX1_key = "flowOutSf"
        else:
            wfX0_obj = outWf
            wfX0_key = "flowOutWf"
            wfX1_key = "flowInWf"
            if flowSense == 0:
                sfX0_obj = inSf
                sfX0_key = "flowInSf"
                sfX1_key = "flowOutSf"
            elif flowSense == 1:
                sfX0_obj = outSf
                sfX0_key = "flowOutSf"
                sfX1_key = "flowInSf"
        endFound = False
        # Section A
        if endFound is False and wfX0_obj.h() < liqWf_h and wfX0_obj.x() < -TOLABS_X:
            if isEvap:
                if outWf_h > liqWf_h:
                    wfX1_obj = liqWf
                    if flowSense == 0:
                        hLiqSf = sfX0_obj.h() + self._mWf() * self._effFactorWf() * (
                            liqWf_h - wfX0_obj.h()
                        ) / self._mSf() / self._effFactorSf()
                    elif flowSense == 1:
                        hLiqSf = sfX0_obj.h() - self._mWf() * self._effFactorWf() * (
                            liqWf_h - wfX0_obj.h()
                        ) / self._mSf() / self._effFactorSf()
                    sfX1_obj = inSf.copyState(CP.HmassP_INPUTS, hLiqSf, inSf.p())
                else:
                    endFound = True
                    wfX1_obj = outWf
                    if flowSense == 0:
                        sfX1_obj = inSf
                    elif flowSense == 1:
                        sfX1_obj = outSf
            else:  # not isEvap
                if inWf_h > liqWf_h:
                    wfX1_obj = liqWf
                    if flowSense == 0:
                        hLiqSf = sfX0_obj.h() + self.mWf * self._effFactorWf() * (
                            liqWf_h - wfX0_obj.h()
                        ) / self.mSf / self._effFactorSf()
                    elif flowSense == 1:
                        hLiqSf = sfX0_obj.h() - self.mWf * self._effFactorWf() * (
                            liqWf_h - wfX0_obj.h()
                        ) / self.mSf / self._effFactorSf()
                    sfX1_obj = inSf.copyState(CP.HmassP_INPUTS, hLiqSf, inSf.p())
                else:
                    endFound = True
                    wfX1_obj = inWf
                    if flowSense == 0:
                        sfX1_obj = outSf
                    elif flowSense == 1:
                        sfX1_obj = inSf
        else:
            wfX0_key = ""
            # wfX1_key = None
        #
        if wfX0_key != "":
            assert (
                wfX1_obj.h() - wfX0_obj.h()
            ) > 0, "Subcooled region: {}, h={} lower enthalpy than {}, h={}".format(
                wfX1_key, wfX1_obj.h(), wfX0_key, wfX0_obj.h())
            N_units = int(
                np.ceil((wfX1_obj.T() - wfX0_obj.T()) / self.config.divT)) + 1
            hWf_unit = np.linspace(wfX0_obj.h(), wfX1_obj.h(), N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h(), sfX1_obj.h(), N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i], inWf.p())
                wf_i1 = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p())
                sf_i = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i], inSf.p())

                sf_i1 = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p())
                unit = _unitClass(
                    *self._unitArgsLiq(),
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config)
                if isEvap:
                    _units.append(unit)
                else:
                    _units.insert(0, unit)
            wfX0_obj = wfX1_obj
            sfX0_obj = sfX1_obj
        # Section B
        if endFound is False and wfX0_obj.h() < vapWf_h:
            if isEvap:
                wfX0_key = "flowInWf"
                if outWf_h > vapWf_h:
                    wfX1_obj = vapWf
                    if flowSense == 0:
                        hVapSf = sfX0_obj.h() + self._mWf() * self._effFactorWf() * (
                            vapWf_h - wfX0_obj.h()
                        ) / self._mSf() / self._effFactorSf()
                    elif flowSense == 1:
                        hVapSf = sfX0_obj.h() - self.mWf * self._effFactorWf() * (
                            vapWf_h - wfX0_obj.h()
                        ) / self._mSf() / self._effFactorSf()
                    sfX1_obj = inSf.copyState(CP.HmassP_INPUTS, hVapSf, inSf.p())
                else:
                    endFound = True
                    wfX1_obj = outWf
                    if flowSense == 0:
                        sfX1_obj = inSf
                    elif flowSense == 1:
                        sfX1_obj = outSf
            else:  # not isEvap
                wfX0_key = "flowOutWf"
                if inWf_h > vapWf_h:
                    wfX1_obj = vapWf
                    if flowSense == 0:
                        hVapSf = sfX0_obj.h() + self.mWf * self._effFactorWf() * (
                            vapWf_h - wfX0_obj.h()
                        ) / self.mSf / self._effFactorSf()
                    elif flowSense == 1:
                        hVapSf = sfX0_obj.h() - self.mWf * self._effFactorWf() * (
                            vapWf_h - wfX0_obj.h()
                        ) / self.mSf / self._effFactorSf()
                    sfX1_obj = inSf.copyState(CP.HmassP_INPUTS, hVapSf, inSf.p())
                else:
                    endFound = True
                    wfX1_obj = inWf
                    if flowSense == 0:
                        sfX1_obj = outSf
                    elif flowSense == 1:
                        sfX1_obj = inSf
        else:
            wfX0_key = ""
            # wfX1_key = None
        #
                 
        if wfX0_key != "":
            assert (wfX1_obj.x() - wfX0_obj.x()
                    ) > 0, "Two-phase region: {}, x={} lower quality than {}, x={}".format(
                        wfX1_key,wfX1_obj.x(), wfX0_key,wfX0_obj.x())
            N_units = int(
                np.ceil((wfX1_obj.x() - wfX0_obj.x()) / self.config.divX)) + 1
            hWf_unit = np.linspace(wfX0_obj.h(), wfX1_obj.h(), N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h(), sfX1_obj.h(), N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i], inWf.p())
                wf_i1 = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p())
                sf_i = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i], inSf.p())
                sf_i1 = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p())
                unit = _unitClass(
                    *self._unitArgsTp(),
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config)
                if isEvap:
                    _units.append(unit)
                else:
                    _units.insert(0, unit)
            wfX0_obj = wfX1_obj
            sfX0_obj = sfX1_obj

        # Section C
        if endFound is False and (wfX0_obj.h() - vapWf_h
                                  ) / vapWf_h >= self.config._tolRel_h or (
                                      1 - wfX0_obj.x()) < TOLABS_X:
            if isEvap:
                wfX0_key = "flowInWf"
                wfX1_obj = outWf
                if flowSense == 0:
                    sfX1_obj = inSf
                elif flowSense == 1:
                    sfX1_obj = outSf
            else:  # not isEvap
                wfX0_key = "flowOutWf"
                wfX1_obj = inWf
                if flowSense == 0:
                    sfX1_obj = outSf
                elif flowSense == 1:
                    sfX1_obj = inSf
        else:
            wfX0_key = ""
            # wfX1_key = None
        #
        if wfX0_key != "" and (wfX1_obj.h() - vapWf_h
                                     ) / vapWf_h >= self.config._tolRel_h:
            assert (
                (wfX1_obj.h() - wfX0_obj.h())
            ) / wfX0_obj.h() > self.config._tolRel_h, "Superheated region: {}, h={} lower enthalpy than {}, h={}".format(
                wfX1_key, wfX1_obj.h(), wfX0_key, wfX0_obj.h())
            N_units = int(
                np.ceil((wfX1_obj.T() - wfX0_obj.T()) / self.config.divT)) + 1
            hWf_unit = np.linspace(wfX0_obj.h(), wfX1_obj.h(), N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h(), sfX1_obj.h(), N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i], inWf.p())
                wf_i1 = inWf.copyState(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p())
                sf_i = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i], inSf.p())
                sf_i1 = inSf.copyState(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p())
                unit = _unitClass(
                    *self._unitArgsVap(),
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config)
                if isEvap:
                    _units.append(unit)
                else:
                    _units.insert(0, unit)
        if self._checkContinuous():
            self._units = _units
        else:
            log("critical", "HxUnits are not in continuous order")
            raise ValueError("HxUnits are not in continuous order")

        
    cpdef double _f_sizeHxBasic(self, double value, str attr, list unitsBounds):
        self.update({attr: value})
        A_units = 0.
        for unit in self._units:
            unit.sizeUnits('A', unitsBounds)
            A_units += unit.A
        return A_units - self._A()
                
    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.

unitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. If None, self.sizeUnitsBounds is used. Defaults to None.
        """
        cdef double hOutSf, A_unitstol
        cdef HxUnitBasic unit
        if attr == "":
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            if attr == "A":
                self.unitise()
                A_units = 0.
                for unit in self._units:
                    unit.sizeUnits('A', unitsBounds)
                    A_units += unit._A()
                self.A = A_units
                # return self._A()
            elif attr == "flowOutSf":
                hOutSf = self.flowsIn[1].h() + (
                    self.flowsIn[0].h() - self.flowsOut[0].h()
                ) * self._mWf() * self._effFactorWf() / self._mSf() / self._effFactorSf()
                self.flowsOut[1] = self.flowsIn[1].copyState(CP.HmassP_INPUTS, hOutSf,
                                                    self.flowsIn[1].p())
                self.unitise()
                # return self.flowsOut[1]
            else:
                self.unitise()

                tol = self.config.tolAbs + self.config.tolRel * abs(self.Q())
                if len(bounds) == 2:
                    sizedValue = opt.brentq(
                        self._f_sizeHxBasic,
                        bounds[0],
                        bounds[1],
                        args=(attr, unitsBounds),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(bounds) == 1:
                    sizedValue = opt.newton(self._f_sizeHxBasic, bounds[0], args=(attr, unitsBounds), tol=tol)
                else:
                    raise ValueError("bounds is not valid (given: {})".format(bounds))
                self.update({attr, sizedValue})
                #return sizedValue
        except AssertionError as err:
            raise err
        except:
            raise StopIteration(
                "Warning: {}.size({},{},{}) failed to converge.".format(
                    self.__class__.__name__, attr, bounds, unitsBounds))

    @property
    def hWf(self):
        """float: Average of hWf_liq, hWf_tp & hWf_vap.
        Setter makes all equal to desired value."""
        return (self.hWf_liq + self.hWf_tp + self.hWf_vap) / 3

    @hWf.setter
    def hWf(self, value):
        self.hWf_liq = value
        self.hWf_tp = value
        self.hWf_vap = value

    @property
    def hWf_sp(self):
        """float: Average of hWf_liq & hWf_vap.
        Setter makes both equal to desired value."""
        return (self.hWf_liq + self.hWf_vap) / 2

    @hWf_sp.setter
    def hWf_sp(self, value):
        self.hWf_liq = value
        self.hWf_vap = value

    @property
    def Rf(self):
        """float: Average of RfWf & RfSf.
        Setter makes both equal to desired value."""
        return (self.RfWf + self.RfSf) / 2

    @Rf.setter
    def Rf(self, value):
        self.RfWf = value
        self.RfSf = value

