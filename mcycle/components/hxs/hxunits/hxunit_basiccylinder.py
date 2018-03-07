from .hxunit_basic import HxUnitBasic
from ....bases import Config


class HxUnitBasicCylinder(HxUnitBasic):
    r"""Characterises a basic cylindrical heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

.. note:: Heat transfer calculation are based on the outer area of the cylinder (AOut=pi*DOut*L).


Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counterflow" or "parallel". Defaults to "counterflow".
innnerWf : bool, optional
    True if the working fluid is the inner fluid. Defaults to True.
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
UWf : float, optional
    Heat transfer coefficient of the working fluid. Defaults to nan.
USf : float, optional
    Heat transfer coefficient of the secondary fluid. Defaults to nan.
RfWf : float, optional
    Thermal resistance factor due to fouling on the working fluid side [m^2K/W]. Defaults to 0.
RfSf : float, optional
    Thermal resistance factor due to fouling on the secondary fluid side [m^2K/W]. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
DOut : float, optional
    Outer diameter of the cylindrical wall (dimension perpendicular to flow direction) [m]. Defaults to nan.
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
                 innerWf=True,
                 NWf=1,
                 NSf=1,
                 NWall=1,
                 UWf=float("nan"),
                 USf=float("nan"),
                 RfWf=0,
                 RfSf=0,
                 wall=None,
                 tWall=float("nan"),
                 L=float("nan"),
                 DOut=float("nan"),
                 effThermal=1.0,
                 flowInWf=None,
                 flowInSf=None,
                 flowOutWf=None,
                 flowOutSf=None,
                 solveAttr="L",
                 solveBracket=[0.01, 10.0],
                 name="HxUnitBasic instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{0} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
        self.innerWf = innerWf
        self.L = L
        self.DOut = DOut
        super().__init__(flowSense, NWf, NSf, NWall, UWf, USf, RfWf, RfSf,
                         wall, tWall, L * DOut * np.pi, None, None, None,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         solveAttr, solveBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor"""
        return (self.flowSense, self.innerWf, self.NWf, self.NSf, self.NWall,
                self.UWf, self.USf, self.wall, self.tWall, self.RfWf,
                self.RfSf, self.L, self.DOut, self.effThermal, self.flowInWf,
                self.flowInSf, self.flowOutWf, self.flowOutSf, self.solveAttr,
                self.solveBracket, self.name, self.notes, self.config)

    @property
    def DIn(self):
        """float: cylinder inner diameter [m]."""
        return self.DOut - 2 * self.tWall

    @DIn.setter
    def DIn(self, value):
        self.DOut = value + 2 * self.tWall

    @property
    def DWf(self):
        """float: characteristic diameter of working fluid flow [m]."""
        if self.innerWf:
            return self.DIn
        else:
            return self.DOut

    @DWf.setter
    def DWf(self, value):
        if self.innerWf:
            self.DIn = value
        else:
            self.DOut = value

    @property
    def DSf(self):
        """float: characteristic diameter of secondary fluid flow [m]."""
        if self.innerWf:
            return self.DOut
        else:
            return self.DIn

    @DSf.setter
    def DSf(self, value):
        if self.innerWf:
            self.DOut = value
        else:
            self.DIn = value

    @property
    def rOut(self):
        """float: cylinder outer radius [m]."""
        return self.DOut / 2

    @rOut.setter
    def rOut(self, value):
        self.DOut = value * 2

    @property
    def rIn(self):
        """float: cylinder inner radius [m]."""
        return self.DIn / 2

    @rIn.setter
    def rIn(self, value):
        self.DIn = value * 2

    @property
    def rWf(self):
        """float: characteristic radius of working fluid flow [m]."""
        if self.innerWf:
            return self.rIn
        else:
            return self.rOut

    @rWf.setter
    def rWf(self, value):
        if self.innerWf:
            self.rIn = value
        else:
            self.rOut = value

    @property
    def rSf(self):
        """float: characteristic radius of secondary fluid flow [m]."""
        if self.innerWf:
            return self.rOut
        else:
            return self.rIn

    @rSf.setter
    def rSf(self, value):
        if self.innerWf:
            self.rOut = value
        else:
            self.rIn = value

    @property
    def AOut(self):
        """float: AOut = L * DOut * pi.
        Setter preserves the ratio of L/DOut."""
        return self.L * self.DOut * np.pi

    @AOut.setter
    def AOut(self, value):
        if self.L and self.DOut:
            a = self.L * self.DOut * np.pi
            self.L *= (value / a)**0.5
            self.DOut *= (value / a)**0.5
        else:
            pass

    @property
    def AIn(self):
        """float: AIn = L * DIn * pi.
        Setter preserves the ratio of L/DIn."""
        return self.L * self.DIn * np.pi

    @AIn.setter
    def AIn(self, value):
        if self.L and self.DIn:
            a = self.L * self.DIn * np.pi
            self.L *= (value / a)**0.5
            self.DIn *= (value / a)**0.5
        else:
            pass

    @property
    def A(self):
        """float: alias of AOut."""
        return self.AOut

    @A.setter
    def A(self, value):
        self.AOut = value

    @property
    def ARatioWf(self):
        """float: Area ratio of working fluid heat transfer area to outer cylinder area."""
        return self.AWf / self.AOut

    @property
    def ARatioSf(self):
        """float: Area ratio of secondary fluid heat transfer area to outer cylinder area."""
        return self.ASf / self.AOut

    @property
    def ARatioWall(self):
        """float: Area ratio of wall heat transfer area to outer cylinder area."""
        return 2 * self.tWall / self.DOut / np.log(self.DOut / self.DIn)

    def solve(self, solveAttr=None, solveBracket=None):
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
solveAttr : string, optional
    Attribute to be solved. If None, self.solveAttr is used. Defaults to None.
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
            if solveAttr in ["L"]:
                setattr(self, solveAttr, 1.)
                setattr(self, solveAttr, self.Q / self.Q_LMTD)
                return getattr(self, self.solveAttr)
            else:
                super().solve(solveAttr, solveBracket)
        except:
            raise Exception(
                "Warning: {0}.solve({1},{2}) failed to converge".format(
                    self.__class__.__name__, solveAttr, solveBracket))

    def summary(self, printOutput=True, printFlows=False):
        """Prints and returns a summary of useful component attributes.

Parameters
-----------
printOutput : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
printFlows : bool, optional
    If true, summaries of the incoming and outgoing flows of the component are also printed. Defaults to False.
        """
        output = r"{} properties".format(self.name)
        output += """
{0}
    Notes: {}
    Flow sense, flowSense = {}
    Inner fluid is WF, innerWf = {}
    No. of WF channels, NWf  = {}
    No. of SF channels, NSf  = {}
    No. of walls, NWall = {}
    Heat trans. working fluid, UWf = {} [W/m^2.K]
    Heat trans. secondary, USf = {} [W/m^2.K]
    Fouling resist. factor WF side, RfWf = {} [m^2K/W]
    Fouling resist. factor SF side, RfSf = {} [m^2K/W]
    Wall material, wall = {}
    Wall thickness, tWall = {} [m]
    Heat trans. length, L = {} [m]
    Heat trans. width, W = {} [m]
    Area multiplier of WF, ARatioWf = {}
    Area multiplier of SF, ARatioSf = {}
    Area multiplier of wall, ARatioWall = {}
    Thermal efficiency, effThermal = {}
        """.format('-' * len(output), self.notes, self.flowSense, self.innerWf,
                   self.NWf, self.NSf, self.NWall, self.UWf, self.USf,
                   self.RfWf, self.RfSf, self.wall.name, self.tWall, self.L,
                   self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                   self.effThermal)
        if printFlows is False:
            pass
        else:
            if self.flowInWf is not None:
                outputFlowInWf = """
{0}
""".format(self.flowInWf.summary(False, "flowInWf: "))
            else:
                outputFlowInWf = "flowInWf: No incoming flow."
            if self.flowOutWf is not None:
                outputFlowOutWf = """
flowOutWf: {0}
""".format(self.flowOutWf.summary(False, "flowOutWf: "))
            else:
                outputFlowOutWf = "flowOutWf: No outgoing flow."
            if self.flowInSf is not None:
                outputFlowInSf = """
{0}
""".format(self.flowInSf.summary(False, "flowInSf: "))
            else:
                outputFlowInSf = "flowInSf: No incoming flow."
            if self.flowOutSf is not None:
                outputFlowOutSf = """
flowOutSf: {0}
""".format(self.flowOutSf.summary(False, "flowOutSf: "))
            else:
                outputFlowOutSf = "flowOutSf: No outgoing flow."
            output = output + outputFlowInWf + outputFlowOutWf + outputFlowInSf + outputFlowOutSf
        if printOutput:
            print(output)
        return output
