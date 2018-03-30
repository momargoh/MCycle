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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "effThermal".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
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
                 sizeAttr="effThermal",
                 sizeBracket=[0.1, 1.0],
                 name="ClrBasic instance",
                 notes="no notes/model info.",
                 config=Config(),
                 **kwargs):
        assert (
            effThermal > 0 and effThermal <= 1.
        ), "Thermal efficiency={0} is not in range (0, 1]".format(effThermal)
        self.Q = Q
        self.effThermal = effThermal
        super().__init__(flowIn, flowOut, sizeAttr, sizeBracket, name, notes,
                         config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("Q", "power"), ("effThermal", "none"), ("flowIn", "none"),
                ("flowOut", "none"), ("sizeAttr", "none"),
                ("sizeBracket", "none"), ("name", "none"), ("notes", "none"),
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
    def size(self):
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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "effThermal".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
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
                 sizeAttr="effThermal",
                 sizeBracket=[0.1, 1.0],
                 name="ClrBasicConstP instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(Q, effThermal, flowIn, flowOut, sizeAttr,
                         sizeBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    def run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowOut = self.flowIn.copy(
            CP.HmassP_INPUTS,
            self.flowIn.h + self.Q * self.effThermal / self.m, self.flowIn.p)

    def size(self, sizeAttr=None, sizeBracket=None):
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
sizeAttr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBracket is used. Defaults to None.

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
        """
        if sizeAttr is None:
            sizeAttr = self.sizeAttr
        if sizeBracket is None:
            sizeBracket = self.sizeBracket
        try:
            assert abs(1 - self.flowOut.p / self.flowIn.
                       p) < self.config._tolRel_p, "flowOut.p != flowIn.p"
            if sizeAttr == "Q":
                self.Q = (
                    self.flowOut.h - self.flowIn.h) * self.m / self.effThermal
            elif sizeAttr == "effThermal":
                self.effThermal = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.Q
            elif sizeAttr == "m":
                self.m = (
                    self.flowOut.h - self.flowIn.h) / self.effThermal / self.Q
            else:
                super().size(sizeAttr, sizeBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, sizeAttr, sizeBracket))


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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "effThermal".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
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
                 sizeAttr="effThermal",
                 sizeBracket=[0.1, 1.0],
                 name="ClrBasicConstV instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(Q, effThermal, flowIn, flowOut, sizeAttr,
                         sizeBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    def run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowOut = self.flowIn.copy(
            CP.DmassHmass_INPUTS, self.flowIn.rho,
            self.flowIn.h - self.Q * self.effThermal / self.m)

    def size(self, sizeAttr=None, sizeBracket=None):
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
sizeAttr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBracket is used. Defaults to None.

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
        """
        if sizeAttr is None:
            sizeAttr = self.sizeAttr
        if sizeBracket is None:
            sizeBracket = self.sizeBracket
        try:
            assert abs(1 - self.flowOut.rho / self.flowIn.rho
                       ) < self.config._tolRel_rho, "flowOut.rho != flowIn.rho"
            if sizeAttr == "Q":
                self.Q = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.effThermal
            elif sizeAttr == "effThermal":
                self.effThermal = (
                    self.flowIn.h - self.flowOut.h) * self.m / self.Q
            elif sizeAttr == "m":
                self.m = (
                    self.flowOut.h - self.flowIn.h) / self.effThermal / self.Q
            else:
                super().size(sizeAttr, sizeBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, sizeAttr, sizeBracket))
