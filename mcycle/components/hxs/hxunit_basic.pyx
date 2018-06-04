from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from warnings import warn
from ...DEFAULTS cimport TOLABS_X, TOLREL, TOLABS, MAXITER_COMPONENT
import CoolProp as CP
import numpy as np
import scipy.optimize as opt


cdef class HxUnitBasic(Component22):
    r"""Characterises a basic heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

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
    Heat transfer coefficient of the working fluid.. Defaults to nan.
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
A : float, optional
    Heat transfer surface area [m^2]. Defaults to nan.
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
                 str flowSense="counterflow",
                 int NWf=1,
                 int NSf=1,
                 int NWall=1,
                 double hWf=float("nan"),
                 double hSf=float("nan"),
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=float("nan"),
                 double A=float("nan"),
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="A",
                 list sizeBracket=[0.01, 10.0],
                 str name="HxUnitBasic instance",
                 str  notes="No notes/model info.",
                 Config config=Config()):
        assert "counter" in flowSense.lower() or "parallel" in flowSense.lower(
        ), "{} is not a valid value for flowSense; must be 'counterflow' or 'parallel'.".format(
            flowSense)
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, None, sizeAttr,
                         sizeBracket, [], [0, 0], name, notes, config)
        self.flowSense = flowSense
        self.NWf = NWf
        self.NSf = NSf
        self.NWall = NWall
        self.hWf = hWf
        self.hSf = hSf
        self.RfWf = RfWf
        self.RfSf = RfSf
        self.wall = wall
        self.tWall = tWall
        self.A = A
        self.ARatioWf = ARatioWf
        self.ARatioSf = ARatioSf
        self.ARatioWall = ARatioWall
        self.effThermal = effThermal
        self._inputs = {"flowSense": MCAttr(str, "none"), "NWf": MCAttr(int, "none"), "NSf": MCAttr(int, "none"),
                        "NWall": MCAttr(int, "none"), "hWf": MCAttr(float, "htc"), "hSf": MCAttr(float, "htc"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "wall": MCAttr(SolidMaterial, "none"), "tWall": MCAttr(float, "length"),
                        "RfWf": MCAttr(float, "fouling"), "RfSf": MCAttr(float, "fouling"), "A": MCAttr(float, "area"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioWall": MCAttr(float, "none"),
                        "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  
                        "sizeAttr": MCAttr(str, "none"), "sizeBracket": MCAttr(list, "none"),
                        "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}

    
    cpdef public double _A(self):
        return self.A
    cpdef public double _hWf(self):
        return self.hWf
    cpdef public double _hSf(self):
        return self.hSf
    
    cpdef public bint isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowsIn[1].T() > self.flowsIn[0].T():
            return True
        else:
            return False

    cpdef public double _effFactorWf(self):
        if self.isEvap():
            return 1
        else:
            return self.effThermal

    cpdef public double _effFactorSf(self):
        if not self.isEvap():
            return 1
        else:
            return self.effThermal

    cpdef public double dpWf(self):
        return 0
    
    cpdef public double dpSf(self):
        return 0

    @property
    def twoPhaseWf(self):
        """bool: Return True if working fluid is in 2-phase region."""
        if self.hasInAndOut(0):
            if self.flowsIn[0].x() >= -self.config._tolAbs_x and self.flowsIn[0].x() <= 1 + self.config._tolAbs_x and self.flowsOut[0].x() >= -self.config._tolAbs_x and self.flowsOut[0].x() <= 1 + self.config._tolAbs_x:
                return True
            else:
                return False
        elif self.isEvap():
            if self.flowsIn[0].x() >= -self.config._tolAbs_x and self.flowsIn[0].x() < 1:
                return True
            else:
                return False
        elif not self.isEvap():
            if self.flowsIn[0].x() > 0 and self.flowsIn[0].x() <= 1 + self.config._tolAbs_x:
                return True
            else:
                return False
    
    cpdef public str phaseWf(self):
        """str: Identifier of working fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'tpEvap' or 'tpCond': evaporating or condensing in two-phase liq/vapour region."""
        if self.hasInAndOut(0):
            if self.flowsIn[0].phase() == "satLiq":
                if self.flowsOut[0].phase() == "tp":
                    return "tpEvap"
                elif self.flowsOut[0].phase() == "liq":
                    return "liq"
                else:
                    raise ValueError(
                        "Could not determine phase of WF flow. flowIn={}, flowOut={}".
                        format(self.flowsIn[0].phase(), self.flowsOut[0].phase()))
            elif self.flowsIn[0].phase() == "satVap":
                if self.flowsOut[0].phase() == "tp":
                    return "tpCond"
                elif self.flowsOut[0].phase() == "vap":
                    return "vap"
                else:
                    raise ValueError(
                        "could not determine phase of WF flow. flowIn={}, flowOut={}".
                        format(self.flowsIn[0].phase(), self.flowsOut[0].phase()))
            elif self.flowsIn[0].phase() == "tp" and self.flowsOut[0].phase() == "satLiq":
                return "tpCond"
            elif self.flowsIn[0].phase() == "tp" and self.flowsOut[0].phase() == "satVap":
                return "tpEvap"
            elif self.flowsIn[0].phase() == "tp" and self.flowsOut[0].phase() == "tp":
                if self.flowsIn[0].h() < self.flowsOut[0].h():
                    return "tpEvap"
                else:
                    return "tpCond"
            elif self.flowsIn[0].phase() == "liq" or self.flowsOut[0].phase() == "liq":
                return "liq"
            elif self.flowsIn[0].phase() == "vap" or self.flowsOut[0].phase() == "vap":
                return "vap"
            else:
                raise ValueError(
                    "could not determine phase of WF flow. flowIn={}, flowOut={}".
                    format(self.flowsIn[0].phase(), self.flowsOut[0].phase()))
        else:
            if self.flowsIn[0].phase() == "tp":
                if self.flowsIn[0].T() < self.flowsIn[1].T():
                    return "tpEvap"
                else:
                    return "tpCond"

            elif self.flowsIn[0].phase() == "satLiq":
                if self.flowsIn[0].T() < self.flowsIn[1].T():
                    return "tpEvap"
                else:
                    return "liq"
            elif self.flowsIn[0].phase() == "satVap":
                if self.flowsIn[0].T() < self.flowsIn[1].T():
                    return "vap"
                else:
                    return "tpCond"

            elif self.flowsIn[0].phase() == "liq":

                return "liq"
            elif self.flowsIn[0].phase() == "vap":
                return "vap"
            else:
                raise ValueError(
                    "Could not determine phase of WF flow. flowIn={}, flowOut={}".
                    format(self.flowsIn[0].phase(), self.flowsOut[0].phase()))

    cpdef public str phaseSf(self):
        """str: Identifier of secondary fluid phase: 'liq': subcooled liquid, 'vap': superheated vapour, 'sp': unknown single-phase."""
        if self.hasInAndOut(1):
            if self.flowsIn[1].phase() == "liq" or self.flowsOut[1].phase() == "liq":
                return "liq"
            elif self.flowsIn[1].phase() == "vap" or self.flowsOut[1].phase() == "vap":
                return "vap"
            elif self.flowsIn[1].phase() == "sp" or self.flowsOut[1].phase() == "sp":
                return "sp"
        else:
            if self.flowsIn[1].phase() == "liq":
                return "liq"
            elif self.flowsIn[1].phase() == "vap":
                return "vap"
            elif self.flowsIn[1].phase() == "sp":
                return "sp"

    cdef public double QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowsOut[0].h() - self.flowsIn[0].h()) > TOLABS:
            return (self.flowsOut[0].h() - self.flowsIn[0].h()
                    ) * self._mWf() * self._effFactorWf()
        else:
            return 0

    cdef public double QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowsOut[1].h() - self.flowsIn[1].h()) > TOLABS:
            return (self.flowsOut[1].h() - self.flowsIn[1].h()
                    ) * self._mSf() * self._effFactorSf()
        else:
            return 0

    cpdef public double Q(self):
        """float: Heat transfer from the secondary fluid to the working fluid [W]."""
        err_msg = """QWf*{}={},QSf*{}={}. Check effThermal={} is correct.""".format(
            self._effFactorWf(), self.QWf(), self._effFactorSf(), self.QSf(),
            self.effThermal)
        if abs(self.QWf()) < TOLABS and abs(self.QSf()) < TOLABS:
            return 0
        elif abs((self.QWf() + self.QSf()) / (self.QWf())) < TOLREL:
            return self.QWf()
        else:
            warn(err_msg)
            return self.QWf()

    cpdef public int _NWf(self):
        return self.NWf

    cpdef public int _NSf(self):
        return self.NSf

    cpdef public double U(self):
        """float: Overall heat transfer coefficient [W/m^2.K]; heat transfer coefficients of each flow channel and wall, summed in series."""
        cdef double RWf = 1 / self._hWf() / self.ARatioWf / self._NWf() + self.RfWf / self.ARatioWf / self._NWf()
        cdef double RSf = 1 / self._hSf() / self.ARatioSf / self._NSf() + self.RfSf / self.ARatioSf / self._NSf()
        cdef double RWall = self.tWall / self.wall.k() / self.ARatioWall / self.NWall
        return (RWf + RSf + RWall)**-1

    cpdef public double LMTD(self):
        """float: Log-mean temperature difference [K]"""
        cdef double dT1 = 0
        cdef double dT2 = 0
        if "counter" in self.flowSense.lower():
            dT1 = self.flowsIn[1].T() - self.flowsOut[0].T()
            dT2 = self.flowsOut[1].T() - self.flowsIn[0].T()
        elif "parallel" in self.flowSense.lower():
            dT1 = self.flowsOut[1].T() - self.flowsOut[0].T()
            dT2 = self.flowsIn[1].T() - self.flowsIn[0].T()
        ans = (dT1 - dT2) / np.log(dT1 / dT2)
        if np.isnan(ans):
            warn(
                "LMTD found non valid flow temperatures: flowInWf={}, flowOutWf={}, flowInSf={}, flowOutSf={}".
                format(self.flowsIn[0].T(), self.flowsOut[0].T(), self.flowsIn[1].T(),
                       self.flowsOut[1].T()))
        return ans

    cdef public double Q_LMTD(self):
        """float: Heat transfer rate to the working fluid [W] as calculated using the log-mean temperature difference method."""
        return self.U() * self._A() * self.LMTD()

    cpdef public double weight(self):
        """float: Estimate of weight [Kg], based purely on wall properties."""
        return self._A() * self.ARatioWall * self.tWall * self.wall.rho * self.NWall

    cpdef public void run(self):
        """Run the HX from the incoming FlowState, using the epsilon-NTU method to produce an initial solution estimate."""
        # initial guess from e-NTU method
        cdef double eps = 0.8
        cdef double Cmin = min(self.flowsIn[0].cp() * self._mWf(), self.flowsIn[1].cp() * self._mSf())
        cdef double q = eps * Cmin * (self.flowsIn[1].T() - self.flowsIn[0].T()) * self.effThermal
        self.flowsOut[0] = self.flowsIn[0].copyState(
            CP.HmassP_INPUTS, self.flowsIn[0].h() + q / self._mWf(), self.flowsIn[0].p())
        self.flowsOut[1] = self.flowsIn[1].copyState(
            CP.HmassP_INPUTS, self.flowsIn[1].h() - self._mWf() * self._effFactorWf() *
            (self.flowsOut[0].h() - self.flowsIn[0].h()
             ) / self._mSf() / self._effFactorSf(), self.flowsIn[1].p())
        cdef double diff = abs(self.Q() - self.Q_LMTD()) / self.Q()
        cdef int count = 0
        while diff > self.config._tolRel_h:
            q = self.Q_LMTD()
            self.flowsOut[0] = self.flowsIn[0].copyState(
                CP.HmassP_INPUTS,
                self.flowsIn[0].h() + q / self._effFactorWf() / self._mWf(),
                self.flowsIn[0].p())
            self.flowsOut[1] = self.flowsIn[1].copyState(
                CP.HmassP_INPUTS,
                self.flowsIn[1].h() - q / self._effFactorSf() / self._mSf(),
                self.flowsIn[1].p())
            diff = abs(self.Q() - q) / self.Q()

            count += 1
            if count > MAXITER_COMPONENT:
                raise StopIteration(
                    """{} iterations without {} converging: diff={}>tol={}""".
                    format(MAXITER_COMPONENT, "h", diff,
                           self.config._tolRel_h))
        #return self.flowsOut[0]

    cdef double _f_sizeHxUnitBasic(self, double value, str attr):
        self.update({attr: value})
        return self.Q() - self.Q_LMTD()
                
    cpdef public void sizeUnits(self, str attr, list bracket) except *:
        """Size for the value of the nominated attribute required to achieve the defined outgoing FlowState.

