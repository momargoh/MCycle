from ...bases.component cimport Component11
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
import CoolProp as CP

cdef class HtrBasic(Component11):
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
                 double Q,
                 double effThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="pRatio",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="HtrBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, [0, 0], name, notes,
                         config)
        assert (
            effThermal > 0 and effThermal <= 1.
        ), "Thermal efficiency={} is not in range (0, 1]".format(effThermal)
        self.Q = Q
        self.effThermal = effThermal
        
        self._inputs = {"Q": MCAttr(float, "power"), "effThermal": MCAttr(float, "none"),
                        "flowIn": MCAttr(FlowState, "none"), "flowOut": MCAttr(FlowState, "none"), 'ambient': MCAttr(FlowState, 'none'), "sizeAttr": MCAttr(str, "none"),
                "sizeBounds": MCAttr(list, "none"),"sizeUnitsBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
        self._properties= {"mWf": MCAttr(float, "mass/time"), "dpWf()": MCAttr(float, "pressure"),
                "dpSf()": MCAttr(float, "pressure")}

    cpdef public double _effFactorWf(self):
        return 1
    
    cpdef public double _effFactorSf(self):
        return self.effThermal

    cpdef public double  dpWf(self):
        """float: Pressure drop of the working fluid [Pa]. Defaults to 0."""
        return 0

    cpdef public double dpSf(self):
        """float: Pressure drop of the secondary fluid [Pa]. Defaults to 0."""
        return 0

    cpdef public void run(self):
        pass
    
    cpdef public double _Q(self):
        """double: Heat [W] transferred to the working fluid."""
        return self.Q
    

cdef class HtrBasicConstP(HtrBasic):
    r"""Basic constant pressure heat addition.

Parameters
----------
Q : float
    Heat added [W].
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "effThermal".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "HtrBasicConstP instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 double Q,
                 double effThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="pRatio",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="HtrBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(Q, effThermal, flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, name, notes,
                         config)

    cpdef public void run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowsOut[0] = self.flowsIn[0].copyState(CP.HmassP_INPUTS, self.flowsIn[0].h() + self.Q * self.effThermal / self._m(), self.flowsIn[0].p())

    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
attr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        if attr == '':
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            assert abs(1 - self.flowsOut[0].p() / self.flowsIn[0].
                       p()) < self.config._tolRel_p, "flowOut.p != flowIn.p"
            if attr == "Q":
                self.Q = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) * self._m() / self.effThermal
            elif attr == "effThermal":
                self.effThermal = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) * self._m() / self.Q
            elif attr == "m":
                self.m = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) / self.effThermal / self.Q
            else:
                super(HtrBasic, self)._size(attr, bounds, unitsBounds)
        except AssertionError as err:
            raise err
        except:
            raise StopIteration(
                "Warning: {}.size({},{},{}) failed to converge".format(
                    self.__class__.__name__, attr, bounds, unitsBounds))


cdef class HtrBasicConstV(HtrBasic):
    r"""Basic constant volume heat addition.

Parameters
----------
Q : float
    Heat added [W].
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "effThermal".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "HtrBasicConstV instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 double Q,
                 double effThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="pRatio",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="HtrBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(Q, effThermal, flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, name, notes,
                         config)
        
    cpdef public void run(self):
        """Compute outgoing FlowState from component attributes."""
        self.flowsOut[0] = self.flowsIn[0].copyState(CP.DmassHmass_INPUTS, self.flowsIn[0].rho(), self.flowsIn[0].h() + self.Q * self.effThermal / self._m())

    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
attr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        if attr == '':
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            assert abs(1 - self.flowsOut[0].rho() / self.flowsIn[0].rho()
                       ) < self.config._tolRel_rho, "flowOut.rho != flowIn.rho"
            if attr == "Q":
                self.Q = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) * self._m() / self.effThermal
            elif attr == "effThermal":
                self.effThermal = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) * self._m() / self.Q
            elif attr == "m":
                self.m = (
                    self.flowsOut[0].h() - self.flowsIn[0].h()) / self.effThermal / self.Q
            else:
                super(HtrBasic, self)._size(attr, bounds)
        except AssertionError as err:
            raise err
        except:
            raise StopIteration(
                "Warning: {}.size({},{},{}) failed to converge".format(
                    self.__class__.__name__, attr, bounds, unitsBounds))
