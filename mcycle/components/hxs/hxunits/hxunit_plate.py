from .hxunit_basicplanar import HxUnitBasicPlanar
from ....bases import Config
from warnings import warn
import CoolProp as CP
import numpy as np
import scipy.optimize as opt


class HxUnitPlate(HxUnitBasicPlanar):
    r"""Characterises a basic plate heat exchanger unit consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counterflow" or "parallel". Defaults to "counterflow".
NPlate : int, optional
    Number of parallel plates [-]. Defaults to 3.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
plate : SolidMaterial, optional
    Plate material. Defaults to None.
tPlate : float, optional
    Thickness of the plate [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioPlate : float, optional
    Multiplier for the heat transfer surface area of the plate [-]. Defaults to 1.
beta : float, optional
     Plate corrugation chevron angle [deg]. Defaults to nan.
phi : float, optional
     Corrugated plate surface enlargement factor; ratio of developed length to projected length. Defaults to 1.2.
pitchCor : float, optional
     Plate corrugation pitch [m] (distance between corrugation 'bumps'). Defaults to nan.
     .. note: Not to be confused with the plate pitch which is usually defined as the sum of the plate channel spacing and one plate thickness.
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
    Default attribute used by solve(). Defaults to "L".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [1e-5, 10.0].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of object. Defaults to "HxUnitPlateCorrugated instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 flowSense="counterflow",
                 NPlate=3,
                 RfWf=0,
                 RfSf=0,
                 plate=None,
                 tPlate=float("nan"),
                 geomPlateWf=None,
                 geomPlateSf=None,
                 L=float("nan"),
                 W=float("nan"),
                 ARatioWf=1,
                 ARatioSf=1,
                 ARatioPlate=1,
                 effThermal=1.0,
                 flowInWf=None,
                 flowInSf=None,
                 flowOutWf=None,
                 flowOutSf=None,
                 solveAttr="L",
                 solveBracket=[1e-5, 10.0],
                 name="HxUnitPlateCorrugated instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(flowSense, None, None, NPlate, None, None, RfWf, RfSf,
                         plate, tPlate, L, W, ARatioWf, ARatioSf, ARatioPlate,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         solveAttr, solveBracket, name, notes, config)
        self.geomPlateWf = geomPlateWf
        self.geomPlateSf = geomPlateSf
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("flowSense", "none"), ("NPlate", "none"), ("RfWf", "fouling"),
                ("RfSf", "fouling"), ("plate", "none"), ("tPlate", "length"),
                ("geomPlateWf", "none"), ("geomPlateSf", "none"),
                ("L", "length"), ("W", "length"), ("ARatioWf", "none"),
                ("ARatioSf", "none"), ("ARatioPlate", "none"),
                ("effThermal", "none"), ("flowInWf", "none"),
                ("flowInSf", "none"), ("flowOutWf", "none"),
                ("flowOutSf", "none"), ("solveAttr", "none"),
                ("solveBracket", "none"), ("name", "none"), ("notes", "none"),
                ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("mSf", "mass/time"), ("Q", "power"),
                ("U", "htc"), ("A", "area"), ("hWf", "htc"), ("hSf", "htc"),
                ("dpFWf", "pressure"), ("dpFSf", "pressure"),
                ("isEvap", "none")]

    @property
    def geomPlate(self):
        if self.geomPlateSf is self.geomPlateWf:
            return self.geomPlateWf
        else:
            warn(
                "geomPlate is not valid: geomPlateWf and geomPlateSf are different objects"
            )
            pass

    @geomPlate.setter
    def geomPlate(self, obj):
        self.geomPlateWf = obj
        self.geomPlateSf = obj

    @property
    def NWf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NPlate & 1:  # NPlate is odd
            return (self.NPlate - 1) / 2
        else:
            if self.config.evenPlatesWf:
                return self.NPlate / 2
            else:
                return self.NPlate / 2 - 1

    @NWf.setter
    def NWf(self, value):
        pass

    @property
    def NSf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NPlate & 1:  # NPlate is odd
            return (self.NPlate - 1) / 2
        else:
            if self.config.evenPlatesWf:
                return self.NPlate / 2 - 1
            else:
                return self.NPlate / 2

    @NSf.setter
    def NSf(self, value):
        pass

    @property
    def hWf(self):
        """float: Heat transfer coefficient of a working fluid channel [W/m^2.K]. Calculated using the relevant method defined in config.methodsHeatWf (depending on phase)."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateWf.__class__, "heat",
                                            self.phaseWf, "wf")
        return method(
            flowIn=self.flowInWf,
            flowOut=self.flowOutWf,
            N=self.NWf,
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["h"]

    @hWf.setter
    def hWf(self, value):
        pass

    @property
    def hSf(self):
        """float: Heat transfer coefficient of a secondary fluid channel [W/m^2.K]. Calculated using the relevant method defined in config.methodsHeatSf."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateSf.__class__, "heat",
                                            self.phaseSf, "sf")
        return method(
            flowIn=self.flowInSf,
            flowOut=self.flowOutSf,
            N=self.NSf,
            geom=self.geomPlateSf,
            L=self.L,
            W=self.W)["h"]

    @hSf.setter
    def hSf(self, value):
        pass

    @property
    def fWf(self):
        """float: Fanning friction factor of a working fluid channel [-]. Calculated using the relevant method defined in config.methodsFrictionWf (depending on phase)."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateWf.__class__,
                                            "friction", self.phaseWf, "wf")
        return method(
            flowIn=self.flowInWf,
            flowOut=self.flowOutWf,
            N=self.NWf,
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["f"]

    @property
    def fSf(self):
        """float: Fanning friction factor of a secondary fluid channel [-]. Calculated using the relevant method defined in config.methodsFrictionSf."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateSf.__class__,
                                            "friction", self.phaseSf, "sf")
        return method(
            flowIn=self.flowInSf,
            flowOut=self.flowOutSf,
            N=self.NSf,
            geom=self.geomPlateSf,
            L=self.L,
            W=self.W)["f"]

    @property
    def dpFWf(self):
        """float: Frictional pressure drop of a working fluid channel [-]. Calculated using the relevant method defined in config.methodsFrictionWf (depending on phase)."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateWf.__class__,
                                            "friction", self.phaseWf, "wf")
        return method(
            flowIn=self.flowInWf,
            flowOut=self.flowOutWf,
            N=self.NWf,
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["dpF"]

    @property
    def dpFSf(self):
        """float: Frictional pressure drop of a secondary fluid channel [-]. Calculated using the relevant method defined in config.methodsFrictionSf."""
        method = self.config.methods.lookup(self.__class__,
                                            self.geomPlateSf.__class__,
                                            "friction", self.phaseSf, "sf")
        return method(
            flowIn=self.flowInSf,
            flowOut=self.flowOutSf,
            N=self.NSf,
            geom=self.geomPlateSf,
            L=self.L,
            W=self.W)["dpF"]

    @property
    def U(self):
        """float: Overall heat transfer coefficient of the unit [W/m^2.K]."""
        RWf = (1 / self.hWf + self.RfWf) / self.ARatioWf / self.NWf
        RSf = (1 / self.hSf + self.RfSf) / self.ARatioSf / self.NSf
        RPlate = self.tPlate / (
            self.NPlate - 2) / self.plate.k / self.ARatioPlate
        return (RWf + RSf + RPlate)**-1

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

    @property
    def plate(self):
        """alias of self.wall."""
        return self.wall

    @plate.setter
    def plate(self, value):
        self.wall = value

    @property
    def tPlate(self):
        """alias of self.tWall."""
        return self.tWall

    @tPlate.setter
    def tPlate(self, value):
        self.tWall = value

    @property
    def ARatioPlate(self):
        """alias of self.ARatioWall."""
        return self.ARatioWall

    @ARatioPlate.setter
    def ARatioPlate(self, value):
        self.ARatioWall = value

    @property
    def NPlate(self):
        """alias of self.NWall."""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value
