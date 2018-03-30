from ...bases import Component11, Config
import CoolProp as CP


class CompBasic(Component11):
    r"""Basic compression defined by a pressure ratio and isentropic efficiency.

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
    Description of Component object. Defaults to "CompBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 pRatio,
                 effIsentropic=1,
                 flowIn=None,
                 flowOut=None,
                 sizeAttr="pRatio",
                 sizeBracket=[1, 50],
                 name="CompBasic instance",
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
            assert value <= self.flowOut.p, "pIn (given: {}) cannot be greater than pOut = {}".format(
                value, self.flowOut.p)
            self.pRatio = self.flowOut.p / value
        else:
            pass

    @property
    def pOut(self):
        """float: Alias of flowOut.p [Pa]. Setter sets pRatio if flowIn is defined."""
        return self.flowOut.p

    @pOut.setter
    def pOut(self, value):
        if self.flowIn:
            assert value >= self.flowIn.p, "pOut (given: {}) cannot be less than pIn = {}".format(
                value, self.flowIn.p)
            self.pRatio = value / self.flowIn.p
        else:
            pass

    @property
    def P_in(self):
        """float: Power input [W]."""
        return (self.flowOut.h - self.flowIn.h) * self.m

    def run(self):
        """Compute for the outgoing working fluid FlowState from component attributes."""
        flowOut_s = self.flowIn.copy(CP.PSmass_INPUTS, self.flowIn.p *
                                     self.pRatio, self.flowIn.s)
        hOut = self.flowIn.h + (flowOut_s.h - self.flowIn.h
                                ) / self.effIsentropic
        self.flowOut = self.flowIn.copy(CP.HmassP_INPUTS, hOut,
                                        self.flowIn.p * self.pRatio)
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
                self.pRatio = self.flowOut.p / self.flowIn.p
            elif sizeAttr == "effIsentropic":
                assert (self.flowOut.p / self.flowIn.p - self.pRatio
                        ) / self.pRatio < self.config._tolRel_p
                flowOut_s = self.flowIn.copy(CP.PSmass_INPUTS, self.flowOut.p,
                                             self.flowIn.s)
                self.effIsentropic = (flowOut_s.h - self.flowIn.h) / (
                    self.flowOut.h - self.flowIn.h)
            else:
                super().size(sizeAttr, sizeBracket)
        except AssertionError as err:
            raise (err)
        except:
            raise StopIteration("{}.size({},{}) failed to converge".format(
                self.__class__.__name__, sizeAttr, sizeBracket))
