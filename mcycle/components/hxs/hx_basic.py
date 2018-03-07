from warnings import warn
from ...DEFAULTS import TOLABS_X, TOLREL, TOLABS
from ...bases import Component22, Config
from .hxunits import HxUnitBasic
import numpy as np
import scipy.optimize as opt
import CoolProp as CP


class HxBasic(Component22):
    r"""Characterises a basic heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counterflow" or "parallel". Defaults to "counterflow".
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
UWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
UWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
UWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
USf : float, optional
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
flowDeadSf : FlowState, optional
    Secondary fluid in its local dead state. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to "N".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [1, 100].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
solveBracketUnits : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of solve() for the unit. Typically this bracket is used to solve for the length of the HxUnit. Defaults to [1e-5, 1.].
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
                 flowSense="counterflow",
                 NWf=1,
                 NSf=1,
                 NWall=1,
                 hWf_liq=float("nan"),
                 hWf_tp=float("nan"),
                 hWf_vap=float("nan"),
                 hSf=float("nan"),
                 RfWf=0,
                 RfSf=0,
                 wall=None,
                 tWall=float("nan"),
                 A=float("nan"),
                 ARatioWf=1,
                 ARatioSf=1,
                 ARatioWall=1,
                 effThermal=1.0,
                 flowInWf=None,
                 flowInSf=None,
                 flowOutWf=None,
                 flowOutSf=None,
                 flowDeadSf=None,
                 solveAttr="N",
                 solveBracket=[1, 100],
                 solveBracketUnits=[1e-5, 1.],
                 name="HxBasic instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
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
        self.flowDeadSf = flowDeadSf
        self.solveBracketUnits = solveBracketUnits
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, solveAttr,
                         solveBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)
        self._units = []
        self._unitClass = HxUnitBasic
        if self.hasInAndOut("Wf") and self.hasInAndOut("Sf"):
            pass  # self._unitise()

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (
            ("flowSense", "none"), ("NWf", "none"), ("NSf", "none"),
            ("NWall", "none"), ("UWf_liq", "htc"), ("UWf_tp", "htc"),
            ("UWf_vap", "htc"), ("USf", "htc"), ("RfWf", "fouling"),
            ("RfSf", "fouling"), ("wall", "none"), ("tWall", "length"),
            ("RfWf", "fouling"), ("RfSf", "fouling"), ("A", "area"),
            ("ARatioWf", "none"), ("ARatioSf", "none"), ("ARatioWall", "none"),
            ("effThermal", "none"), ("flowInWf", "none"), ("flowInSf", "none"),
            ("flowOutWf", "none"), ("flowOutSf", "none"),
            ("solveAttr", "none"), ("solveBracket", "none"),
            ("solveBracketUnits", "none"), ("name", "none"), ("notes", "none"),
            ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("mSf", "mass/time"), ("Q", "power"),
                ("dpWf", "pressure"), ("dpSf", "pressure"), ("isEvap", "none")]

    @property
    def isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowInSf.T > self.flowInWf.T:
            return True
        else:
            return False

    def update(self, **kwargs):
        """Update (multiple) variables using keyword arguments."""
        for key, value in kwargs.items():
            if key not in [
                    "L", "flowInWf", "flowInSf", "flowOutWf", "flowOutSf"
            ]:
                setattr(self, key, value)
                for unit in self._units:
                    unit.update(**{key: value})
            else:
                setattr(self, key, value)
        # self.unitise()

    @property
    def _effFactorWf(self):
        if self.isEvap:
            return 1
        else:
            return self.effThermal

    @property
    def _effFactorSf(self):
        if not self.isEvap:
            return 1
        else:
            return self.effThermal

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

    @property
    def QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        QIn = self.flowInWf.h * self.mWf * self._effFactorWf
        QOut = self.flowOutWf.h * self.mWf * self._effFactorWf
        if abs((QOut - QIn)) > TOLABS:
            return QOut - QIn
        else:
            return 0

    @property
    def QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        QIn = self.flowInSf.h * self.mSf * self._effFactorSf
        QOut = self.flowOutSf.h * self.mSf * self._effFactorSf
        if abs((QOut - QIn)) > TOLABS:
            return QOut - QIn
        else:
            return 0

    @property
    def Q(self):
        """float: Heat transfer from the secondary fluid to the working fluid [W]."""
        err_msg = """QWf*{}={},QSf*{}={}. Check effThermal={} is correct.""".format(
            self._effFactorWf, self.QWf, self._effFactorSf, self.QSf,
            self.effThermal)
        if abs((self.QWf + self.QSf) / (self.QWf)) < TOLREL:
            return self.QWf
        else:
            warn(err_msg)
            return self.QWf

    def _checkContinuous(self):
        """Check unitise() worked properly."""
        if all(self._units[i].flowInWf == self._units[i - 1].flowOutWf
               for i in range(1, len(self._units))):
            if "counter" in self.flowSense.lower() and all(
                    self._units[i].flowOutSf == self._units[i - 1].flowInSf
                    for i in range(1, len(self._units))):
                return True
            elif "parallel" in self.flowSense.lower() and all(
                    self._units[i].flowInSf == self._units[i - 1].flowOutSf
                    for i in range(1, len(self._units))):
                return True
            else:
                return False
        else:
            return False

    def run(self):
        """Not defined here, must be defined by subclasses."""
        pass

    @property
    def _unitArgsLiq(self):
        """Arguments passed to single-phase liquid HxUnits in unitise()."""
        return (self.isEvap, self.flowSense, self.NWf, self.NSf, self.NWall,
                self.hWf_liq, self.hSf, self.RfWf, self.RfSf, self.wall,
                self.tWall, None, self.ARatioWf, self.ARatioSf,
                self.ARatioWall, self.effThermal)

    @property
    def _unitArgsTp(self):
        """Arguments passed to two-phase HxUnits in unitise()."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.effThermal)

    @property
    def _unitArgsVap(self):
        """Arguments passed to single-phase vapour HxUnits in unitise()."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.effThermal)

    def unitise(self):
        """Divides the Hx into HxUnits according to divT and divX defined in the configuration parameters, for calculating accurate heat transfer properties."""
        self._units = []
        inWf = self.flowInWf.copy()
        liqWf = self.flowInWf.copy(CP.PQ_INPUTS, self.flowInWf.p, 0)
        vapWf = self.flowInWf.copy(CP.PQ_INPUTS, self.flowInWf.p, 1)
        outWf = self.flowOutWf.copy()
        inSf = self.flowInSf.copy()
        outSf = self.flowOutSf.copy()
        wfX0_obj = None
        sfX0_obj = None
        if self.isEvap:
            wfX0_obj = inWf
            wfX0_key = "flowInWf"
            wfX1_key = "flowOutWf"
            if "counter" in self.flowSense.lower():
                sfX0_obj = outSf
                sfX0_key = "flowOutSf"
                sfX1_key = "flowInSf"
            elif "parallel" in self.flowSense.lower():
                sfX0_obj = inSf
                sfX0_key = "flowInSf"
                sfX1_key = "flowOutSf"
        else:
            wfX0_obj = outWf
            wfX0_key = "flowOutWf"
            wfX1_key = "flowInWf"
            if "counter" in self.flowSense.lower():
                sfX0_obj = inSf
                sfX0_key = "flowInSf"
                sfX1_key = "flowOutSf"
            elif "parallel" in self.flowSense.lower():
                sfX0_obj = outSf
                sfX0_key = "flowOutSf"
                sfX1_key = "flowInSf"
        endFound = False
        # Section A
        # if wfX0_obj.h < liqWf.h:
        if endFound is False and wfX0_obj.h < liqWf.h and wfX0_obj.x < -TOLABS_X:
            if self.isEvap:
                if outWf.h > liqWf.h:
                    wfX1_obj = liqWf
                    if "counter" in self.flowSense.lower():
                        hLiqSf = sfX0_obj.h + self.mWf * self._effFactorWf * (
                            liqWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    elif "parallel" in self.flowSense.lower():
                        hLiqSf = sfX0_obj.h - self.mWf * self._effFactorWf * (
                            liqWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    sfX1_obj = inSf.copy(CP.HmassP_INPUTS, hLiqSf, inSf.p)
                else:
                    endFound = True
                    wfX1_obj = outWf
                    if "counter" in self.flowSense.lower():
                        sfX1_obj = inSf
                    elif "parallel" in self.flowSense.lower():
                        sfX1_obj = outSf
            else:  # not self.isEvap
                if inWf.h > liqWf.h:
                    wfX1_obj = liqWf
                    if "counter" in self.flowSense.lower():
                        hLiqSf = sfX0_obj.h + self.mWf * self._effFactorWf * (
                            liqWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    elif "parallel" in self.flowSense.lower():
                        hLiqSf = sfX0_obj.h - self.mWf * self._effFactorWf * (
                            liqWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    sfX1_obj = inSf.copy(CP.HmassP_INPUTS, hLiqSf, inSf.p)
                else:
                    endFound = True
                    wfX1_obj = inWf
                    if "counter" in self.flowSense.lower():
                        sfX1_obj = outSf
                    elif "parallel" in self.flowSense.lower():
                        sfX1_obj = inSf
        else:
            wfX0_key = None
            # wfX1_key = None
        #
        if wfX0_key is not None:
            assert (
                wfX1_obj.T - wfX0_obj.T
            ) > 0, "Subcooled region: {}, {} lower quality than {}, {}".format(
                wfX1_key, wfX1_obj.x, wfX0_key, wfX0_obj.x)
            N_units = int(
                np.ceil((wfX1_obj.T - wfX0_obj.T) / self.config.divT)) + 1
            hWf_unit = np.linspace(wfX0_obj.h, wfX1_obj.h, N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h, sfX1_obj.h, N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i], inWf.p)
                wf_i1 = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p)
                sf_i = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i], inSf.p)

                sf_i1 = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p)
                unit = self._unitClass(
                    *self._unitArgsLiq,
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    solveBracket=self.solveBracketUnits,
                    config=self.config)
                if self.isEvap:
                    self._units.append(unit)
                else:
                    self._units.insert(0, unit)
            wfX0_obj = wfX1_obj
            sfX0_obj = sfX1_obj
        # Section B
        if endFound is False and wfX0_obj.h < vapWf.h:
            if self.isEvap:
                wfX0_key = "flowInWf"
                if outWf.h > vapWf.h:
                    wfX1_obj = vapWf
                    if "counter" in self.flowSense.lower():
                        hVapSf = sfX0_obj.h + self.mWf * self._effFactorWf * (
                            vapWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    elif "parallel" in self.flowSense.lower():
                        hVapSf = sfX0_obj.h - self.mWf * self._effFactorWf * (
                            vapWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    sfX1_obj = inSf.copy(CP.HmassP_INPUTS, hVapSf, inSf.p)
                else:
                    endFound = True
                    wfX1_obj = outWf
                    if "counter" in self.flowSense.lower():
                        sfX1_obj = inSf
                    elif "parallel" in self.flowSense.lower():
                        sfX1_obj = outSf
            else:  # not self.isEvap
                wfX0_key = "flowOutWf"
                if inWf.h > vapWf.h:
                    wfX1_obj = vapWf
                    if "counter" in self.flowSense.lower():
                        hVapSf = sfX0_obj.h + self.mWf * self._effFactorWf * (
                            vapWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    elif "parallel" in self.flowSense.lower():
                        hVapSf = sfX0_obj.h - self.mWf * self._effFactorWf * (
                            vapWf.h - wfX0_obj.h
                        ) / self.mSf / self._effFactorSf
                    sfX1_obj = inSf.copy(CP.HmassP_INPUTS, hVapSf, inSf.p)
                else:
                    endFound = True
                    wfX1_obj = inWf
                    if "counter" in self.flowSense.lower():
                        sfX1_obj = outSf
                    elif "parallel" in self.flowSense.lower():
                        sfX1_obj = inSf
        else:
            wfX0_key = None
            # wfX1_key = None
        #
        if wfX0_key is not None:
            assert (wfX1_obj.x - wfX0_obj.x
                    ) > 0, "Two-phase region: {} lower quality than {}".format(
                        wfX1_key, wfX0_key)
            N_units = int(
                np.ceil((wfX1_obj.x - wfX0_obj.x) / self.config.divX)) + 1
            hWf_unit = np.linspace(wfX0_obj.h, wfX1_obj.h, N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h, sfX1_obj.h, N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i], inWf.p)
                wf_i1 = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p)
                sf_i = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i], inSf.p)
                sf_i1 = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p)
                unit = self._unitClass(
                    *self._unitArgsTp,
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    solveBracket=self.solveBracketUnits,
                    config=self.config)
                if self.isEvap:
                    self._units.append(unit)
                else:
                    self._units.insert(0, unit)
            wfX0_obj = wfX1_obj
            sfX0_obj = sfX1_obj

        # Section C
        # if wfX0_obj.h >= vapWf.h and wfX0_obj.x < -TOLABS_X:
        if endFound is False and (wfX0_obj.h - vapWf.h
                                  ) / vapWf.h >= self.config._tolRel_h or (
                                      1 - wfX0_obj.x) < TOLABS_X:
            if self.isEvap:
                wfX0_key = "flowInWf"
                wfX1_obj = outWf
                if "counter" in self.flowSense.lower():
                    sfX1_obj = inSf
                elif "parallel" in self.flowSense.lower():
                    sfX1_obj = outSf
            else:  # not self.isEvap
                wfX0_key = "flowOutWf"
                wfX1_obj = inWf
                if "counter" in self.flowSense.lower():
                    sfX1_obj = outSf
                elif "parallel" in self.flowSense.lower():
                    sfX1_obj = inSf
        else:
            wfX0_key = None
            # wfX1_key = None
        #
        if wfX0_key is not None and (wfX1_obj.h - vapWf.h
                                     ) / vapWf.h >= self.config._tolRel_h:
            assert (
                wfX1_obj.T - wfX0_obj.T
            ) / wfX0_obj.T > self.config._tolRel_T, "Superheated region: {}, T={} lower quality than {}, T={}".format(
                wfX1_key, wfX1_obj.T, wfX0_key, wfX0_obj.T)
            N_units = int(
                np.ceil((wfX1_obj.T - wfX0_obj.T) / self.config.divT)) + 1
            hWf_unit = np.linspace(wfX0_obj.h, wfX1_obj.h, N_units, True)
            hSf_unit = np.linspace(sfX0_obj.h, sfX1_obj.h, N_units, True)
            for i in range(N_units - 1):
                wf_i = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i], inWf.p)
                wf_i1 = inWf.copy(CP.HmassP_INPUTS, hWf_unit[i + 1], inWf.p)
                sf_i = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i], inSf.p)
                sf_i1 = inSf.copy(CP.HmassP_INPUTS, hSf_unit[i + 1], inSf.p)
                unit = self._unitClass(
                    *self._unitArgsVap,
                    **{wfX0_key: wf_i},
                    **{wfX1_key: wf_i1},
                    **{sfX0_key: sf_i},
                    **{sfX1_key: sf_i1},
                    solveBracket=self.solveBracketUnits,
                    config=self.config)
                if self.isEvap:
                    self._units.append(unit)
                else:
                    self._units.insert(0, unit)
        if not self._checkContinuous():
            self._units = []
            raise ValueError("HxUnits are not in continuous order")
        else:
            return None

    def solve(self, solveAttr=None, solveBracket=None, solveBracketUnits=None):
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
solveAttr : string, optional
    Attribute to be solved. If None, self.solveAttr is used. Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). If None, self.solveBracket is used. Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.

solveBracketUnits : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of solve() for the unit. If None, self.solveBracketUnits is used. Defaults to None.
        """
        if solveAttr is None:
            solveAttr = self.solveAttr
        if solveBracket is None:
            solveBracket = self.solveBracket
        if solveBracketUnits is None:
            solveBracketUnits = self.solveBracketUnits
        try:
            if solveAttr in "A":
                self.unitise()
                A_units = 0.
                for unit in self._units:
                    A_units += unit.solve("A", solveBracketUnits)
                self.A = A_units
                return self.A
            elif solveAttr == "flowOutSf":
                hOutSf = self.flowInSf.h + (
                    self.flowInWf.h - self.flowOutWf.h
                ) * self.mWf * self._effFactorWf / self.mSf / self._effFactorSf
                self.flowOutSf = self.flowInSf.copy(CP.HmassP_INPUTS, hOutSf,
                                                    self.flowInSf.p)
                self.unitise()
                return self.flowOutSf
            else:
                self.unitise()

                def f(value):
                    self.update(**{solveAttr: value})
                    A_units = 0.
                    for unit in self._units:
                        A_units += unit.solve("A", solveBracketUnits)
                    return A_units - self.A

                tol = self.config.tolAbs + self.config.tolRel * abs(self.Q)
                if len(solveBracket) == 2:
                    solvedValue = opt.brentq(
                        f,
                        solveBracket[0],
                        solveBracket[1],
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(solveBracket) == 1:
                    solvedValue = opt.newton(f, solveBracket[0], tol=tol)
                else:
                    solvedValue = opt.newton(f, solveBracket, tol=tol)
                setattr(self, solveAttr, solvedValue)
                return solvedValue
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.solve({},{}) failed to converge".format(
                    self.__class__.__name__, solveAttr, solveBracket))
