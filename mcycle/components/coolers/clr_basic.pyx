from ...bases.component cimport Component11
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ..._constants cimport *
from ...logger import log

cdef tuple _inputs = ('constraint', 'QCool', 'efficiencyThermal', 'flowIn', 'flowOut', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'dpWf()', 'dpSf()')
        
cdef class ClrBasic(Component11):
    r"""Basic heat removal defined by the cooling power and its thermal efficiency. May be either constant pressure or volume.

Parameters
----------
constraint : unsigned char
    Operational constraint: CONSTANT_P or CONSTANT_V (see :meth:`constants <mcycle.constants>`)
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
    Default attribute used by size(). Defaults to ''.
sizeBounds : list len=2, optional
    Bracket containing solution of size(). Defaults to []. (Passed to scipy.optimize.brentq as ``bounds`` argument)
sizeUnitsBounds : list len=2, optional
    Bracket containing solution of sizeUnits(). Defaults to []. (Passed to scipy.optimize.brentq as ``bounds`` argument)
runBounds : list len=2, optional
    Not required for all components. Bracket containing value of :meth:`TOLATTR <mcycle.defaults.TOLATTR>` for the outgoing working fluid FlowState. Defaults to [nan, nan]. 
name : string, optional
    Description of Component object. Defaults to "ExpBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
    """

    def __init__(self,
                 unsigned char constraint,
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
        self.constraint = constraint
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
            
    cpdef public double Q(self):
        """double: Heat [W] transferred to the working fluid."""
        return -self.QCool

    cpdef public void _run_constantP(self) except *:
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
            HmassP_INPUTS,
            self.flowsIn[0].h() - self.QCool * self.efficiencyThermal / self._m(), self.flowsIn[0].p())

    cpdef public void _size_constantP(self) except *:
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
                raise ValueError('sizeAttr not valid, given: {}'.format(attr))
        except AssertionError as err:
            log('error', 'ClrBasic.size(): flowOut.p != flowIn.p', err)
            raise err
        except Exception as exc:
            msg = 'ClrBasic.size(): failed to converge.'.format(self.__class__.__name__)
            log('error', msg, exc)
            raise exc

        
    cpdef public void _run_constantV(self) except *:
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(
            DmassHmass_INPUTS, self.flowsIn[0].rho(),
            self.flowsIn[0].h() - self.QCool * self.efficiencyThermal / self._m())

    cpdef public void _size_constantV(self) except *:
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
                raise ValueError('sizeAttr not valid, given: {}'.format(attr))
        except AssertionError as err:
            log('error', 'ClrBasic.size(): flowOut.rho != flowIn.rho', err)
            raise err
        except Exception as exc:
            msg = 'ClrBasic.size(): failed to converge.'.format(self.__class__.__name__)
            log('error', msg, exc)
            raise exc

    cpdef public void run(self) except *:
        """Compute outgoing FlowState from component attributes."""
        if self.constraint == CONSTANT_P:
            self._run_constantP()
        elif self.constraint == CONSTANT_V:
            self._run_constantV()
        else:
            msg = "ClrBasic.run(): Invalid value for self.constraint, given: {}".format(self.constraint)
            log('error', msg)
            raise ValueError(msg)

    cpdef public void size(self) except *:
        """Solve for the value of the nominated attribute required to achieve the defined outgoing FlowState.
        """
        if self.constraint == CONSTANT_P:
            self._size_constantP()
        elif self.constraint == CONSTANT_V:
            self._size_constantV()
        else:
            msg = "ClrBasic.size(): Invalid value for self.constraint, given: {}".format(self.constraint)
            log('error', msg)
            raise ValueError(msg)