Parameters
------------
attr : string, optional
    Component attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bracket : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBracket is used. Defaults to None.

    - if bracket=[a,b]: scipy.optimize.brentq is used.

    - if bracket=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol, sizedValue
        if attr == '':
            attr = self.sizeAttr
        if bracket == []:
            bracket = self.sizeBracket
        try:
            if attr == "A":
                self.A = 1.
                self.A = self.Q() / self.Q_LMTD()
                #return self.A
            else:
                tol = self.config.tolAbs + self.config.tolRel * self.Q()
                if len(bracket) == 2:
                    sizedValue = opt.brentq(
                        self._f_sizeHxUnitBasic,
                        bracket[0],
                        bracket[1],
                        args=(attr),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(bracket) == 1:
                    sizedValue = opt.newton(self._f_sizeHxUnitBasic, bracket[0], args=(attr), tol=tol)
                else:
                    raise ValueError("bracket is not valid (given: {})".format(bracket))
                self.update({attr:sizedValue})
                #return sizedValue
        except AssertionError as err:
            raise (err)
        except:
            raise Exception(
                "Warning: {}.size({},{}) failed to converge".format(
                    self.__class__.__name__, attr, bracket))
        
    @property
    def N(self):
        """int: Number of flow channels, returns average of NWf & NSf.
        Setter makes both equal to desired value."""
        return (self._NWf() + self._NSf()) / 2.

    @N.setter
    def N(self, value):
        self.NWf = value
        self.NSf = value

