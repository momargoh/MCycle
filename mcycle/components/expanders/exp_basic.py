from ...bases import Component11, Config
import CoolProp as CP


class ExpBasic(Component11):
    r"""Basic expansion defined by a pressure ratio and isentropic efficiency.

Parameters
----------
pRatio : float
    Pressure increase ratio [-].
effIsentropic : float
    Isentropic efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "pRatio".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1, 50].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "ExpBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 pRatio=1,
                 effIsentropic=1.0,
                 flowIn=None,
                 flowOut=None,
                 sizeAttr="pRatio",
                 sizeBracket=[1, 50],
                 name="ExpBasic instance",
                 notes="No notes/model info.",
                 config=Config(),
                 **kwargs):
        super().__init__(flowIn, flowOut, sizeAttr, sizeBracket, name, notes,
                         config)
        self.pRatio = pRatio
        self.effIsentropic = effIsentropic
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("pRatio", "none"), ("effIsentropic", "none"),
                ("flowIn", "none"), ("flowOut", "none"), ("sizeAttr", "none"),
                ("sizeBracket", "none"), ("name", "none"), ("notes", "none"),
                ("config", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time"), ("pIn", "pressure"),
                ("pOut", "pressure")]

    @property
    def pIn(self):
        """float: Alias of flowIn.p [Pa]. Setter sets pRatio if flowOut is defined."""
        return self.flowIn.p

    @pIn.setter
    def pIn(self, value):
        if self.flowOut:
            assert value >= self.flowOut.p, "pIn (given: {}) cannot be less than pOut = {}".format(
                value, self.flowOut.p)
            self.pRatio = value / self.flowOut.p
        else:
            pass

    @property
    def pOut(self):
        """float: Alias of flowOut.p [Pa]. Setter sets pRatio if flowIn is defined."""
        return self.flowOut.p

    @pOut.setter
    def pOut(self, value):
        if self.flowIn:
            assert value <= self.flowIn.p, "pOut (given: {}) cannot be greater than pIn = {}".format(
                value, self.flowIn.p)
            self.pRatio = self.flowIn.p / value
        else:
            pass

    @property
    def P_out(self):
        """float: Power output [W]."""
        return (self.flowIn.h - self.flowOut.h) * self.m

    def run(self, flowIn=None):
        """Compute for the outgoing working fluid FlowState from component attributes."""
        if flowIn is not None:
            self.flowIn = flowIn
        flowOut_s = self.flowIn.copy(CP.PSmass_INPUTS, self.flowIn.p /
                                     self.pRatio, self.flowIn.s)
        hOut = self.flowIn.h - self.effIsentropic * (self.flowIn.h -
                                                     flowOut_s.h)
        self.flowOut = self.flowIn.copy(CP.HmassP_INPUTS, hOut,
                                        self.flowIn.p / self.pRatio)
        return self.flowOut

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
            if sizeAttr == "pRatio":
                self.pRatio = self.flowIn.p / self.flowOut.p
            elif sizeAttr == "effIsentropic":
                assert (self.flowIn.p / self.flowOut.p - self.pRatio
                        ) / self.pRatio < self.config._tolRel_p
                flowOut_s = self.flowIn.copy(CP.PSmass_INPUTS, self.flowOut.p,
                                             self.flowIn.s)
                self.effIsentropic = (self.flowIn.h - self.flowOut.h) / (
                    self.flowIn.h - flowOut_s.h)
            else:
                super().size(sizeAttr, sizeBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, sizeAttr, sizeBracket))
