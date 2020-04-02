from ...bases.component cimport Component11
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ..._constants cimport *
from ...logger import log

cdef tuple _inputs = ('pRatio', 'efficiencyIsentropic', 'flowIn', 'flowOut', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'pIn', 'pOut', 'POut()')

cdef class ExpBasic(Component11):
    r"""Basic expansion defined by a pressure ratio and isentropic efficiency.

Parameters
----------
pRatio : float
    Pressure increase ratio [-].
efficiencyIsentropic : float, optional
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
                 double efficiencyIsentropic=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="pRatio",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="ExpBasic instance",
                 str notes="No notes/model info.",
                 Config config=None):
        super().__init__(flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, [0, 0], [0, 0], name, notes,
                         config)
        self.pRatio = pRatio
        self.efficiencyIsentropic = efficiencyIsentropic
        self._inputs = _inputs
        self._properties = _properties

    cpdef double POut(self):
        """float: Power output [W]."""
        return (self.flowsIn[0].h() - self.flowsOut[0].h()) * self._m()

    cpdef public void run(self) except *:
        """Compute for the outgoing working fluid FlowState from component attributes."""
        cdef FlowState flowOut_s = self.flowsIn[0].copyUpdateState(PSmass_INPUTS, self.flowsIn[0].p() /
                                                    self.pRatio, self.flowsIn[0].s())
        cdef double hOut = self.flowsIn[0].h() - self.efficiencyIsentropic * (self.flowsIn[0].h() - flowOut_s.h())
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(HmassP_INPUTS, hOut,
                                        self.flowsIn[0].p() / self.pRatio)

    cpdef public void size(self) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.
        """
        cdef FlowState flowOut_s
        cdef str attr = self.sizeAttr
        try:
            if attr == "pRatio":
                self.pRatio = self.flowsIn[0].p() / self.flowsOut[0].p()
            elif attr == "efficiencyIsentropic":
                assert (self.flowsIn[0].p() / self.flowsOut[0].p() - self.pRatio
                        ) / self.pRatio < self.config._tolRel_p
                flowOut_s = self.flowsIn[0].copyUpdateState(PSmass_INPUTS, self.flowsOut[0].p(),
                                             self.flowsIn[0].s())
                self.efficiencyIsentropic = (self.flowsIn[0].h() - self.flowsOut[0].h()) / (
                    self.flowsIn[0].h() - flowOut_s.h())
            else:
                super(ExpBasic, self).size()
        except AssertionError as err:
            log('error', 'ExpBasic.size(): pRatio appears to be incorrect', err)
            raise err
        except Exception as exc:
            msg = 'ExpBasic.size(): failed to converge.'
            log('error', msg, exc)
            raise exc
        
    @property
    def pIn(self):
        """float: Alias of flowIn.p [Pa]. Setter sets pRatio if flowOut is defined."""
        return self.flowsIn[0].p()

    @pIn.setter
    def pIn(self, double value):
        if self.flowsOut[0]:
            assert value >= self.flowsOut[0].p(), "pIn (given: {}) cannot be less than pOut = {}".format(
                value, self.flowsOut[0].p())
            self.pRatio = value / self.flowsOut[0].p()
        else:
            pass

    @property
    def pOut(self):
        """float: Alias of flowOut.p [Pa]. Setter sets pRatio if flowIn is defined."""
        return self.flowsOut[0].p()

    @pOut.setter
    def pOut(self, double value):
        if self.flowsIn[0]:
            assert value <= self.flowsIn[0].p(), "pOut (given: {}) cannot be greater than pIn = {}".format(
                value, self.flowsIn[0].p())
            self.pRatio = self.flowsIn[0].p() / value
        else:
            pass

