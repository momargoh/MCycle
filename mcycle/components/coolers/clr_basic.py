from abc import abstractmethod
from ...bases import Component11, Config
import CoolProp as CP


class ClrBasic(Component11):
    r"""Basic heat removal.

Parameters
----------
Q : float
    Heat removed [W].
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to "effThermal".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [0.1, 1.0].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "ClrBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    @abstractmethod
    def __init__(self,
                 Q=None,
                 effThermal=1.0,
                 flowIn=None,
                 flowOut=None,
                 solveAttr="effThermal",
                 solveBracket=[0.1, 1.0],
                 name="ClrBasic instance",
                 notes="no notes/model info.",
                 config=Config(),
                 **kwargs):
        assert (
            effThermal > 0 and effThermal <= 1.
        ), "Thermal efficiency={0} is not in range (0, 1]".format(effThermal)
        self.Q = Q
        self.effThermal = effThermal
        super().__init__(flowIn, flowOut, solveAttr, solveBracket, name, notes,
                         config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("Q", "power"), ("effThermal", "none"), ("flowIn", "none"),
                ("flowOut", "none"), ("solveAttr", "none"),
                ("solveBracket", "none"), ("name", "none"), ("notes", "none"),
                ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("dpWf", "pressure")]

    @property
    def _effFactorWf(self):
        return self.effThermal

    @property
    def _effFactorSf(self):
        return 1

    @property
    def dpWf(self):
        """float: Pressure drop of the working fluid [Pa]. Defaults to 0."""
        return 0

    @property
    def dpSf(self):
        """float: Pressure drop of the secondary fluid [Pa]. Defaults to 0."""
        return 0

    @abstractmethod
    def run(self):
        pass

    @abstractmethod
    def solve(self):
        pass


class ClrBasicConstP(ClrBasic):
    r"""Basic constant volume heat removal.

Parameters
----------
Q : float
    Heat removed [-].
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to "effThermal".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [0.1, 1.0].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "ClrBasicConstP instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 Q=None,
                 effThermal=1.0,
                 flowIn=None,
                 flowOut=None,
                 solveAttr="effThermal",
                 solveBracket=[0.1, 1.0],
                 name="ClrBasicConstP instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(Q, effThermal, flowIn, flowOut, solveAttr,
                         solveBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    def run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowOut = self.flowIn.copy(
            CP.HmassP_INPUTS,
            self.flowIn.h + self.Q * self.effThermal / self.m, self.flowIn.p)

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
            assert abs(1 - self.flowOut.p / self.flowIn.
                       p) < self.config._tolRel_p, "flowOut.p != flowIn.p"
            if solveAttr == "Q":
                self.Q = (
                    self.flowOut.h - self.flowIn.h) * self.m / self.effThermal
            elif solveAttr == "effThermal":
                self.effThermal = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.Q
            elif solveAttr == "m":
                self.m = (
                    self.flowOut.h - self.flowIn.h) / self.effThermal / self.Q
            else:
                super().solve(solveAttr, solveBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.solve({},{}) failed to converge".format(
                    self.__class__.__name__, solveAttr, solveBracket))


class ClrBasicConstV(ClrBasic):
    r"""Basic constant volume heat removal.

Parameters
----------
Q : float
    Heat rejected [-].
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to "effThermal".
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to [0.1, 1.0].

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "ClrBasicConstV instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 Q=None,
                 effThermal=1.0,
                 flowIn=None,
                 flowOut=None,
                 solveAttr="effThermal",
                 solveBracket=[0.1, 1.0],
                 name="ClrBasicConstV instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(Q, effThermal, flowIn, flowOut, solveAttr,
                         solveBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    def run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowOut = self.flowIn.copy(
            CP.DmassHmass_INPUTS, self.flowIn.rho,
            self.flowIn.h - self.Q * self.effThermal / self.m)

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
            assert abs(1 - self.flowOut.rho / self.flowIn.rho
                       ) < self.config._tolRel_rho, "flowOut.rho != flowIn.rho"
            if solveAttr == "Q":
                self.Q = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.effThermal
            elif solveAttr == "effThermal":
                self.effThermal = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.Q
            elif solveAttr == "m":
                self.m = (
                    self.flowOut.h - self.flowIn.h) / self.effThermal / self.Q
            else:
                super().solve(solveAttr, solveBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.solve({},{}) failed to converge".format(
                    self.__class__.__name__, solveAttr, solveBracket))
