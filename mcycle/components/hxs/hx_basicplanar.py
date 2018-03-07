from ...DEFAULTS import TOLABS, MAXITERATIONSCOMPONENT, MAXWALLS
from .hx_basic import HxBasic
from .hxunits import HxUnitBasicPlanar
from ...bases import Config
import scipy.optimize as opt
import CoolProp as CP


class HxBasicPlanar(HxBasic):
    r"""Characterises a basic planar heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

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
hWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
hWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
hWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid in a single-phase region. Defaults to nan.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
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
    Description of object. Defaults to "HxBasicPlanar instance".
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
                 L=float("nan"),
                 W=float("nan"),
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
                 name="HxBasicPlanar instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)

        self.L = L
        self.W = W
        super().__init__(flowSense, NWf, NSf, NWall, hWf_liq, hWf_tp, hWf_vap,
                         hSf, RfWf, RfSf, wall, tWall, L * W, ARatioWf,
                         ARatioSf, ARatioWall, effThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, flowDeadSf, solveAttr,
                         solveBracket, solveBracketUnits, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)
        self._units = []
        self._unitClass = HxUnitBasicPlanar
        if self.hasInAndOut("Wf") and self.hasInAndOut("Sf"):
            pass  # self._unitise()

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("flowSense", "none"), ("NWf", "none"), ("NSf", "none"),
                ("NWall", "none"), ("hWf_liq", "htc"), ("hWf_tp", "htc"),
                ("hWf_vap", "htc"), ("hSf", "htc"), ("RfWf", "fouling"),
                ("RfSf", "fouling"), ("wall", "none"), ("tWall", "length"),
                ("L", "length"), ("W", "length"), ("ARatioWf", "none"),
                ("ARatioSf", "none"), ("ARatioWall", "none"),
                ("effThermal", "none"), ("flowInWf", "none"),
                ("flowInSf", "none"), ("flowOutWf", "none"),
                ("flowOutSf", "none"), ("solveAttr", "none"),
                ("solveBracket", "none"), ("solveBracketUnits", "none"),
                ("name", "none"), ("notes", "none"), ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("mSf", "mass/time"), ("Q", "power"),
                ("A", "area"), ("dpWf", "pressure"), ("dpSf", "pressure"),
                ("isEvap", "none")]

    @property
    def A(self):
        """float: Heat transfer surface area. A = L * W.
        Setter preserves the ratio of L/W."""
        return self.L * self.W

    @A.setter
    def A(self, value):
        if self.L and self.W:
            a = self.L * self.W
            self.L *= (value / a)**0.5
            self.W *= (value / a)**0.5
        else:
            pass

    @property
    def _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_liq,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    @property
    def _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    @property
    def _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    def solve_L(self, solveBracketUnits=None):
        """float: Solve for the required length of the Hx to satisfy the heat transfer equations [m]."""
        if solveBracketUnits is None:
            solveBracketUnits = self.solveBracketUnits
        L = 0.
        for unit in self._units:
            if abs(unit.Q) > TOLABS:
                L += unit.solve("L", solveBracketUnits)
        self.L = L
        return L

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
            if solveAttr == "L":
                self.unitise()
                L = 0.
                for unit in self._units:
                    L += unit.solve("L", solveBracketUnits)
                self.L = L
                return L
            elif solveAttr == "flowOutSf":
                super().solve(solveAttr, solveBracket, solveBracketUnits)
            else:
                self.unitise()
                L = self.L

                def f(value):
                    self.update(**{solveAttr: value})
                    return self.solve_L(solveBracketUnits) - L

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
