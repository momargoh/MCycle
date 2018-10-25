from ...bases.component cimport Component11
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
import CoolProp as CP

cdef dict _inputs = {"pRatio": MCAttr(float, "none"), "effIsentropic": MCAttr(float, "none"),
                "flowIn": MCAttr(FlowState, "none"), "flowOut": MCAttr(FlowState, "none"), "ambient": MCAttr(FlowState, "none"),"sizeAttr": MCAttr(str, "none"),
                "sizeBounds": MCAttr(list, "none"),"sizeUnitsBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties= {"mWf": MCAttr(float, "mass/time"), "pIn": MCAttr(float, "pressure"),
                "pOut": MCAttr(float, "pressure"), "PIn()": MCAttr(float, "power")}
        
cdef class CompBasic(Component11):
    r"""Basic expansion defined by a pressure ratio and isentropic efficiency.

Parameters
----------
pRatio : float
    Pressure increase ratio [-].
effIsentropic : float, optional
    Isentropic efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "pRatio".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1, 50].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 double pRatio,
                 double effIsentropic=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="pRatio",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="CompBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, [0, 0], name, notes,
                         config)
        self.pRatio = pRatio
        self.effIsentropic = effIsentropic
        self._inputs = _inputs
        self._properties = _properties
        
    cpdef public double PIn(self):
        """float: Power input [W]."""
        return (self.flowsOut[0].h() - self.flowsIn[0].h()) * self._m()

    cpdef public void run(self):
        """Compute for the outgoing working fluid FlowState from component attributes."""
        cdef FlowState flowOut_s = self.flowsIn[0].copyState(CP.PSmass_INPUTS, self.flowsIn[0].p() *
                                     self.pRatio, self.flowsIn[0].s())
        cdef double hOut = self.flowsIn[0].h() + (flowOut_s.h() - self.flowsIn[0].h()
                                ) / self.effIsentropic
        self.flowsOut[0] = self.flowsIn[0].copyState(CP.HmassP_INPUTS, hOut,
                                        self.flowsIn[0].p() * self.pRatio)

    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
sizeAttr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
        """
        cdef FlowState flowOut_s
        if attr == '':
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            if attr == 'pRatio':
                self.pRatio = self.flowsOut[0].p() / self.flowsIn[0].p()
            elif attr == 'effIsentropic':
                assert (self.flowsOut[0].p() / self.flowsIn[0].p() - self.pRatio
                        ) / self.pRatio < self.config._tolRel_p
                flowOut_s = self.flowsIn[0].copyState(CP.PSmass_INPUTS, self.flowsOut[0].p(),
                                             self.flowsIn[0].s())
                self.effIsentropic = (flowOut_s.h() - self.flowsIn[0].h()) / (
                    self.flowsOut[0].h() - self.flowsIn[0].h())
            else:
                super(CompBasic, self)._size(attr, bounds, unitsBounds)
        except AssertionError as err:
            raise err
        except:
            raise StopIteration('{}.size({},{},{}) failed to converge.'.format(self.__class__.__name__, attr, bounds, unitsBounds))

    @property
    def pIn(self):
        """float: Alias of flowIn.p [Pa]. Setter sets pRatio if flowOut is defined."""
        return self.flowsIn[0].p()

    @pIn.setter
    def pIn(self, double value):
        if self.flowsOut[0]:
            assert value <= self.flowsOut[0].p(), "pIn (given: {}) cannot be greater than pOut = {}".format(
                value, self.flowsOut[0].p())
            self.pRatio = self.flowsOut[0].p() / value
        else:
            pass

    @property
    def pOut(self):
        """float: Alias of flowOut.p [Pa]. Setter sets pRatio if flowIn is defined."""
        return self.flowsOut[0].p()

    @pOut.setter
    def pOut(self, double value):
        if self.flowsIn[0]:
            assert value >= self.flowsIn[0].p(), "pOut (given: {}) cannot be less than pIn = {}".format(
                value, self.flowsIn[0].p())
            self.pRatio = value / self.flowsIn[0].p()
        else:
            pass

