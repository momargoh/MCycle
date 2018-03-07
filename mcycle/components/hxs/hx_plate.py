import warnings
from ...DEFAULTS import MAXITERATIONSCOMPONENT, MAXWALLS
from ...bases import Config
from .hx_basicplanar import HxBasicPlanar
from .hxunits import HxUnitPlate
import numpy as np
from scipy import optimize as opt
import CoolProp as CP


class HxPlate(HxBasicPlanar):
    r"""Characterises a basic plate heat exchanger consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counterflow" or "parallel". Defaults to "counterflow".
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
NPlate : int, optional
    Number of parallel plates [-]. The number of thermally activate plates is equal to NPlate - 2, due to the 2 end plates. Must be >= 3. Defaults to 3.
DPortWf : float, optional
    Diameter of the working fluid flow ports [m]. Defaults to nan.
DPortSf : float, optional
    Diameter of the secondary fluid flow ports [m]. Defaults to nan.
LVertPortWf : float, optional
    Vertical distance between incoming and outgoing working fluid flow ports [m]. If None, L is used. Defaults to None.
LVertPortSf : float, optional
    Vertical distance between incoming and outgoing secondary fluid flow ports [m]. If None, L is used. Defaults to None.
coeffs_LPlate : list of float, optional
    Coefficients to calculate the total plate length from the length of the heat transfer area. LPlate = sum(coeffs_LPlate[i] * L**i). Defaults to [0, 1].
coeffs_WPlate : list of float, optional
    Coefficients to calculate the total plate width from the width of the heat transfer area. wPlate = sum(coeffs_WPlate[i] * W**i). Defaults to [0, 1].
coeffs_weight : list of float, optional
    Coefficients to calculate the total weight of the plates from the number of plates and the plate volume.::
        weight = sum(coeffs_weight[i] * NPlates**i)*(LPlate*WPlate*tPlate).

    If None, the weight is approximated from the plate geometry. Defaults to None.
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
    Default attribute used by solve(). Defaults to "NPlate".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [3, 100].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
solveBracketUnits : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of solve() for the unit. Typically this bracket is used to solve for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxPlate instance".
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
                 DPortWf=float("nan"),
                 DPortSf=float("nan"),
                 LVertPortWf=None,
                 LVertPortSf=None,
                 coeffs_LPlate=[0, 1],
                 coeffs_WPlate=[0, 1],
                 coeffs_weight=None,
                 effThermal=1.0,
                 flowInWf=None,
                 flowInSf=None,
                 flowOutWf=None,
                 flowOutSf=None,
                 flowDeadSf=None,
                 solveAttr="NPlate",
                 solveBracket=[3, 100],
                 solveBracketUnits=[1e-5, 10.],
                 name="HxPlate instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
        self.geomPlateWf = geomPlateWf
        self.geomPlateSf = geomPlateSf
        self.DPortWf = DPortWf
        self.DPortSf = DPortSf
        self._LVertPortWf = LVertPortWf
        self._LVertPortSf = LVertPortSf
        self.coeffs_LPlate = coeffs_LPlate
        self.coeffs_WPlate = coeffs_WPlate
        self.coeffs_weight = coeffs_weight
        super().__init__(flowSense, None, None, NPlate, None, None, None, None,
                         RfWf, RfSf, plate, tPlate, L, W, ARatioWf, ARatioSf,
                         ARatioPlate, effThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, flowDeadSf, solveAttr,
                         solveBracket, solveBracketUnits, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

        self._unitClass = HxUnitPlate

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (
            ("flowSense", "none"), ("NPlate", "none"), ("RfWf", "fouling"),
            ("RfSf", "fouling"), ("plate", "none"), ("tPlate", "length"),
            ("geomPlateWf", "none"), ("geomPlateSf", "none"), ("L", "length"),
            ("W", "length"), ("ARatioWf", "none"), ("ARatioSf", "none"),
            ("ARatioPlate", "none"), ("DPortWf", "length"),
            ("DPortSf", "length"), ("LVertPortWf", "length"),
            ("LVertPortSf", "length"), ("coeffs_LPlate", "none"),
            ("coeffs_WPlate", "none"), ("coeffs_weight", "none"),
            ("effThermal", "none"), ("flowInWf", "none"), ("flowInSf", "none"),
            ("flowOutWf", "none"), ("flowOutSf", "none"),
            ("solveAttr", "none"), ("solveBracket", "none"),
            ("solveBracketUnits", "none"), ("name", "none"), ("notes", "none"),
            ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("mSf", "mass/time"), ("Q", "power"),
                ("A", "area"), ("dpWf", "pressure"), ("dpSf", "pressure"),
                ("isEvap", "none")]

    @property
    def _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowSense, self.NPlate, self.RfWf, self.RfSf, self.plate,
                self.tPlate, self.geomPlateWf, self.geomPlateSf, self.L,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioPlate,
                self.effThermal)

    @property
    def _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return self._unitArgsLiq

    @property
    def _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return self._unitArgsLiq

    @property
    def geomPlate(self):
        if self.geomPlateSf is self.geomPlateWf:
            return self.geomPlateWf
        else:
            warnings.warn(
                "geomPlate is not valid: geomPlateWf and geomPlateSf are different objects"
            )
            pass

    @geomPlate.setter
    def geomPlate(self, obj):
        self.geomPlateWf = obj
        self.geomPlateSf = obj

    @property
    def LPlate(self):
        """float: Total length of the plate; sum(coeffs_LPlate[i] * L**i)."""
        ans = 0
        for i in range(len(self.coeffs_LPlate)):
            ans += self.coeffs_LPlate[i] * self.L**i
        return ans

    @property
    def WPlate(self):
        """float: Total width of the plate; sum(coeffs_WPlate[i] * W**i)."""
        ans = 0
        for i in range(len(self.coeffs_WPlate)):
            ans += self.coeffs_WPlate[i] * self.W**i
        return ans

    @property
    def LVertPortWf(self):
        if self._LVertPortWf is None:
            return self.L
        else:
            return self._LVertPortWf

    @LVertPortWf.setter
    def LVertPortWf(self, value):
        self._LVertPortWf = value

    @property
    def LVertPortSf(self):
        if self._LVertPortSf is None:
            return self.L
        else:
            return self._LVertPortSf

    @LVertPortSf.setter
    def LVertPortSf(self, value):
        self._LVertPortSf = value

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
    def dpFWf(self):
        """float: Frictional pressure drop of the working fluid [Pa]."""
        dp = 0.
        for unit in self._units:
            dp += unit.dpFWf
        return dp

    @property
    def dpFSf(self):
        """float: Frcitional pressure drop of the secondary fluid [Pa]."""
        dp = 0.
        for unit in self._units:
            dp += unit.dpFSf
        return dp

    @property
    def dpPortWf(self):
        """float: Port pressure loss of the working fluid [Pa]."""
        GPort = self.mWf / (0.25 * np.pi * self.DPortWf**2)
        dpIn = 1.0 * GPort**2 / 2 / self.flowInWf.rho
        dpOut = 0.4 * GPort**2 / 2 / self.flowOutWf.rho
        return dpIn + dpOut

    @property
    def dpPortSf(self):
        """float: Port pressure loss of the secondary fluid [Pa]."""
        GPort = self.mSf / (0.25 * np.pi * self.DPortSf**2)
        dpIn = 1.0 * GPort**2 / 2 / self.flowInSf.rho
        dpOut = 0.4 * GPort**2 / 2 / self.flowOutSf.rho
        return dpIn + dpOut

    @property
    def dpAccWf(self):
        """float: Acceleration pressure drop of the working fluid [Pa]."""
        G = self.mWf / self.NWf / (self.geomPlateWf.b * self.W)
        return G**2 * (1 / self.flowOutWf.rho - 1 / self.flowInWf.rho)

    @property
    def dpAccSf(self):
        """float: Acceleration pressure drop of the secondary fluid [Pa]."""
        G = self.mSf / self.NSf / (self.geomPlateSf.b * self.W)
        return G**2 * (1 / self.flowOutSf.rho - 1 / self.flowInSf.rho)

    @property
    def dpHeadWf(self):
        """float: Static head pressure drop of the working fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.isEvap:
            return self.flowOutWf.rho * self.config.g * self.LVertPortWf
        else:
            return -self.flowOutWf.rho * self.config.g * self.LVertPortWf

    @property
    def dpHeadSf(self):
        """float: Static head pressure drop of the secondary fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.isEvap:
            return -self.flowOutSf.rho * self.config.g * self.LVertPortSf
        else:
            return self.flowOutSf.rho * self.config.g * self.LVertPortSf

    @property
    def dpWf(self):
        """float: Total pressure drop of the working fluid [Pa]."""
        dp = 0
        if self.config.dpFWf:
            dp += self.dpFWf
        if self.config.dpAccWf:
            dp += self.dpAccWf
        if self.config.dpHeadWf:
            dp += self.dpHeadWf
        if self.config.dpPortWf:
            dp += self.dpPortWf
        return dp

    @property
    def dpSf(self):
        """float: Total pressure drop of the secondary fluid [Pa]."""
        dp = 0
        if self.config.dpFSf:
            dp += self.dpFSf
        if self.config.dpAccSf:
            dp += self.dpAccSf
        if self.config.dpHeadSf:
            dp += self.dpHeadSf
        if self.config.dpPortSf:
            dp += self.dpPortSf
        return dp

    @property
    def weight(self):
        """float: Approximate total weight of the heat exchanger plates [Kg], calculated as either

    - sum(coeffs_weight[i] * NPlate**i)*(LPlate*WPlate*tPlate) if coeffs_weight is defined,
    - or (LPlate*WPlate - 2(0.25*pi*DPortWf**2 + 0.25*pi*DPortSf**2))*tPlate*plate.rho*NPlate.
        """
        if self.coeffs_weight is None:
            return (
                self.LPlate * self.WPlate - 2 *
                (0.25 * np.pi * self.DPortWf**2 + 0.25 * np.pi * self.DPortSf**
                 2)) * self.tPlate * self.plate.rho * self.NPlate
        else:
            weightPerVol = 0.
            for i in range(len(self.coeffs_weight)):
                weightPerVol += self.coeffs_weight[i] * self.NPlate**i
            return weightPerVol * self.LPlate * self.WPlate * self.tPlate

    def solve_NPlate(self, solveBracket=None, solveBracketUnits=None):
        """int: solve for NPlate that requires L to be closest to self.L"""
        if solveBracket is None:
            solveBracket = [3, MAXWALLS]
        NPlate = solveBracket[0]
        L = self.L
        diff_vals = [float("nan"), float("nan")]
        while NPlate < solveBracket[1]:
            self.update(NPlate=NPlate)
            diff = self.solve_L(solveBracketUnits) - L
            diff_vals = [diff_vals[1], diff]
            if diff > 0:
                NPlate += 1
            else:
                break
        if abs(diff_vals[0]) < abs(diff_vals[1]):
            self.update(NPlate=NPlate - 1)
            self.solve_L(solveBracketUnits)
            return NPlate - 1
        else:
            return NPlate

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
            if solveAttr in ["N", "NPlate"]:
                self.unitise()
                return self.solve_NPlate(solveBracket, solveBracketUnits)
            else:
                super().solve(solveAttr, solveBracket, solveBracketUnits)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration("{}.solve({},{}) failed to converge".format(
                self.__class__.__name__, solveAttr, solveBracket))

    @property
    def plate(self):
        """SolidMaterial: Alias of self.wall"""
        return self.wall

    @plate.setter
    def plate(self, value):
        self.wall = value

    @property
    def tPlate(self):
        """float: Alias of self.tWall"""
        return self.tWall

    @tPlate.setter
    def tPlate(self, value):
        self.tWall = value

    @property
    def ARatioPlate(self):
        """float: Alias of self.ARatioWall"""
        return self.ARatioWall

    @ARatioPlate.setter
    def ARatioPlate(self, value):
        self.ARatioWall = value

    @property
    def NPlate(self):
        """int: Alias of self.NWall"""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value
