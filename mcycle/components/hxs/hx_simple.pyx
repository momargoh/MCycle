from ...bases.component cimport Component22
from ...bases.config cimport Config
from ... import defaults
from ...logger import log
from ..._constants cimport *
from ...methods.heat_transfer cimport lmtd
from warnings import warn
from math import nan
import numpy as np
cimport numpy as np
import scipy.optimize as opt

cdef tuple _inputs = ('sense', 'U', 'A', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'sizeAttr', 'runBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'dpWf()', 'dpSf()', 'isEvap()')
        
cdef class HxSimple(Component22):
    r"""Characterises a simple heat exchanger with defined overall heat transfer coefficient.

Parameters
----------
sense : unsigned char
    General sense of the flows: COUNTERFLOW, PARALLELFLOW or CROSSFLOW. Defaults to COUNTERFLOW.
U : float, optional
    Overall heat transfer coefficient [W/m^2.K]. Defaults to nan.
A : float, optional
    Heat transfer surface area [m^2]. Defaults to nan.
efficiencyThermal : float, optional
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
    Default attribute used by size(). Must be 'A', 'U' or 'flowOutSf'. Defaults to 'A'.
runBounds : list len=2, optional
    Bracket containing value of :meth:`TOLATTR <mcycle.defaults.TOLATTR>` for the outgoing working fluid FlowState. Defaults to [nan, nan]. 
name : string, optional
    Description of object. Defaults to "HxBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
    """

    def __init__(self,
                 unsigned char sense=COUNTERFLOW,
                 double U=nan,
                 double A=nan,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="A",
                 list runBounds=[nan, nan],
                 str name="HxSimple instance",
                 str notes="No notes/model info.",
                 Config config=None):
        self.sense = sense
        self.U = U
        self.A = A
        self.efficiencyThermal = efficiencyThermal
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, None, sizeAttr,
                          [nan, nan], [nan, nan], runBounds, [nan, nan], name, notes, config)
        self._inputs = _inputs
        self._properties = _properties
                        

    cpdef public bint isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowsIn[1].T() > self.flowsIn[0].T():
            return True
        else:
            return False
    
    cpdef public double _efficiencyFactorWf(self):
        if self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double _efficiencyFactorSf(self):
        if not self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double dpWf(self):
        return 0
    
    cpdef public double dpSf(self):
        return 0

    cdef public double _QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowsOut[0].h() - self.flowsIn[0].h()) > self.config.tolAbs:
            return (self.flowsOut[0].h() - self.flowsIn[0].h()
                    ) * self._mWf() * self._efficiencyFactorWf()
        else:
            return 0

    cdef public double _QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowsOut[1].h() - self.flowsIn[1].h()) > self.config.tolAbs:
            return (self.flowsOut[1].h() - self.flowsIn[1].h()
                    ) * self._mSf() * self._efficiencyFactorSf()
        else:
            return 0

    cpdef public double Q(self):
        """float: Heat transfer to the working fluid from the secondary fluid [W]."""
        cdef str err_msg
        cdef double qWf = self._QWf()
        cdef double qSf = self._QSf()
        cdef double tolAbs = self.config.tolAbs
        if abs(qWf) < tolAbs and abs(qSf) < tolAbs:
            return 0
        elif abs((qWf + qSf) / (qWf)) < self.config.tolRel:
            return qWf
        else:
            msg = """{}.Q(), QWf*{}={},QSf*{}={}. Check efficiencyThermal={} is correct.""".format(self.__class__.__name__,
            self._efficiencyFactorWf(), qWf, self._efficiencyFactorSf(), qSf,
            self.efficiencyThermal)
            log("error", msg)
            warn(msg)
            return qWf

    cpdef public double lmtd(self):
        """float: Log-mean temperature difference [K]."""
        return lmtd(self.flowsIn[0].T(), self.flowsOut[0].T(), self.flowsIn[1].T(), self.flowsOut[1].T(), self.flowConfig.sense)
    
    cpdef public double Q_lmtd(self):
        """float: Absolute value of heat transfer rate to the working fluid [W] as calculated using the log-mean temperature difference method."""
        return self.U * self.A * self.lmtd()

    cdef double _f_runHxSimple(self, double value):
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(HmassP_INPUTS, value, self.flowsIn[0].p())
        self.flowsOut[1] = self.flowsIn[1].copyUpdateState(
                HmassP_INPUTS,
                self.flowsIn[1].h() - self._QWf() / self._efficiencyFactorSf() / self._mSf(),
                self.flowsIn[1].p())
        return abs(self.Q()) - self.Q_lmtd()
    
    cpdef public void run(self) except *:
        cdef double tol, sol
        try:
            tol = self.config.tolAbs + self.config.tolRel * self.flowsIn[0].h()
            sol = opt.brentq(
                        self._f_runHxSimple,
                        *self.runBounds,
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
        except Exception as exc:
            msg = "HxSimple.run(): error raised"
            log('error', msg, exc)
            raise exc
                           
    cpdef public void size(self) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.
        """
        cdef str attr = self.sizeAttr
        try:
            if attr == "A":
                self.A = 1.
                self.A = abs(self.Q() / self.Q_lmtd())
            elif attr == "U":
                self.U = 1.
                self.U = abs(self.Q() / self.Q_lmtd())
            elif attr == "flowOutSf":
                hOutSf = self.flowsIn[1].h() + (
                    self.flowsIn[0].h() - self.flowsOut[0].h()
                ) * self._mWf() * self._efficiencyFactorWf() / self._mSf() / self._efficiencyFactorSf()
                self.flowsOut[1] = self.flowsIn[1].copyUpdateState(HmassP_INPUTS, hOutSf,
                                                    self.flowsIn[1].p())
            else:
                raise ValueError('HxSimple.sizeAttr is not valid (given: {})'.format(attr))
        except Exception as exc:
            msg = 'HxSimple.size(): sizing failed'
            log('error', msg, exc)
            raise exc
