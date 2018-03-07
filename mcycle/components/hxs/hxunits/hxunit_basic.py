from warnings import warn
from ....DEFAULTS import TOLABS_X, TOLREL, TOLABS
from ....bases import Config, Component22
import CoolProp as CP
import numpy as np
import scipy.optimize as opt
import warnings


class HxUnitBasic(Component22):
    r"""Characterises a basic heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

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
solveAttr : string, optional
    Default attribute used by solve(). Defaults to "N".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [3, 100].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
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
                 flowSense="counterflow",
                 NWf=1,
                 NSf=1,
                 NWall=1,
                 hWf=float("nan"),
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
                 solveAttr="A",
                 solveBracket=[0.01, 10.0],
                 name="HxUnitBasic instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, solveAttr,
                         solveBracket, name, notes, config)
        self.flowSense = flowSense
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
        self.effThermal = effThermal
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("flowSense", "none"), ("NWf", "none"), ("NSf", "none"),
                ("NWall", "none"), ("hWf", "htc"), ("hSf", "htc"),
                ("RfWf", "fouling"), ("RfSf", "fouling"), ("wall", "none"),
                ("tWall", "length"), ("RfWf", "fouling"), ("RfSf", "fouling"),
                ("A", "area"), ("ARatioWf", "none"), ("ARatioSf", "none"),
                ("ARatioWall", "none"), ("effThermal", "none"),
                ("flowInWf", "none"), ("flowInSf", "none"),
                ("flowOutWf", "none"), ("flowOutSf", "none"),
                ("solveAttr", "none"), ("solveBracket", "none"),
                ("name", "none"), ("notes", "none"), ("config", "none"))

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
    def twoPhaseWf(self):
        """bool: Return True if working fluid is in 2-phase region."""
        if self.hasInAndOut("Wf"):
            if self.flowInWf.x >= -self.config._tolAbs_x and self.flowInWf.x <= 1 + self.config._tolAbs_x and self.flowOutWf.x >= -self.config._tolAbs_x and self.flowOutWf.x <= 1 + self.config._tolAbs_x:
                return True
            else:
                return False
        elif self.isEvap:
            if self.flowInWf.x >= -self.config._tolAbs_x and self.flowInWf.x < 1:
                return True
            else:
                return False
        elif not self.isEvap:
            if self.flowInWf.x > 0 and self.flowInWf.x <= 1 + self.config._tolAbs_x:
                return True
            else:
                return False

    @property
    def phaseWf(self):
        """str: Identifier of working fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'tpEvap' or 'tpCond': evaporating or condensing in two-phase liq/vapour region."""
        if self.hasInAndOut("wf"):
            if self.flowInWf.phase == "satLiq":
                if self.flowOutWf.phase == "tp":
                    return "tpEvap"
                elif self.flowOutWf.phase == "liq":
                    return "liq"
                else:
                    raise ValueError(
                        "could not determine phase of WF flow. flowIn={}, flowOut={}".
                        format(self.flowInWf.phase, self.flowOutWf.phase))
            elif self.flowInWf.phase == "satVap":
                if self.flowOutWf.phase == "tp":
                    return "tpCond"
                elif self.flowOutWf.phase == "vap":
                    return "vap"
                else:
                    raise ValueError(
                        "could not determine phase of WF flow. flowIn={}, flowOut={}".
                        format(self.flowInWf.phase, self.flowOutWf.phase))
            elif self.flowInWf.phase == "tp" and self.flowOutWf.phase == "satLiq":
                return "tpCond"
            elif self.flowInWf.phase == "tp" and self.flowOutWf.phase == "satVap":
                return "tpEvap"
            elif self.flowInWf.phase == "tp" and self.flowOutWf.phase == "tp":
                if self.flowInWf.h < self.flowOutWf.h:
                    return "tpEvap"
                else:
                    return "tpCond"
            elif self.flowInWf.phase == "liq" or self.flowOutWf.phase == "liq":
                return "liq"
            elif self.flowInWf.phase == "vap" or self.flowOutWf.phase == "vap":
                return "vap"
            else:
                raise ValueError(
                    "could not determine phase of WF flow. flowIn={}, flowOut={}".
                    format(self.flowInWf.phase, self.flowOutWf.phase))
        else:
            if self.flowInWf.phase == "tp":
                if self.flowInWf.T < self.flowInSf.T:
                    return "tpEvap"
                else:
                    return "tpCond"

            elif self.flowInWf.phase == "satLiq":
                if self.flowInWf.T < self.flowInSf.T:
                    return "tpEvap"
                else:
                    return "liq"
            elif self.flowInWf.phase == "satVap":
                if self.flowInWf.T < self.flowInSf.T:
                    return "vap"
                else:
                    return "tpCond"

            elif self.flowInWf.phase == "liq":

                return "liq"
            elif self.flowInWf.phase == "vap":
                return "vap"
            else:
                raise ValueError(
                    "Could not determine phase of WF flow. flowIn={}, flowOut={}".
                    format(self.flowInWf.phase, self.flowOutWf.phase))

    @property
    def phaseSf(self):
        """str: Identifier of secondary fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'sp': unknown single-phase."""
        if self.hasInAndOut("sf"):
            if self.flowInSf.phase == "liq" or self.flowOutSf.phase == "liq":
                return "liq"
            elif self.flowInSf.phase == "vap" or self.flowOutSf.phase == "vap":
                return "vap"
            elif self.flowInSf.phase == "sp" or self.flowOutSf.phase == "sp":
                return "sp"
        else:
            if self.flowInSf.phase == "liq":
                return "liq"
            elif self.flowInSf.phase == "vap":
                return "vap"
            elif self.flowInSf.phase == "sp":
                return "sp"

    @property
    def QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowOutWf.h - self.flowInWf.h) > TOLABS:
            return (self.flowOutWf.h - self.flowInWf.h
                    ) * self.mWf * self._effFactorWf
        else:
            return 0

    @property
    def QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowOutSf.h - self.flowInSf.h) > TOLABS:
            return (self.flowOutSf.h - self.flowInSf.h
                    ) * self.mSf * self._effFactorSf
        else:
            return 0

    @property
    def Q(self):
        """float: Heat transfer from the secondary fluid to the working fluid [W]."""
        err_msg = """QWf*{}={},QSf*{}={}. Check effThermal={} is correct.""".format(
            self._effFactorWf, self.QWf, self._effFactorSf, self.QSf,
            self.effThermal)
        # print("QWf = ", self.QWf, "  QSf = ", self.QSf)
        if abs(self.QWf) < TOLABS and abs(self.QSf) < TOLABS:
            return 0
        elif abs((self.QWf + self.QSf) / (self.QWf)) < TOLREL:
            return self.QWf
        else:
            warn(err_msg)
            return self.QWf

    @property
    def N(self):
        """int: Number of flow channels, returns average of NWf & NSf.
        Setter makes both equal to desired value."""
        return (self.NWf + self.NSf) / 2.

    @N.setter
    def N(self, value):
        self.NWf = value
        self.NSf = value

    @property
    def U(self):
        """float: Overall heat transfer coefficient [W/m^2.K]; heat transfer coefficients of each flow channel and wall, summed in series."""
        RWf = 1 / self.hWf / self.ARatioWf / self.NWf + self.RfWf / self.ARatioWf / self.NWf
        RSf = 1 / self.hSf / self.ARatioSf / self.NSf + self.RfSf / self.ARatioSf / self.NSf
        RWall = self.tWall / self.wall.k / self.ARatioWall / self.NWall
        return (RWf + RSf + RWall)**-1

    @property
    def LMTD(self):
        """float: Log-mean temperature difference [K]"""
        if "counter" in self.flowSense.lower():
            dT1 = self.flowInSf.T - self.flowOutWf.T
            dT2 = self.flowOutSf.T - self.flowInWf.T
        elif "parallel" in self.flowSense.lower():
            dT1 = self.flowOutSf.T - self.flowOutWf.T
            dT2 = self.flowInSf.T - self.flowInWf.T
        ans = (dT1 - dT2) / np.log(dT1 / dT2)
        if np.isnan(ans):
            warnings.warn(
                "LMTD found non valid flow temperatures: flowInWf={}, flowOutWf={}, flowInSf={}, flowOutSf={}".
                format(self.flowInWf.T, self.flowOutWf.T, self.flowInSf.T,
                       self.flowOutSf.T))
        return ans

    @property
    def Q_LMTD(self):
        """float: Heat transfer rate to the working fluid [W] as calculated using the log-mean temperature difference method."""
        return self.U * self.A * self.LMTD

    def weight(self):
        """float: Estimate of weight [Kg], based purely on wall properties."""
        return self.A * self.ARatioWall * self.tWall * self.wall.rho * self.NWall

    def run(self):
        """Run the HX from the incoming FlowState, using the epsilon-NTU method to produce an initial solution estimate."""
        # initial guess from e-NTU method
        eps = 0.8
        Cmin = min(self.flowInWf.cp * self.mWf, self.flowInSf.cp * self.mSf)
        q = eps * Cmin * (self.flowInSf.T - self.flowInWf.T) * self.effThermal
        self.flowOutWf = self.flowInWf.copy(
            CP.HmassP_INPUTS, self.flowInWf.h + q / self.mWf, self.flowInWf.p)
        self.flowOutSf = self.flowInSf.copy(
            CP.HmassP_INPUTS, self.flowInSf.h - self.mWf * self._effFactorWf *
            (self.flowOutWf.h - self.flowInWf.h
             ) / self.mSf / self._effFactorSf, self.flowInSf.p)
        diff = abs(self.Q - self.Q_LMTD) / self.Q
        count = 0
        while diff > self.config._tolRel_h:
            q = self.Q_LMTD
            self.flowOutWf = self.flowInWf.copy(
                CP.HmassP_INPUTS,
                self.flowInWf.h + q / self._effFactorWf / self.mWf,
                self.flowInWf.p)
            self.flowOutSf = self.flowInSf.copy(
                CP.HmassP_INPUTS,
                self.flowInSf.h - q / self._effFactorSf / self.mSf,
                self.flowInSf.p)
            diff = abs(self.Q - q) / self.Q

            count += 1
            if count > self.config.maxIterationsCycle:
                raise StopIteration(
                    """{} iterations without {} converging: diff={}>tol={}""".
                    format(self.config.maxIterationsCycle, "h", diff,
                           self.config._tolRel_h))
        return self.flowOutWf

    def solve(self, solveAttr=None, solveBracket=None):
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
solveAttr : string, optional
    Component attribute to be solved. If None, self.solveAttr is used. Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). If None, self.solveBracket is used. Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
        """
        if solveAttr is None:
            solveAttr = self.solveAttr
        if solveBracket is None:
            solveBracket = self.solveBracket
        try:
            if solveAttr == "A":
                self.A = 1.
                self.A = self.Q / self.Q_LMTD
                return self.A
            else:

                def f(value):
                    self.update(**{solveAttr: value})
                    return self.Q - self.Q_LMTD

                tol = self.config.tolAbs + self.config.tolRel * self.Q
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
                self.update(**{solveAttr: solvedValue})
                return solvedValue
        except AssertionError as err:
            raise (err)
        except:
            raise Exception(
                "Warning: {}.solve({},{}) failed to converge".format(
                    self.__class__.__name__, solveAttr, solveBracket))
