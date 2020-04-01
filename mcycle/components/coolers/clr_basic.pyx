from ...bases.component cimport Component11
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.abc cimport MCAttr
from ..._constants cimport *
from ...logger import log

cdef dict _inputs = {"QCool": MCAttr(float, "power"), "efficiencyThermal": MCAttr(float, "none"),
                "flowIn": MCAttr(FlowState, "none"), "flowOut": MCAttr(FlowState, "none"), 'ambient': MCAttr(FlowState, 'none'), "sizeAttr": MCAttr(str, "none"),
                "sizeBounds": MCAttr(list, "none"),"sizeUnitsBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "dpWf()": MCAttr(float, "pressure"),
                "dpSf()": MCAttr(float, "pressure")}
        
cdef class ClrBasic(Component11):
    r"""Basic heat removal defined by the cooling power and its thermal efficiency.

Parameters
----------
QCool : double
    Cooling power: heat removed from the working fluid [W].
efficiencyIsentropic : float, optional
    Isentropic efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "QCool".
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
                 double QCool,
                 double efficiencyThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="QCool",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="ClrBasic instance",
                 str notes="No notes/model info.",
                 Config config=None):
        super().__init__(flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, [0, 0], [0, 0], name, notes,
                         config)
        if efficiencyThermal <= 0 or efficiencyThermal > 1:
            msg = "ClrBasic(): efficiencyThermal={} is not in range (0, 1]".format(efficiencyThermal)
            log('error', msg)
            raise ValueError(msg)
        self.QCool = QCool
        self.efficiencyThermal = efficiencyThermal
        self._inputs = _inputs
        self._properties = _properties

    cpdef public double _efficiencyFactorWf(self):
        return self.efficiencyThermal
    
    cpdef public double _efficiencyFactorSf(self):
        return 1

    cpdef public double dpWf(self):
        """float: Pressure drop of the working fluid [Pa]. Defaults to 0."""
        return 0

    cpdef public double dpSf(self):
        """float: Pressure drop of the secondary fluid [Pa]. Defaults to 0."""
        return 0

    cpdef public void run(self) except *:
        pass
    
    cpdef public double Q(self):
        """double: Heat [W] transferred to the working fluid."""
        return -self.QCool
    

cdef class ClrBasicConstP(ClrBasic):
    r"""Basic constant pressure heat addition.

Parameters
----------
QCool : float
    Cooling power: heat removed from the working fluid [W].
efficiencyThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "efficiencyThermal".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 double QCool,
                 double efficiencyThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="QCool",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="ClrBasic instance",
                 str notes="No notes/model info.",
                 Config config=None):
        super().__init__(QCool, efficiencyThermal, flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, name, notes,
                         config)

    cpdef public void run(self) except *:
        """Compute outgoing FlowState from component attributes."""
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
            HmassP_INPUTS,
            self.flowsIn[0].h() - self.QCool * self.efficiencyThermal / self._m(), self.flowsIn[0].p())

    cpdef public void size(self) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.
        """
        cdef FlowState flowOut_s
        cdef str attr = self.sizeAttr
        try:
            assert abs(1 - self.flowsOut[0].p() / self.flowsIn[0].
                       p()) < self.config._tolRel_p, "flowOut.p != flowIn.p"
            if attr == "QCool" or attr == "Q":
                self.QCool = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) * self._m() / self.efficiencyThermal
            elif attr == "efficiencyThermal":
                self.efficiencyThermal = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) * self._m() / self.QCool
            elif attr == "m":
                self.m = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) / self.efficiencyThermal / self.QCool
            else:
                super(ClrBasic, self).size()
        except AssertionError as err:
            log('error', 'ClrBasicConstP.size(): flowOut.p != flowIn.p', err)
            raise err
        except Exception as exc:
            msg = 'ClrBasicConstP.size(): failed to converge.'.format(self.__class__.__name__)
            log('error', msg, exc)
            raise exc


cdef class ClrBasicConstV(ClrBasic):
    r"""Basic constant volume heat addition.

Parameters
----------
QCool : float
    Cooling power: heat removed from the working fluid [W].
efficiencyThermal : float, optional
    Thermal efficiencyiciency [-]. Defaults to 1.
flowIn : FlowState, optional
    Incoming FlowState. Defaults to None.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "QCool".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [0.1, 1.0].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 double QCool,
                 double efficiencyThermal=1.0,
                 FlowState flowIn=None,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="QCool",
                 list sizeBounds=[1, 50],
                 list sizeUnitsBounds=[],
                 str name="ClrBasic instance",
                 str notes="No notes/model info.",
                 Config config=None):
        super().__init__(QCool, efficiencyThermal, flowIn, flowOut, ambient, sizeAttr, sizeBounds, sizeUnitsBounds, name, notes,
                         config)
        
    cpdef public void run(self) except *:
        """Compute outgoing FlowState from component attributes."""
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
            DmassHmass_INPUTS, self.flowsIn[0].rho(),
            self.flowsIn[0].h() - self.QCool * self.efficiencyThermal / self._m())

    cpdef public void size(self) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
attr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - ifbounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        cdef FlowState flowOut_s
        cdef str attr = self.sizeAttr
        try:
            assert abs(1 - self.flowsOut[0].rho() / self.flowsIn[0].rho()
                       ) < self.config._tolRel_rho, "flowOut.rho != flowIn.rho"
            if attr == "QCool" or attr == "Q":
                self.QCool = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) * self._m() / self.efficiencyThermal
            elif attr == "efficiencyThermal":
                self.efficiencyThermal = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) * self._m() / self.QCool
            elif attr == "m":
                self.m = (
                    self.flowsIn[0].h() - self.flowsOut[0].h()) / self.efficiencyThermal / self.QCool
            else:
                super(ClrBasic, self).size()
        except AssertionError as err:
            log('error', 'ClrBasicConstV.size(): flowOut.rho != flowIn.rho', err)
            raise err
        except Exception as exc:
            msg = 'ClrBasicConstV.size(): failed to converge.'.format(self.__class__.__name__)
            log('error', msg, exc)
            raise exc
