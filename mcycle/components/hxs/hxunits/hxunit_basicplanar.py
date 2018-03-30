from .hxunit_basic import HxUnitBasic
from ....bases import Config


class HxUnitBasicPlanar(HxUnitBasic):
    r"""Characterises a basic planar heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

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
    Heat transfer coefficient of the working fluid. Defaults to nan.
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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "N".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [3, 100].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
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
                 sizeAttr="A",
                 sizeBracket=[0.01, 10.0],
                 name="HxUnitBasic instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{0} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
        self.L = L
        self.W = W
        super().__init__(flowSense, NWf, NSf, NWall, hWf, hSf, RfWf, RfSf,
                         wall, tWall, L * W, ARatioWf, ARatioSf, ARatioWall,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBracket, name, notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (
            ("flowSense", "none"), ("NWf", "none"), ("NSf", "none"),
            ("NWall", "none"), ("hWf", "htc"), ("hSf", "htc"),
            ("RfWf", "fouling"), ("RfSf", "fouling"), ("wall", "none"),
            ("tWall", "length"), ("L", "length"), ("W", "length"),
            ("ARatioWf", "none"), ("ARatioSf", "none"), ("ARatioWall", "none"),
            ("effThermal", "none"), ("flowInWf", "none"), ("flowInSf", "none"),
            ("flowOutWf", "none"), ("flowOutSf", "none"),
            ("sizeAttr", "none"), ("sizeBracket", "none"), ("name", "none"),
            ("notes", "none"), ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("mSf", "mass/time"), ("Q", "power"),
                ("U", "htc"), ("dpWf", "pressure"), ("dpSf", "pressure"),
                ("isEvap", "none")]

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor"""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf,
                self.hSf, self.wall, self.tWall, self.RfWf, self.RfSf, self.L,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal, self.flowInWf, self.flowInSf, self.flowOutWf,
                self.flowOutSf, self.sizeAttr, self.sizeBracket, self.name,
                self.notes, self.config)

    @property
    def A(self):
        """float: A = L * W.
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

    def size(self, sizeAttr=None, sizeBracket=None):
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
sizeAttr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
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
            if sizeAttr in ["L", "W", "A"]:
                setattr(self, sizeAttr, 1.)
                setattr(self, sizeAttr, self.Q / self.Q_LMTD)
                return getattr(self, self.sizeAttr)
            else:
                super().size(sizeAttr, sizeBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, sizeAttr, sizeBracket))
